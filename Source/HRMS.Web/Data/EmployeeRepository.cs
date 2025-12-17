using Microsoft.Data.SqlClient;
using System.Data;
using System.IO;
using HRMS.Web.Models;

public class EmployeeRepository
{
    private readonly SqlConnection _conn;

    public EmployeeRepository(SqlConnection conn)
    {
        _conn = conn;
    }

    // LOGIN (General Component)
    public async Task<Employee?> LoginAsync(string email, string nationalId)
    {
        const string sql = """
            SELECT 
                e.employee_id,
                e.full_name,
                e.email,
                r.role_name
            FROM Employee e
            LEFT JOIN Employee_Role er ON e.employee_id = er.employee_id
            LEFT JOIN Role r ON er.role_id = r.role_id
            WHERE e.email = @Email
              AND e.national_id = @NationalID;
        """;

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@Email", email);
        cmd.Parameters.AddWithValue("@NationalID", nationalId);

        using var r = await cmd.ExecuteReaderAsync();
        if (!await r.ReadAsync())
        {
            await _conn.CloseAsync();
            return null;
        }

        var emp = new Employee
        {
            EmployeeId = (int)r["employee_id"],
            FullName = r["full_name"].ToString(),
            Email = r["email"].ToString(),
            RoleName = r["role_name"]?.ToString()
        };

        await _conn.CloseAsync();
        return emp;
    }

    public async Task<Employee?> GetEmployeeByEmailAsync(string email)
    {
        const string sql = """
            SELECT 
                e.employee_id,
                e.full_name,
                e.email,
                e.national_id,
                r.role_name
            FROM Employee e
            LEFT JOIN Employee_Role er ON e.employee_id = er.employee_id
            LEFT JOIN Role r ON er.role_id = r.role_id
            WHERE e.email = @Email;
        """;

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@Email", email);

        using var r = await cmd.ExecuteReaderAsync();
        if (!await r.ReadAsync())
        {
            await _conn.CloseAsync();
            return null;
        }

        var emp = new Employee
        {
            EmployeeId = (int)r["employee_id"],
            FullName = r["full_name"].ToString(),
            Email = r["email"].ToString(),
            RoleName = r["role_name"]?.ToString()
        };

        // Check if national_id is NULL (first-time login)
        if (r["national_id"] == DBNull.Value || string.IsNullOrEmpty(r["national_id"]?.ToString()))
        {
            emp.AccountStatus = "FirstTimeLogin";
        }

        await _conn.CloseAsync();
        return emp;
    }

    public async Task SetNationalIdAsync(int employeeId, string nationalId)
    {
        const string sql = """
            UPDATE Employee
            SET national_id = @NationalId
            WHERE employee_id = @EmployeeId
        """;

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@NationalId", nationalId);
        cmd.Parameters.AddWithValue("@EmployeeId", employeeId);
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<int> CreateEmployeeAsync(
        string firstName,
        string lastName,
        string email,
        string phone,
        int departmentId,
        int roleId)
    {
        await _conn.OpenAsync();

        using var cmd = new SqlCommand("CreateEmployeeProfile", _conn);
        cmd.CommandType = CommandType.StoredProcedure;

        cmd.Parameters.AddWithValue("@FirstName", firstName);
        cmd.Parameters.AddWithValue("@LastName", lastName);
        cmd.Parameters.AddWithValue("@Email", email);
        cmd.Parameters.AddWithValue("@Phone", phone);
        cmd.Parameters.AddWithValue("@DepartmentID", departmentId);
        cmd.Parameters.AddWithValue("@RoleID", roleId);

        return Convert.ToInt32(await cmd.ExecuteScalarAsync());
    }

    // Self-registration for System Admins, HR Admins, and Line Managers
    public async Task<int> SelfRegisterAsync(
        string firstName,
        string lastName,
        string email,
        string phone,
        string nationalId,
        int departmentId,
        int roleId)
    {
        try
        {
            await _conn.OpenAsync();

            // Check if email already exists
            var checkEmailCmd = new SqlCommand(
                "SELECT COUNT(*) FROM Employee WHERE email = @Email",
                _conn
            );
            checkEmailCmd.Parameters.AddWithValue("@Email", email);
            int emailCount = Convert.ToInt32(await checkEmailCmd.ExecuteScalarAsync());

            if (emailCount > 0)
            {
                throw new Exception("Email already exists. Please use a different email address.");
            }

            // Get next employee ID
            var idCmd = new SqlCommand(
                "SELECT ISNULL(MAX(employee_id), 0) + 1 FROM Employee",
                _conn
            );
            int employeeId = Convert.ToInt32(await idCmd.ExecuteScalarAsync());

            // Create employee with national_id set (unlike CreateEmployeeAsync)
            var createCmd = new SqlCommand(@"
                INSERT INTO Employee (employee_id, first_name, last_name, full_name, email, phone, department_id, national_id)
                VALUES (@EmployeeId, @FirstName, @LastName, @FullName, @Email, @Phone, @DepartmentId, @NationalId)",
                _conn
            );

            string fullName = $"{firstName} {lastName}";
            createCmd.Parameters.AddWithValue("@EmployeeId", employeeId);
            createCmd.Parameters.AddWithValue("@FirstName", firstName);
            createCmd.Parameters.AddWithValue("@LastName", lastName);
            createCmd.Parameters.AddWithValue("@FullName", fullName);
            createCmd.Parameters.AddWithValue("@Email", email);
            createCmd.Parameters.AddWithValue("@Phone", phone ?? "");
            createCmd.Parameters.AddWithValue("@DepartmentId", departmentId);
            createCmd.Parameters.AddWithValue("@NationalId", nationalId);

            await createCmd.ExecuteNonQueryAsync();

            // Assign role
            var roleCmd = new SqlCommand(@"
                INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
                VALUES (@EmployeeId, @RoleId, GETDATE())",
                _conn
            );
            roleCmd.Parameters.AddWithValue("@EmployeeId", employeeId);
            roleCmd.Parameters.AddWithValue("@RoleId", roleId);
            await roleCmd.ExecuteNonQueryAsync();

            return employeeId;
        }
        finally
        {
            if (_conn.State == System.Data.ConnectionState.Open)
            {
                await _conn.CloseAsync();
            }
        }
    }

    public async Task UpdateEmployeeAsync(
        int employeeId,
        string email,
        string phone,
        string address)
    {
        await _conn.OpenAsync();

        using var cmd = new SqlCommand("UpdateEmployeeInfo", _conn);
        cmd.CommandType = CommandType.StoredProcedure;

        cmd.Parameters.AddWithValue("@EmployeeID", employeeId);
        cmd.Parameters.AddWithValue("@Email", email);
        cmd.Parameters.AddWithValue("@Phone", phone);
        cmd.Parameters.AddWithValue("@Address", address);

        await cmd.ExecuteNonQueryAsync();
    }

    public async Task UpdateProfileImage(int employeeId, string fileName)
    {
        using var cmd = new SqlCommand(
            "UPDATE Employee SET profile_image = @img WHERE employee_id = @id",
            _conn
        );

        cmd.Parameters.AddWithValue("@img", fileName);
        cmd.Parameters.AddWithValue("@id", employeeId);

        await _conn.OpenAsync();
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<Employee?> GetEmployeeById(int employeeId)
    {
        const string sql = """
            SELECT
                employee_id,
                full_name,
                email,
                profile_image
            FROM Employee
            WHERE employee_id = @id
        """;

        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@id", employeeId);

        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        if (!await r.ReadAsync())
        {
            await _conn.CloseAsync();
            return null;
        }

        var emp = new Employee
        {
            EmployeeId = (int)r["employee_id"],
            FullName = r["full_name"]?.ToString(),
            Email = r["email"]?.ToString(),
            ProfileImage = r["profile_image"]?.ToString()
        };

        await _conn.CloseAsync();
        return emp;
    }

    public async Task<Employee?> GetEmployeeByIdAsync(int id)
    {
        const string sql = """
            SELECT *
            FROM Employee
            WHERE employee_id = @id
        """;

        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@id", id);

        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        if (!await r.ReadAsync())
        {
            await _conn.CloseAsync();
            return null;
        }

        var emp = new Employee
        {
            EmployeeId = (int)r["employee_id"],
            FullName = r["full_name"]?.ToString(),
            Email = r["email"]?.ToString(),
            Phone = r["phone"]?.ToString(),
            Address = r["address"]?.ToString(),
            Biography = r["biography"]?.ToString(),
            ProfileImage = r["profile_image"]?.ToString(),
            DepartmentId = r["department_id"] != DBNull.Value ? (int?)r["department_id"] : null,
            ManagerId = r["manager_id"] != DBNull.Value ? (int?)r["manager_id"] : null
        };

        await _conn.CloseAsync();
        return emp;
    }

    public async Task<List<Employee>> GetAllEmployeesAsync()
    {
        const string sql = """
            SELECT employee_id, full_name, email
            FROM Employee
            WHERE is_active = 1
        """;

        var list = new List<Employee>();

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new Employee
            {
                EmployeeId = (int)r["employee_id"],
                FullName = r["full_name"].ToString(),
                Email = r["email"].ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<List<Employee>> SearchEmployeesAsync(string searchTerm)
    {
        const string sql = """
            SELECT employee_id, full_name, email
            FROM Employee
            WHERE is_active = 1
              AND (
                  CAST(employee_id AS VARCHAR) LIKE @Search
                  OR full_name LIKE @Search
                  OR email LIKE @Search
              )
            ORDER BY employee_id
        """;

        var list = new List<Employee>();

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@Search", $"%{searchTerm}%");
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new Employee
            {
                EmployeeId = (int)r["employee_id"],
                FullName = r["full_name"].ToString(),
                Email = r["email"].ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task UpdateMyProfileAsync(Employee e)
    {
        const string sql = """
            UPDATE Employee
            SET phone = @phone,
                address = @address,
                emergency_contact_name = @ecname,
                emergency_contact_phone = @ecphone,
                relationship = @rel,
                biography = @bio
            WHERE employee_id = @id
        """;

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);

        cmd.Parameters.AddWithValue("@phone", e.Phone ?? "");
        cmd.Parameters.AddWithValue("@address", e.Address ?? "");
        cmd.Parameters.AddWithValue("@ecname", e.EmergencyContactName ?? "");
        cmd.Parameters.AddWithValue("@ecphone", e.EmergencyContactPhone ?? "");
        cmd.Parameters.AddWithValue("@rel", e.Relationship ?? "");
        cmd.Parameters.AddWithValue("@bio", e.Biography ?? "");
        cmd.Parameters.AddWithValue("@id", e.EmployeeId);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task HRUpdateEmployeeAsync(Employee e)
    {
        const string sql = """
            UPDATE Employee
            SET phone = @phone,
                address = @address,
                emergency_contact_name = @ecname,
                emergency_contact_phone = @ecphone,
                relationship = @rel,
                biography = @bio,
                account_status = @status
            WHERE employee_id = @id
        """;

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);

        cmd.Parameters.AddWithValue("@phone", e.Phone ?? "");
        cmd.Parameters.AddWithValue("@address", e.Address ?? "");
        cmd.Parameters.AddWithValue("@ecname", e.EmergencyContactName ?? "");
        cmd.Parameters.AddWithValue("@ecphone", e.EmergencyContactPhone ?? "");
        cmd.Parameters.AddWithValue("@rel", e.Relationship ?? "");
        cmd.Parameters.AddWithValue("@bio", e.Biography ?? "");
        cmd.Parameters.AddWithValue("@status", e.AccountStatus ?? "Active");
        cmd.Parameters.AddWithValue("@id", e.EmployeeId);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<List<Employee>> GetTeamAsync(int managerId)
    {
        const string sql = @"
            SELECT employee_id, full_name, email, phone, address
            FROM Employee
            WHERE manager_id = @ManagerId
        ";

        var list = new List<Employee>();

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@ManagerId", managerId);

        using var r = await cmd.ExecuteReaderAsync();
        while (await r.ReadAsync())
        {
            list.Add(new Employee
            {
                EmployeeId = (int)r["employee_id"],
                FullName = r["full_name"].ToString(),
                Email = r["email"].ToString(),
                Phone = r["phone"]?.ToString(),
                Address = r["address"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<List<Employee>> GetIncompleteProfilesAsync()
    {
        const string sql = """
            SELECT employee_id, full_name, email
            FROM Employee
            WHERE profile_completion < 100 OR profile_completion IS NULL
        """;

        var list = new List<Employee>();

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new Employee
            {
                EmployeeId = (int)r["employee_id"],
                FullName = r["full_name"].ToString(),
                Email = r["email"].ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<int> CreateContractAsync(
        string type,
        DateTime startDate,
        DateTime endDate,
        string state,
        int employeeId)
    {
        const string sql = @"
            DECLARE @NewId INT;
            SELECT @NewId = ISNULL(MAX(contract_id), 0) + 1 FROM Contract;

            INSERT INTO Contract (contract_id, type, start_date, end_date, current_state)
            VALUES (@NewId, @Type, @StartDate, @EndDate, @State);

            UPDATE Employee
            SET contract_id = @NewId
            WHERE employee_id = @EmployeeId;

            SELECT @NewId;
        ";

        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@Type", type);
        cmd.Parameters.AddWithValue("@StartDate", startDate);
        cmd.Parameters.AddWithValue("@EndDate", endDate);
        cmd.Parameters.AddWithValue("@State", state);
        cmd.Parameters.AddWithValue("@EmployeeId", employeeId);

        await _conn.OpenAsync();
        var id = Convert.ToInt32(await cmd.ExecuteScalarAsync());
        await _conn.CloseAsync();

        return id;
    }

    public async Task RenewContractAsync(
        int employeeId,
        int oldContractId,
        DateTime newStart,
        DateTime newEnd,
        string type)
    {
        await _conn.OpenAsync();

        // 1. Expire old contract
        var expireCmd = new SqlCommand(
            "UPDATE Contract SET current_state = 'Expired' WHERE contract_id = @cid",
            _conn
        );
        expireCmd.Parameters.AddWithValue("@cid", oldContractId);
        await expireCmd.ExecuteNonQueryAsync();

        // 2. Create new contract with manual ID generation
        var newIdCmd = new SqlCommand(
            "SELECT ISNULL(MAX(contract_id), 0) + 1 FROM Contract",
            _conn
        );
        int newContractId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());

        var newCmd = new SqlCommand(@"
            INSERT INTO Contract (contract_id, type, start_date, end_date, current_state)
            VALUES (@newId, @type, @start, @end, 'Active')", _conn);

        newCmd.Parameters.AddWithValue("@newId", newContractId);
        newCmd.Parameters.AddWithValue("@type", type);
        newCmd.Parameters.AddWithValue("@start", newStart);
        newCmd.Parameters.AddWithValue("@end", newEnd);

        await newCmd.ExecuteNonQueryAsync();

        // 3. Assign new contract to employee
        var assignCmd = new SqlCommand(
            "UPDATE Employee SET contract_id = @newCid WHERE employee_id = @eid",
            _conn
        );
        assignCmd.Parameters.AddWithValue("@newCid", newContractId);
        assignCmd.Parameters.AddWithValue("@eid", employeeId);

        await assignCmd.ExecuteNonQueryAsync();

        await _conn.CloseAsync();
    }

    public async Task<List<ExpiringContract>> GetExpiringContractsAsync(int daysBefore = 30)
    {
        const string sql = """
            SELECT 
                e.employee_id,
                c.contract_id,
                e.full_name,
                e.email,
                c.type AS contract_type,
                c.start_date,
                c.end_date,
                c.current_state
            FROM Employee e
            INNER JOIN Contract c ON e.contract_id = c.contract_id
            WHERE (
                (c.current_state = 'Active' AND c.end_date <= DATEADD(DAY, @DaysBefore, GETDATE()) AND c.end_date >= GETDATE())
                OR
                (c.current_state = 'Expired' OR c.end_date < GETDATE())
            )
            ORDER BY c.end_date ASC
        """;

        var list = new List<ExpiringContract>();

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@DaysBefore", daysBefore);
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new ExpiringContract
            {
                EmployeeId = (int)r["employee_id"],
                ContractId = (int)r["contract_id"],
                FullName = r["full_name"]?.ToString(),
                Email = r["email"]?.ToString(),
                ContractType = r["contract_type"]?.ToString(),
                StartDate = (DateTime)r["start_date"],
                EndDate = (DateTime)r["end_date"],
                CurrentState = r["current_state"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<ExpiringContract?> GetContractByIdAsync(int contractId)
    {
        const string sql = """
            SELECT 
                e.employee_id,
                c.contract_id,
                e.full_name,
                e.email,
                c.type AS contract_type,
                c.start_date,
                c.end_date,
                c.current_state
            FROM Contract c
            INNER JOIN Employee e ON e.contract_id = c.contract_id
            WHERE c.contract_id = @ContractId
        """;

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@ContractId", contractId);
        using var r = await cmd.ExecuteReaderAsync();

        if (!await r.ReadAsync())
        {
            await _conn.CloseAsync();
            return null;
        }

        var contract = new ExpiringContract
        {
            EmployeeId = (int)r["employee_id"],
            ContractId = (int)r["contract_id"],
            FullName = r["full_name"]?.ToString(),
            Email = r["email"]?.ToString(),
            ContractType = r["contract_type"]?.ToString(),
            StartDate = (DateTime)r["start_date"],
            EndDate = (DateTime)r["end_date"],
            CurrentState = r["current_state"]?.ToString()
        };

        await _conn.CloseAsync();
        return contract;
    }

    public async Task CreateNotificationAsync(
        int employeeId,
        string message,
        string urgency = "Normal",
        string type = "Contract")
    {
        await _conn.OpenAsync();

        // 1. Create notification
        var newIdCmd = new SqlCommand(
            "SELECT ISNULL(MAX(notification_id), 0) + 1 FROM Notification",
            _conn
        );
        int notificationId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());

        var notifCmd = new SqlCommand(@"
            INSERT INTO Notification (notification_id, message_content, timestamp, urgency, read_status, notification_type)
            VALUES (@nid, @msg, GETDATE(), @urgency, 0, @type)", _conn);

        notifCmd.Parameters.AddWithValue("@nid", notificationId);
        notifCmd.Parameters.AddWithValue("@msg", message);
        notifCmd.Parameters.AddWithValue("@urgency", urgency);
        notifCmd.Parameters.AddWithValue("@type", type);

        await notifCmd.ExecuteNonQueryAsync();

        // 2. Assign to employee
        var linkCmd = new SqlCommand(@"
            INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
            VALUES (@eid, @nid, 'Delivered', GETDATE())", _conn);

        linkCmd.Parameters.AddWithValue("@eid", employeeId);
        linkCmd.Parameters.AddWithValue("@nid", notificationId);

        await linkCmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<List<Notification>> GetEmployeeNotifications(int employeeId)
    {
        var list = new List<Notification>();

        var cmd = new SqlCommand(@"
            SELECT n.notification_id, n.message_content, n.timestamp, n.read_status, n.urgency, n.notification_type
            FROM Notification n
            JOIN Employee_Notification en ON n.notification_id = en.notification_id
            WHERE en.employee_id = @id
            ORDER BY n.timestamp DESC", _conn);

        cmd.Parameters.AddWithValue("@id", employeeId);

        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new Notification
            {
                NotificationId = (int)r["notification_id"],
                MessageContent = r["message_content"]?.ToString(),
                Timestamp = (DateTime)r["timestamp"],
                ReadStatus = (bool)r["read_status"],
                Urgency = r["urgency"]?.ToString(),
                NotificationType = r["notification_type"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<int> GetUnreadNotificationCountAsync(int employeeId)
    {
        var cmd = new SqlCommand(@"
            SELECT COUNT(*)
            FROM Notification n
            JOIN Employee_Notification en ON n.notification_id = en.notification_id
            WHERE en.employee_id = @id AND n.read_status = 0", _conn);

        cmd.Parameters.AddWithValue("@id", employeeId);

        await _conn.OpenAsync();
        var count = Convert.ToInt32(await cmd.ExecuteScalarAsync());
        await _conn.CloseAsync();

        return count;
    }

    public async Task MarkNotificationAsReadAsync(int notificationId, int employeeId)
    {
        var cmd = new SqlCommand(@"
            UPDATE Notification
            SET read_status = 1
            WHERE notification_id = @nid
            AND EXISTS (
                SELECT 1 FROM Employee_Notification 
                WHERE employee_id = @eid AND notification_id = @nid
            )", _conn);

        cmd.Parameters.AddWithValue("@nid", notificationId);
        cmd.Parameters.AddWithValue("@eid", employeeId);

        await _conn.OpenAsync();
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task MarkAllNotificationsAsReadAsync(int employeeId)
    {
        var cmd = new SqlCommand(@"
            UPDATE n
            SET n.read_status = 1
            FROM Notification n
            INNER JOIN Employee_Notification en ON n.notification_id = en.notification_id
            WHERE en.employee_id = @eid AND n.read_status = 0", _conn);

        cmd.Parameters.AddWithValue("@eid", employeeId);

        await _conn.OpenAsync();
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<Contract?> GetEmployeeContract(int employeeId)
    {
        var cmd = new SqlCommand(@"
            SELECT c.*
            FROM Contract c
            JOIN Employee e ON e.contract_id = c.contract_id
            WHERE e.employee_id = @id", _conn);

        cmd.Parameters.AddWithValue("@id", employeeId);

        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        if (!await r.ReadAsync())
        {
            await _conn.CloseAsync();
            return null;
        }

        var contract = new Contract
        {
            ContractId = (int)r["contract_id"],
            Type = r["type"]?.ToString(),
            StartDate = r["start_date"] == DBNull.Value ? null : (DateTime?)r["start_date"],
            EndDate = r["end_date"] == DBNull.Value ? null : (DateTime?)r["end_date"],
            CurrentState = r["current_state"]?.ToString()
        };

        await _conn.CloseAsync();
        return contract;
    }

    public async Task<bool> IsEmployeeInManagerTeam(int managerId, int employeeId)
    {
        const string sql = """
            SELECT COUNT(*)
            FROM Employee
            WHERE employee_id = @EmployeeId
              AND manager_id = @ManagerId
        """;

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@EmployeeId", employeeId);
        cmd.Parameters.AddWithValue("@ManagerId", managerId);
        
        int count = Convert.ToInt32(await cmd.ExecuteScalarAsync());
        await _conn.CloseAsync();
        
        return count > 0;
    }

    public async Task AssignRoleToEmployee(int employeeId, int roleId)
    {
        const string sql = """
            IF NOT EXISTS (
                SELECT 1 FROM Employee_Role
                WHERE employee_id = @EmployeeId AND role_id = @RoleId
            )
            BEGIN
                INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
                VALUES (@EmployeeId, @RoleId, GETDATE())
            END
        """;

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@EmployeeId", employeeId);
        cmd.Parameters.AddWithValue("@RoleId", roleId);
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task RemoveRoleFromEmployee(int employeeId, int roleId)
    {
        const string sql = """
            DELETE FROM Employee_Role
            WHERE employee_id = @EmployeeId AND role_id = @RoleId
        """;

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@EmployeeId", employeeId);
        cmd.Parameters.AddWithValue("@RoleId", roleId);
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<List<int>> GetEmployeeRoles(int employeeId)
    {
        const string sql = """
            SELECT role_id
            FROM Employee_Role
            WHERE employee_id = @EmployeeId
        """;

        var roles = new List<int>();
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@EmployeeId", employeeId);
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            roles.Add((int)r["role_id"]);
        }

        await _conn.CloseAsync();
        return roles;
    }

    // ========== SHIFT MANAGEMENT METHODS ==========

    public async Task<int> CreateShiftTypeAsync(string name, string type, TimeSpan startTime, TimeSpan endTime, int breakDuration, DateTime? shiftDate, string status)
    {
        await _conn.OpenAsync();
        
        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(shift_id), 0) + 1 FROM ShiftSchedule", _conn);
        int shiftId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());
        
        var cmd = new SqlCommand(@"
            INSERT INTO ShiftSchedule (shift_id, name, type, start_time, end_time, break_duration, shift_date, status)
            VALUES (@id, @name, @type, @start, @end, @break, @date, @status)", _conn);
        
        cmd.Parameters.AddWithValue("@id", shiftId);
        cmd.Parameters.AddWithValue("@name", name);
        cmd.Parameters.AddWithValue("@type", type);
        cmd.Parameters.AddWithValue("@start", startTime);
        cmd.Parameters.AddWithValue("@end", endTime);
        cmd.Parameters.AddWithValue("@break", breakDuration);
        cmd.Parameters.AddWithValue("@date", shiftDate ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("@status", status);
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
        return shiftId;
    }

    public async Task<List<Shift>> GetAllShiftTypesAsync()
    {
        var list = new List<Shift>();
        const string sql = "SELECT shift_id, name, type, start_time, end_time, break_duration, shift_date, status FROM ShiftSchedule ORDER BY shift_id";
        
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        using var r = await cmd.ExecuteReaderAsync();
        
        while (await r.ReadAsync())
        {
            list.Add(new Shift
            {
                ShiftId = (int)r["shift_id"],
                Name = r["name"]?.ToString(),
                Type = r["type"]?.ToString(),
                StartTime = r["start_time"] == DBNull.Value ? null : (TimeSpan?)r["start_time"],
                EndTime = r["end_time"] == DBNull.Value ? null : (TimeSpan?)r["end_time"],
                BreakDuration = r["break_duration"] == DBNull.Value ? null : (int?)r["break_duration"],
                ShiftDate = r["shift_date"] == DBNull.Value ? null : (DateTime?)r["shift_date"],
                Status = r["status"]?.ToString()
            });
        }
        
        await _conn.CloseAsync();
        return list;
    }

    public async Task<Shift?> GetShiftByIdAsync(int shiftId)
    {
        const string sql = "SELECT shift_id, name, type, start_time, end_time, break_duration, shift_date, status FROM ShiftSchedule WHERE shift_id = @id";
        
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@id", shiftId);
        using var r = await cmd.ExecuteReaderAsync();
        
        if (!await r.ReadAsync())
        {
            await _conn.CloseAsync();
            return null;
        }
        
        var shift = new Shift
        {
            ShiftId = (int)r["shift_id"],
            Name = r["name"]?.ToString(),
            Type = r["type"]?.ToString(),
            StartTime = r["start_time"] == DBNull.Value ? null : (TimeSpan?)r["start_time"],
            EndTime = r["end_time"] == DBNull.Value ? null : (TimeSpan?)r["end_time"],
            BreakDuration = r["break_duration"] == DBNull.Value ? null : (int?)r["break_duration"],
            ShiftDate = r["shift_date"] == DBNull.Value ? null : (DateTime?)r["shift_date"],
            Status = r["status"]?.ToString()
        };
        
        await _conn.CloseAsync();
        return shift;
    }

    public async Task AssignShiftToEmployeeAsync(int employeeId, int shiftId, DateTime startDate, DateTime endDate)
    {
        await _conn.OpenAsync();
        
        using var cmd = new SqlCommand("AssignShiftToEmployee", _conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddWithValue("@EmployeeID", employeeId);
        cmd.Parameters.AddWithValue("@ShiftID", shiftId);
        cmd.Parameters.AddWithValue("@StartDate", startDate);
        cmd.Parameters.AddWithValue("@EndDate", endDate);
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task AssignShiftToDepartmentAsync(int departmentId, int shiftId, DateTime startDate, DateTime endDate)
    {
        await _conn.OpenAsync();
        
        using var cmd = new SqlCommand("AssignShiftToDepartment", _conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddWithValue("@DepartmentID", departmentId);
        cmd.Parameters.AddWithValue("@ShiftID", shiftId);
        cmd.Parameters.AddWithValue("@StartDate", startDate);
        cmd.Parameters.AddWithValue("@EndDate", endDate);
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<int> CreateCustomShiftAsync(int employeeId, string shiftName, string shiftType, TimeSpan startTime, TimeSpan endTime, int breakDuration, DateTime startDate, DateTime endDate)
    {
        await _conn.OpenAsync();
        
        using var cmd = new SqlCommand("AssignCustomShift", _conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddWithValue("@EmployeeID", employeeId);
        cmd.Parameters.AddWithValue("@ShiftName", shiftName);
        cmd.Parameters.AddWithValue("@ShiftType", shiftType);
        cmd.Parameters.AddWithValue("@StartTime", startTime);
        cmd.Parameters.AddWithValue("@EndTime", endTime);
        cmd.Parameters.AddWithValue("@BreakDuration", breakDuration);
        cmd.Parameters.AddWithValue("@StartDate", startDate);
        cmd.Parameters.AddWithValue("@EndDate", endDate);
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
        return 0;
    }

    public async Task ConfigureSplitShiftAsync(string shiftName, TimeSpan firstStart, TimeSpan firstEnd, TimeSpan secondStart, TimeSpan secondEnd, int breakDuration)
    {
        await _conn.OpenAsync();
        
        using var cmd = new SqlCommand("ConfigureSplitShift", _conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddWithValue("@ShiftName", shiftName);
        cmd.Parameters.AddWithValue("@FirstSlotStart", firstStart);
        cmd.Parameters.AddWithValue("@FirstSlotEnd", firstEnd);
        cmd.Parameters.AddWithValue("@SecondSlotStart", secondStart);
        cmd.Parameters.AddWithValue("@SecondSlotEnd", secondEnd);
        // Note: BreakDuration is calculated automatically in the stored procedure
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task AssignRotationalShiftAsync(int employeeId, int shiftCycle, DateTime startDate, DateTime endDate, string status)
    {
        await _conn.OpenAsync();
        
        using var cmd = new SqlCommand("AssignRotationalShift", _conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddWithValue("@EmployeeID", employeeId);
        cmd.Parameters.AddWithValue("@ShiftCycle", shiftCycle);
        cmd.Parameters.AddWithValue("@StartDate", startDate);
        cmd.Parameters.AddWithValue("@EndDate", endDate);
        cmd.Parameters.AddWithValue("@status", status);
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<List<ShiftAssignment>> GetEmployeeShiftsAsync(int employeeId)
    {
        var list = new List<ShiftAssignment>();
        const string sql = @"
            SELECT sa.assignment_id, sa.employee_id, e.full_name, sa.shift_id, s.name as shift_name,
                   sa.start_date, sa.end_date, sa.status
            FROM ShiftAssignment sa
            LEFT JOIN Employee e ON sa.employee_id = e.employee_id
            LEFT JOIN ShiftSchedule s ON sa.shift_id = s.shift_id
            WHERE sa.employee_id = @empId
            ORDER BY sa.start_date DESC";
        
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@empId", employeeId);
        using var r = await cmd.ExecuteReaderAsync();
        
        while (await r.ReadAsync())
        {
            list.Add(new ShiftAssignment
            {
                AssignmentId = (int)r["assignment_id"],
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString(),
                ShiftId = (int)r["shift_id"],
                ShiftName = r["shift_name"]?.ToString(),
                StartDate = r["start_date"] == DBNull.Value ? null : (DateTime?)r["start_date"],
                EndDate = r["end_date"] == DBNull.Value ? null : (DateTime?)r["end_date"],
                Status = r["status"]?.ToString()
            });
        }
        
        await _conn.CloseAsync();
        return list;
    }

    public async Task<List<ShiftAssignment>> GetAllShiftAssignmentsAsync()
    {
        var list = new List<ShiftAssignment>();
        const string sql = @"
            SELECT sa.assignment_id, sa.employee_id, e.full_name, sa.shift_id, s.name as shift_name,
                   sa.start_date, sa.end_date, sa.status
            FROM ShiftAssignment sa
            LEFT JOIN Employee e ON sa.employee_id = e.employee_id
            LEFT JOIN ShiftSchedule s ON sa.shift_id = s.shift_id
            ORDER BY sa.start_date DESC";
        
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        using var r = await cmd.ExecuteReaderAsync();
        
        while (await r.ReadAsync())
        {
            list.Add(new ShiftAssignment
            {
                AssignmentId = (int)r["assignment_id"],
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString(),
                ShiftId = (int)r["shift_id"],
                ShiftName = r["shift_name"]?.ToString(),
                StartDate = r["start_date"] == DBNull.Value ? null : (DateTime?)r["start_date"],
                EndDate = r["end_date"] == DBNull.Value ? null : (DateTime?)r["end_date"],
                Status = r["status"]?.ToString()
            });
        }
        
        await _conn.CloseAsync();
        return list;
    }

    public async Task<List<Department>> GetAllDepartmentsAsync()
    {
        var list = new List<Department>();
        const string sql = "SELECT department_id, department_name, purpose FROM Department ORDER BY department_name";
        
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        using var r = await cmd.ExecuteReaderAsync();
        
        while (await r.ReadAsync())
        {
            list.Add(new Department
            {
                DepartmentId = (int)r["department_id"],
                DepartmentName = r["department_name"]?.ToString(),
                Purpose = r["purpose"]?.ToString()
            });
        }
        
        await _conn.CloseAsync();
        return list;
    }

    // ========== ATTENDANCE MANAGEMENT METHODS ==========

    public async Task<int> RecordAttendanceAsync(int employeeId, int? shiftId, DateTime entryTime, string loginMethod)
    {
        await _conn.OpenAsync();
        
        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(attendance_id), 0) + 1 FROM Attendance", _conn);
        int attendanceId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());
        
        var cmd = new SqlCommand(@"
            INSERT INTO Attendance (attendance_id, employee_id, shift_id, entry_time, login_method)
            VALUES (@id, @empId, @shiftId, @entry, @method)", _conn);
        
        cmd.Parameters.AddWithValue("@id", attendanceId);
        cmd.Parameters.AddWithValue("@empId", employeeId);
        cmd.Parameters.AddWithValue("@shiftId", shiftId ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("@entry", entryTime);
        cmd.Parameters.AddWithValue("@method", loginMethod);
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
        return attendanceId;
    }

    public async Task UpdateAttendanceExitAsync(int attendanceId, DateTime exitTime, string logoutMethod)
    {
        await _conn.OpenAsync();
        
        var cmd = new SqlCommand(@"
            UPDATE Attendance 
            SET exit_time = @exit, logout_method = @method,
                duration = DATEDIFF(MINUTE, entry_time, @exit)
            WHERE attendance_id = @id", _conn);
        
        cmd.Parameters.AddWithValue("@id", attendanceId);
        cmd.Parameters.AddWithValue("@exit", exitTime);
        cmd.Parameters.AddWithValue("@method", logoutMethod);
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<Attendance?> GetTodayAttendanceAsync(int employeeId)
    {
        const string sql = @"
            SELECT a.attendance_id, a.employee_id, e.full_name, a.shift_id, s.name as shift_name,
                   a.entry_time, a.exit_time, a.duration, a.login_method, a.logout_method
            FROM Attendance a
            LEFT JOIN Employee e ON a.employee_id = e.employee_id
            LEFT JOIN ShiftSchedule s ON a.shift_id = s.shift_id
            WHERE a.employee_id = @empId 
              AND CAST(a.entry_time AS DATE) = CAST(GETDATE() AS DATE)";
        
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@empId", employeeId);
        using var r = await cmd.ExecuteReaderAsync();
        
        if (!await r.ReadAsync())
        {
            await _conn.CloseAsync();
            return null;
        }
        
        var attendance = new Attendance
        {
            AttendanceId = (int)r["attendance_id"],
            EmployeeId = (int)r["employee_id"],
            EmployeeName = r["full_name"]?.ToString(),
            ShiftId = r["shift_id"] == DBNull.Value ? null : (int?)r["shift_id"],
            ShiftName = r["shift_name"]?.ToString(),
            EntryTime = r["entry_time"] == DBNull.Value ? null : (DateTime?)r["entry_time"],
            ExitTime = r["exit_time"] == DBNull.Value ? null : (DateTime?)r["exit_time"],
            Duration = r["duration"] == DBNull.Value ? null : (int?)r["duration"],
            LoginMethod = r["login_method"]?.ToString(),
            LogoutMethod = r["logout_method"]?.ToString()
        };
        
        await _conn.CloseAsync();
        return attendance;
    }

    public async Task<List<Attendance>> GetEmployeeAttendanceAsync(int employeeId, DateTime? startDate = null, DateTime? endDate = null)
    {
        var list = new List<Attendance>();
        string sql = @"
            SELECT a.attendance_id, a.employee_id, e.full_name, a.shift_id, s.name as shift_name,
                   a.entry_time, a.exit_time, a.duration, a.login_method, a.logout_method
            FROM Attendance a
            LEFT JOIN Employee e ON a.employee_id = e.employee_id
            LEFT JOIN ShiftSchedule s ON a.shift_id = s.shift_id
            WHERE a.employee_id = @empId";
        
        if (startDate.HasValue)
            sql += " AND CAST(a.entry_time AS DATE) >= @start";
        if (endDate.HasValue)
            sql += " AND CAST(a.entry_time AS DATE) <= @end";
        
        sql += " ORDER BY a.entry_time DESC";
        
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@empId", employeeId);
        if (startDate.HasValue)
            cmd.Parameters.AddWithValue("@start", startDate.Value);
        if (endDate.HasValue)
            cmd.Parameters.AddWithValue("@end", endDate.Value);
        
        using var r = await cmd.ExecuteReaderAsync();
        while (await r.ReadAsync())
        {
            list.Add(new Attendance
            {
                AttendanceId = (int)r["attendance_id"],
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString(),
                ShiftId = r["shift_id"] == DBNull.Value ? null : (int?)r["shift_id"],
                ShiftName = r["shift_name"]?.ToString(),
                EntryTime = r["entry_time"] == DBNull.Value ? null : (DateTime?)r["entry_time"],
                ExitTime = r["exit_time"] == DBNull.Value ? null : (DateTime?)r["exit_time"],
                Duration = r["duration"] == DBNull.Value ? null : (int?)r["duration"],
                LoginMethod = r["login_method"]?.ToString(),
                LogoutMethod = r["logout_method"]?.ToString()
            });
        }
        
        await _conn.CloseAsync();
        return list;
    }

    public async Task<int> SubmitAttendanceCorrectionRequestAsync(int employeeId, DateTime date, string correctionType, string reason)
    {
        await _conn.OpenAsync();
        
        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(request_id), 0) + 1 FROM AttendanceCorrectionRequest", _conn);
        int requestId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());
        
        var cmd = new SqlCommand(@"
            INSERT INTO AttendanceCorrectionRequest (request_id, employee_id, date, correction_type, reason, status, recorded_by)
            VALUES (@id, @empId, @date, @type, @reason, 'Pending', @empId)", _conn);
        
        cmd.Parameters.AddWithValue("@id", requestId);
        cmd.Parameters.AddWithValue("@empId", employeeId);
        cmd.Parameters.AddWithValue("@date", date);
        cmd.Parameters.AddWithValue("@type", correctionType);
        cmd.Parameters.AddWithValue("@reason", reason);
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
        return requestId;
    }

    public async Task<List<AttendanceCorrectionRequest>> GetAttendanceCorrectionRequestsAsync(int employeeId)
    {
        var list = new List<AttendanceCorrectionRequest>();
        const string sql = @"
            SELECT acr.request_id, acr.employee_id, e.full_name, acr.date, acr.correction_type, 
                   acr.reason, acr.status, acr.recorded_by
            FROM AttendanceCorrectionRequest acr
            LEFT JOIN Employee e ON acr.employee_id = e.employee_id
            WHERE acr.employee_id = @empId
            ORDER BY acr.date DESC";
        
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@empId", employeeId);
        using var r = await cmd.ExecuteReaderAsync();
        
        while (await r.ReadAsync())
        {
            list.Add(new AttendanceCorrectionRequest
            {
                RequestId = (int)r["request_id"],
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString(),
                Date = (DateTime)r["date"],
                CorrectionType = r["correction_type"]?.ToString(),
                Reason = r["reason"]?.ToString(),
                Status = r["status"]?.ToString(),
                RecordedBy = r["recorded_by"] == DBNull.Value ? null : (int?)r["recorded_by"]
            });
        }
        
        await _conn.CloseAsync();
        return list;
    }

    public async Task SyncLeaveToAttendanceAsync(int leaveRequestId)
    {
        await _conn.OpenAsync();
        
        using var cmd = new SqlCommand("SyncLeaveToAttendance", _conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddWithValue("@LeaveRequestID", leaveRequestId);
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<List<TeamAttendanceSummary>> GetTeamAttendanceSummaryAsync(int managerId, DateTime? startDate = null, DateTime? endDate = null)
    {
        var list = new List<TeamAttendanceSummary>();
        string sql = @"
            SELECT e.employee_id, e.full_name, CAST(COALESCE(a.entry_time, @start) AS DATE) as date,
                   a.entry_time, a.exit_time, a.duration,
                   CASE 
                       WHEN a.entry_time IS NULL THEN 'Absent'
                       WHEN a.exit_time IS NULL THEN 'Incomplete'
                       ELSE 'Complete'
                   END as status
            FROM Employee e
            LEFT JOIN Attendance a ON e.employee_id = a.employee_id 
                AND (@start IS NULL OR CAST(a.entry_time AS DATE) >= @start)
                AND (@end IS NULL OR CAST(a.entry_time AS DATE) <= @end)
            WHERE e.manager_id = @managerId
            ORDER BY date DESC, e.full_name";
        
        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@managerId", managerId);
        cmd.Parameters.AddWithValue("@start", startDate ?? DateTime.Today.AddDays(-30));
        cmd.Parameters.AddWithValue("@end", endDate ?? DateTime.Today);
        
        using var r = await cmd.ExecuteReaderAsync();
        while (await r.ReadAsync())
        {
            list.Add(new TeamAttendanceSummary
            {
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString(),
                Date = (DateTime)r["date"],
                EntryTime = r["entry_time"] == DBNull.Value ? null : (DateTime?)r["entry_time"],
                ExitTime = r["exit_time"] == DBNull.Value ? null : (DateTime?)r["exit_time"],
                Duration = r["duration"] == DBNull.Value ? null : (int?)r["duration"],
                Status = r["status"]?.ToString()
            });
        }
        
        await _conn.CloseAsync();
        return list;
    }

    public async Task SyncOfflineAttendanceAsync(int employeeId, int deviceId, DateTime clockTime, string type)
    {
        await _conn.OpenAsync();
        
        using var cmd = new SqlCommand("SyncOfflineAttendance", _conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddWithValue("@EmployeeID", employeeId);
        cmd.Parameters.AddWithValue("@DeviceID", deviceId);
        cmd.Parameters.AddWithValue("@ClockTime", clockTime);
        cmd.Parameters.AddWithValue("@Type", type); // 'IN' or 'OUT'
        
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    // ========== LEAVE MANAGEMENT METHODS ==========

    public async Task<List<Leave>> GetAllLeaveTypesAsync()
    {
        var list = new List<Leave>();
        const string sql = "SELECT leave_id, leave_type, leave_description FROM Leave ORDER BY leave_type";

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new Leave
            {
                LeaveId = (int)r["leave_id"],
                LeaveType = r["leave_type"]?.ToString(),
                LeaveDescription = r["leave_description"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<int> SubmitLeaveRequestAsync(int employeeId, int leaveId, DateTime startDate, DateTime endDate, string justification)
    {
        await _conn.OpenAsync();

        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(request_id), 0) + 1 FROM LeaveRequest", _conn);
        int requestId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());

        int duration = (endDate - startDate).Days + 1;

        var cmd = new SqlCommand(@"
            INSERT INTO LeaveRequest (request_id, employee_id, leave_id, justification, duration, approval_timing, status)
            VALUES (@id, @empId, @leaveId, @justification, @duration, 'Pending', 'Pending')", _conn);

        cmd.Parameters.AddWithValue("@id", requestId);
        cmd.Parameters.AddWithValue("@empId", employeeId);
        cmd.Parameters.AddWithValue("@leaveId", leaveId);
        cmd.Parameters.AddWithValue("@justification", justification ?? "");
        cmd.Parameters.AddWithValue("@duration", duration);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
        return requestId;
    }

    public async Task<List<LeaveRequest>> GetEmployeeLeaveRequestsAsync(int employeeId)
    {
        var list = new List<LeaveRequest>();
        const string sql = @"
            SELECT lr.request_id, lr.employee_id, e.full_name, lr.leave_id, l.leave_type,
                   lr.justification, lr.duration, lr.approval_timing, lr.status
            FROM LeaveRequest lr
            LEFT JOIN Employee e ON lr.employee_id = e.employee_id
            LEFT JOIN Leave l ON lr.leave_id = l.leave_id
            WHERE lr.employee_id = @empId
            ORDER BY lr.request_id DESC";

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@empId", employeeId);
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new LeaveRequest
            {
                RequestId = (int)r["request_id"],
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString(),
                LeaveId = (int)r["leave_id"],
                LeaveType = r["leave_type"]?.ToString(),
                Duration = r["duration"] == DBNull.Value ? 0 : (int)r["duration"],
                Justification = r["justification"]?.ToString(),
                Status = r["status"]?.ToString(),
                ApprovalTiming = r["approval_timing"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<LeaveRequest?> GetLeaveRequestByIdAsync(int requestId)
    {
        const string sql = @"
            SELECT lr.request_id, lr.employee_id, e.full_name, lr.leave_id, l.leave_type,
                   lr.justification, lr.duration, lr.approval_timing, lr.status
            FROM LeaveRequest lr
            LEFT JOIN Employee e ON lr.employee_id = e.employee_id
            LEFT JOIN Leave l ON lr.leave_id = l.leave_id
            WHERE lr.request_id = @requestId";

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@requestId", requestId);
        using var r = await cmd.ExecuteReaderAsync();

        if (!await r.ReadAsync())
        {
            await _conn.CloseAsync();
            return null;
        }

        var request = new LeaveRequest
        {
            RequestId = (int)r["request_id"],
            EmployeeId = (int)r["employee_id"],
            EmployeeName = r["full_name"]?.ToString(),
            LeaveId = (int)r["leave_id"],
            LeaveType = r["leave_type"]?.ToString(),
            Duration = r["duration"] == DBNull.Value ? 0 : (int)r["duration"],
            Justification = r["justification"]?.ToString(),
            Status = r["status"]?.ToString(),
            ApprovalTiming = r["approval_timing"]?.ToString()
        };

        await _conn.CloseAsync();
        return request;
    }

    public async Task<List<LeaveEntitlement>> GetEmployeeLeaveBalanceAsync(int employeeId)
    {
        var list = new List<LeaveEntitlement>();
        const string sql = @"
            SELECT 
                le.employee_id,
                e.full_name,
                le.leave_type_id,
                l.leave_type,
                le.entitlement,
                ISNULL(SUM(CASE WHEN lr.status = 'Approved' OR lr.status = 'Finalized' THEN lr.duration ELSE 0 END), 0) as used
            FROM LeaveEntitlement le
            LEFT JOIN Employee e ON le.employee_id = e.employee_id
            LEFT JOIN Leave l ON le.leave_type_id = l.leave_id
            LEFT JOIN LeaveRequest lr ON le.employee_id = lr.employee_id AND le.leave_type_id = lr.leave_id
            WHERE le.employee_id = @empId
            GROUP BY le.employee_id, e.full_name, le.leave_type_id, l.leave_type, le.entitlement
            ORDER BY l.leave_type";

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@empId", employeeId);
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            decimal entitlement = Convert.ToDecimal(r["entitlement"]);
            decimal used = Convert.ToDecimal(r["used"]);
            decimal remaining = entitlement - used;

            list.Add(new LeaveEntitlement
            {
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString(),
                LeaveTypeId = (int)r["leave_type_id"],
                LeaveType = r["leave_type"]?.ToString(),
                Entitlement = entitlement,
                Used = used,
                Remaining = remaining
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<int> UploadLeaveDocumentAsync(int leaveRequestId, string fileName)
    {
        await _conn.OpenAsync();

        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(document_id), 0) + 1 FROM LeaveDocument", _conn);
        int documentId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());

        var cmd = new SqlCommand(@"
            INSERT INTO LeaveDocument (document_id, leave_request_id, file_path, uploaded_at)
            VALUES (@id, @requestId, @filePath, GETDATE())", _conn);

        cmd.Parameters.AddWithValue("@id", documentId);
        cmd.Parameters.AddWithValue("@requestId", leaveRequestId);
        cmd.Parameters.AddWithValue("@filePath", fileName);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
        return documentId;
    }

    public async Task<List<LeaveDocument>> GetLeaveRequestDocumentsAsync(int leaveRequestId)
    {
        var list = new List<LeaveDocument>();
        const string sql = @"
            SELECT document_id, leave_request_id, file_path, uploaded_at
            FROM LeaveDocument
            WHERE leave_request_id = @requestId
            ORDER BY uploaded_at DESC";

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        cmd.Parameters.AddWithValue("@requestId", leaveRequestId);
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            string? filePath = r["file_path"]?.ToString();
            list.Add(new LeaveDocument
            {
                DocumentId = (int)r["document_id"],
                LeaveRequestId = (int)r["leave_request_id"],
                FilePath = filePath,
                FileName = filePath != null ? Path.GetFileName(filePath) : null,
                UploadedAt = r["uploaded_at"] == DBNull.Value ? null : (DateTime?)r["uploaded_at"]
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    // ========== MANAGER LEAVE METHODS ==========

    public async Task<List<LeaveRequest>> GetPendingLeaveRequestsAsync(int? managerId = null)
    {
        var list = new List<LeaveRequest>();
        string sql = @"
            SELECT lr.request_id, lr.employee_id, e.full_name, lr.leave_id, l.leave_type,
                   lr.justification, lr.duration, lr.approval_timing, lr.status
            FROM LeaveRequest lr
            LEFT JOIN Employee e ON lr.employee_id = e.employee_id
            LEFT JOIN Leave l ON lr.leave_id = l.leave_id
            WHERE lr.status = 'Pending'";

        if (managerId.HasValue)
        {
            sql += " AND e.manager_id = @managerId";
        }

        sql += " ORDER BY lr.request_id DESC";

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        if (managerId.HasValue)
        {
            cmd.Parameters.AddWithValue("@managerId", managerId.Value);
        }
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new LeaveRequest
            {
                RequestId = (int)r["request_id"],
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString(),
                LeaveId = (int)r["leave_id"],
                LeaveType = r["leave_type"]?.ToString(),
                Duration = r["duration"] == DBNull.Value ? 0 : (int)r["duration"],
                Justification = r["justification"]?.ToString(),
                Status = r["status"]?.ToString(),
                ApprovalTiming = r["approval_timing"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task ApproveLeaveRequestAsync(int requestId, int approvedBy, string? comments = null)
    {
        await _conn.OpenAsync();

        // Keep message short to fit VARCHAR(50) - format: "Approved by ID on YYYY-MM-DD"
        string timing = $"Appr by {approvedBy} {DateTime.Now:yyyy-MM-dd}";
        if (timing.Length > 50) timing = timing.Substring(0, 50);

        var cmd = new SqlCommand(@"
            UPDATE LeaveRequest 
            SET status = 'Approved', 
                approval_timing = @timing
            WHERE request_id = @requestId", _conn);

        cmd.Parameters.AddWithValue("@requestId", requestId);
        cmd.Parameters.AddWithValue("@timing", timing);

        await cmd.ExecuteNonQueryAsync();

        // Update leave balance (deduct from entitlement)
        var balanceCmd = new SqlCommand(@"
            DECLARE @EmployeeID INT, @LeaveID INT, @Duration INT;
            SELECT @EmployeeID = employee_id, @LeaveID = leave_id, @Duration = duration
            FROM LeaveRequest
            WHERE request_id = @requestId;

            UPDATE LeaveEntitlement
            SET entitlement = entitlement - @Duration
            WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveID", _conn);

        balanceCmd.Parameters.AddWithValue("@requestId", requestId);
        await balanceCmd.ExecuteNonQueryAsync();

        await _conn.CloseAsync();
    }

    public async Task DenyLeaveRequestAsync(int requestId, int deniedBy, string reason)
    {
        await _conn.OpenAsync();

        // Keep message short to fit VARCHAR(50) - format: "Rejected by ID on YYYY-MM-DD"
        string timing = $"Rej by {deniedBy} {DateTime.Now:yyyy-MM-dd}";
        if (timing.Length > 50) timing = timing.Substring(0, 50);

        var cmd = new SqlCommand(@"
            UPDATE LeaveRequest 
            SET status = 'Rejected', 
                approval_timing = @timing,
                justification = CAST(justification AS NVARCHAR(MAX)) + ' | Rejection: ' + @reason
            WHERE request_id = @requestId", _conn);

        cmd.Parameters.AddWithValue("@requestId", requestId);
        cmd.Parameters.AddWithValue("@timing", timing);
        cmd.Parameters.AddWithValue("@reason", reason ?? "No reason provided");

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task FlagIrregularLeavePatternAsync(int employeeId, string reason)
    {
        await _conn.OpenAsync();

        // Create a notification for HR about irregular pattern
        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(notification_id), 0) + 1 FROM Notification", _conn);
        int notificationId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());

        var notifCmd = new SqlCommand(@"
            INSERT INTO Notification (notification_id, message_content, timestamp, urgency, read_status, notification_type)
            VALUES (@nid, @msg, GETDATE(), 'High', 0, 'Leave')", _conn);

        notifCmd.Parameters.AddWithValue("@nid", notificationId);
        notifCmd.Parameters.AddWithValue("@msg", $"Irregular leave pattern flagged for employee {employeeId}. Reason: {reason}");

        await notifCmd.ExecuteNonQueryAsync();

        // Assign to HR Admin (assuming role_id 1 is HR Admin - adjust as needed)
        var linkCmd = new SqlCommand(@"
            INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
            SELECT employee_id, @nid, 'Delivered', GETDATE()
            FROM Employee_Role er
            WHERE er.role_id IN (SELECT role_id FROM Role WHERE role_name = 'HR Admin')", _conn);

        linkCmd.Parameters.AddWithValue("@nid", notificationId);
        await linkCmd.ExecuteNonQueryAsync();

        await _conn.CloseAsync();
    }

    // ========== HR ADMIN LEAVE METHODS ==========

    public async Task<int> CreateLeaveTypeAsync(string leaveType, string description)
    {
        await _conn.OpenAsync();

        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(leave_id), 0) + 1 FROM Leave", _conn);
        int leaveId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());

        var cmd = new SqlCommand(@"
            INSERT INTO Leave (leave_id, leave_type, leave_description)
            VALUES (@id, @type, @description)", _conn);

        cmd.Parameters.AddWithValue("@id", leaveId);
        cmd.Parameters.AddWithValue("@type", leaveType);
        cmd.Parameters.AddWithValue("@description", description);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
        return leaveId;
    }

    public async Task<int> CreateLeavePolicyAsync(string name, string purpose, string eligibilityRules, int noticePeriod, string specialLeaveType, bool resetOnNewYear)
    {
        await _conn.OpenAsync();

        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(policy_id), 0) + 1 FROM LeavePolicy", _conn);
        int policyId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());

        var cmd = new SqlCommand(@"
            INSERT INTO LeavePolicy (policy_id, name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
            VALUES (@id, @name, @purpose, @rules, @notice, @type, @reset)", _conn);

        cmd.Parameters.AddWithValue("@id", policyId);
        cmd.Parameters.AddWithValue("@name", name);
        cmd.Parameters.AddWithValue("@purpose", purpose);
        cmd.Parameters.AddWithValue("@rules", eligibilityRules);
        cmd.Parameters.AddWithValue("@notice", noticePeriod);
        cmd.Parameters.AddWithValue("@type", specialLeaveType);
        cmd.Parameters.AddWithValue("@reset", resetOnNewYear);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
        return policyId;
    }

    public async Task AssignLeaveEntitlementAsync(int employeeId, int leaveTypeId, decimal entitlement)
    {
        await _conn.OpenAsync();

        var cmd = new SqlCommand(@"
            IF EXISTS (SELECT 1 FROM LeaveEntitlement WHERE employee_id = @empId AND leave_type_id = @leaveId)
                UPDATE LeaveEntitlement SET entitlement = @entitlement WHERE employee_id = @empId AND leave_type_id = @leaveId
            ELSE
                INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
                VALUES (@empId, @leaveId, @entitlement)", _conn);

        cmd.Parameters.AddWithValue("@empId", employeeId);
        cmd.Parameters.AddWithValue("@leaveId", leaveTypeId);
        cmd.Parameters.AddWithValue("@entitlement", entitlement);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task AdjustLeaveEntitlementAsync(int employeeId, int leaveTypeId, decimal adjustment)
    {
        await _conn.OpenAsync();

        var cmd = new SqlCommand(@"
            UPDATE LeaveEntitlement
            SET entitlement = entitlement + @adjustment
            WHERE employee_id = @empId AND leave_type_id = @leaveId", _conn);

        cmd.Parameters.AddWithValue("@empId", employeeId);
        cmd.Parameters.AddWithValue("@leaveId", leaveTypeId);
        cmd.Parameters.AddWithValue("@adjustment", adjustment);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task OverrideLeaveDecisionAsync(int requestId, string newStatus, string reason, int overriddenBy)
    {
        await _conn.OpenAsync();

        // Keep message short to fit VARCHAR(50) - format: "Overridden by ID on YYYY-MM-DD"
        // Don't append to existing value, replace it to avoid truncation
        string timing = $"Over by {overriddenBy} {DateTime.Now:yyyy-MM-dd}";
        if (timing.Length > 50) timing = timing.Substring(0, 50);

        var cmd = new SqlCommand(@"
            UPDATE LeaveRequest 
            SET status = @status, 
                approval_timing = @timing,
                justification = CAST(justification AS NVARCHAR(MAX)) + ' | Override: ' + @reason
            WHERE request_id = @requestId", _conn);

        cmd.Parameters.AddWithValue("@requestId", requestId);
        cmd.Parameters.AddWithValue("@status", newStatus);
        cmd.Parameters.AddWithValue("@timing", timing);
        cmd.Parameters.AddWithValue("@reason", reason);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<List<LeaveRequest>> GetAllLeaveRequestsAsync(string? status = null)
    {
        var list = new List<LeaveRequest>();
        string sql = @"
            SELECT lr.request_id, lr.employee_id, e.full_name, lr.leave_id, l.leave_type,
                   lr.justification, lr.duration, lr.approval_timing, lr.status
            FROM LeaveRequest lr
            LEFT JOIN Employee e ON lr.employee_id = e.employee_id
            LEFT JOIN Leave l ON lr.leave_id = l.leave_id";

        if (!string.IsNullOrEmpty(status))
        {
            sql += " WHERE lr.status = @status";
        }

        sql += " ORDER BY lr.request_id DESC";

        await _conn.OpenAsync();
        using var cmd = new SqlCommand(sql, _conn);
        if (!string.IsNullOrEmpty(status))
        {
            cmd.Parameters.AddWithValue("@status", status);
        }
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new LeaveRequest
            {
                RequestId = (int)r["request_id"],
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString(),
                LeaveId = (int)r["leave_id"],
                LeaveType = r["leave_type"]?.ToString(),
                Duration = r["duration"] == DBNull.Value ? 0 : (int)r["duration"],
                Justification = r["justification"]?.ToString(),
                Status = r["status"]?.ToString(),
                ApprovalTiming = r["approval_timing"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    // ========== MISSION MANAGEMENT METHODS ==========

    public async Task<List<Mission>> GetEmployeeMissionsAsync(int employeeId)
    {
        var list = new List<Mission>();
        var cmd = new SqlCommand(@"
            SELECT 
                m.mission_id,
                m.destination,
                m.start_date,
                m.end_date,
                m.status,
                m.employee_id,
                m.manager_id,
                e.full_name AS employee_name,
                mgr.full_name AS manager_name
            FROM Mission m
            LEFT JOIN Employee e ON m.employee_id = e.employee_id
            LEFT JOIN Employee mgr ON m.manager_id = mgr.employee_id
            WHERE m.employee_id = @employeeId
            ORDER BY m.start_date DESC", _conn);

        cmd.Parameters.AddWithValue("@employeeId", employeeId);
        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new Mission
            {
                MissionId = (int)r["mission_id"],
                Destination = r["destination"]?.ToString(),
                StartDate = (DateTime)r["start_date"],
                EndDate = (DateTime)r["end_date"],
                Status = r["status"]?.ToString(),
                EmployeeId = (int)r["employee_id"],
                ManagerId = r["manager_id"] != DBNull.Value ? (int?)r["manager_id"] : null,
                EmployeeName = r["employee_name"]?.ToString(),
                ManagerName = r["manager_name"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<List<Mission>> GetPendingMissionRequestsAsync(int managerId)
    {
        var list = new List<Mission>();
        var cmd = new SqlCommand(@"
            SELECT 
                m.mission_id,
                m.destination,
                m.start_date,
                m.end_date,
                m.status,
                m.employee_id,
                m.manager_id,
                e.full_name AS employee_name,
                mgr.full_name AS manager_name
            FROM Mission m
            LEFT JOIN Employee e ON m.employee_id = e.employee_id
            LEFT JOIN Employee mgr ON m.manager_id = mgr.employee_id
            WHERE m.manager_id = @managerId 
              AND m.status IN ('Pending', 'Requested')
            ORDER BY m.start_date ASC", _conn);

        cmd.Parameters.AddWithValue("@managerId", managerId);
        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new Mission
            {
                MissionId = (int)r["mission_id"],
                Destination = r["destination"]?.ToString(),
                StartDate = (DateTime)r["start_date"],
                EndDate = (DateTime)r["end_date"],
                Status = r["status"]?.ToString(),
                EmployeeId = (int)r["employee_id"],
                ManagerId = r["manager_id"] != DBNull.Value ? (int?)r["manager_id"] : null,
                EmployeeName = r["employee_name"]?.ToString(),
                ManagerName = r["manager_name"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<List<Mission>> GetAllMissionsAsync()
    {
        var list = new List<Mission>();
        var cmd = new SqlCommand(@"
            SELECT 
                m.mission_id,
                m.destination,
                m.start_date,
                m.end_date,
                m.status,
                m.employee_id,
                m.manager_id,
                e.full_name AS employee_name,
                mgr.full_name AS manager_name
            FROM Mission m
            LEFT JOIN Employee e ON m.employee_id = e.employee_id
            LEFT JOIN Employee mgr ON m.manager_id = mgr.employee_id
            ORDER BY m.start_date DESC", _conn);

        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new Mission
            {
                MissionId = (int)r["mission_id"],
                Destination = r["destination"]?.ToString(),
                StartDate = (DateTime)r["start_date"],
                EndDate = (DateTime)r["end_date"],
                Status = r["status"]?.ToString(),
                EmployeeId = (int)r["employee_id"],
                ManagerId = r["manager_id"] != DBNull.Value ? (int?)r["manager_id"] : null,
                EmployeeName = r["employee_name"]?.ToString(),
                ManagerName = r["manager_name"]?.ToString()
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<Mission?> GetMissionByIdAsync(int missionId)
    {
        var cmd = new SqlCommand(@"
            SELECT 
                m.mission_id,
                m.destination,
                m.start_date,
                m.end_date,
                m.status,
                m.employee_id,
                m.manager_id,
                e.full_name AS employee_name,
                mgr.full_name AS manager_name
            FROM Mission m
            LEFT JOIN Employee e ON m.employee_id = e.employee_id
            LEFT JOIN Employee mgr ON m.manager_id = mgr.employee_id
            WHERE m.mission_id = @missionId", _conn);

        cmd.Parameters.AddWithValue("@missionId", missionId);
        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        if (await r.ReadAsync())
        {
            var mission = new Mission
            {
                MissionId = (int)r["mission_id"],
                Destination = r["destination"]?.ToString(),
                StartDate = (DateTime)r["start_date"],
                EndDate = (DateTime)r["end_date"],
                Status = r["status"]?.ToString(),
                EmployeeId = (int)r["employee_id"],
                ManagerId = r["manager_id"] != DBNull.Value ? (int?)r["manager_id"] : null,
                EmployeeName = r["employee_name"]?.ToString(),
                ManagerName = r["manager_name"]?.ToString()
            };
            await _conn.CloseAsync();
            return mission;
        }

        await _conn.CloseAsync();
        return null;
    }

    public async Task<int> AssignMissionAsync(int employeeId, int managerId, string destination, DateTime startDate, DateTime endDate, string? description, string? purpose)
    {
        await _conn.OpenAsync();

        // Get next mission ID
        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(mission_id), 0) + 1 FROM Mission", _conn);
        int missionId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());

        var cmd = new SqlCommand(@"
            INSERT INTO Mission (mission_id, destination, start_date, end_date, status, employee_id, manager_id)
            VALUES (@missionId, @destination, @startDate, @endDate, 'Assigned', @employeeId, @managerId)", _conn);

        cmd.Parameters.AddWithValue("@missionId", missionId);
        cmd.Parameters.AddWithValue("@destination", destination);
        cmd.Parameters.AddWithValue("@startDate", startDate);
        cmd.Parameters.AddWithValue("@endDate", endDate);
        cmd.Parameters.AddWithValue("@employeeId", employeeId);
        cmd.Parameters.AddWithValue("@managerId", managerId);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();

        // Create notification for employee
        await CreateNotificationAsync(employeeId, 
            $"You have been assigned a new mission to {destination} from {startDate:yyyy-MM-dd} to {endDate:yyyy-MM-dd}",
            "Normal", "Mission");

        return missionId;
    }

    public async Task ApproveMissionRequestAsync(int missionId, int managerId)
    {
        var cmd = new SqlCommand(@"
            UPDATE Mission 
            SET status = 'Approved'
            WHERE mission_id = @missionId 
              AND manager_id = @managerId
              AND status IN ('Pending', 'Requested')", _conn);

        cmd.Parameters.AddWithValue("@missionId", missionId);
        cmd.Parameters.AddWithValue("@managerId", managerId);

        await _conn.OpenAsync();
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();

        // Get mission details for notification
        var mission = await GetMissionByIdAsync(missionId);
        if (mission != null)
        {
            await CreateNotificationAsync(mission.EmployeeId,
                $"Your mission request to {mission.Destination} has been approved",
                "Normal", "Mission");
        }
    }

    public async Task RejectMissionRequestAsync(int missionId, int managerId, string reason)
    {
        var cmd = new SqlCommand(@"
            UPDATE Mission 
            SET status = 'Rejected'
            WHERE mission_id = @missionId 
              AND manager_id = @managerId
              AND status IN ('Pending', 'Requested')", _conn);

        cmd.Parameters.AddWithValue("@missionId", missionId);
        cmd.Parameters.AddWithValue("@managerId", managerId);

        await _conn.OpenAsync();
        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();

        // Get mission details for notification
        var mission = await GetMissionByIdAsync(missionId);
        if (mission != null)
        {
            await CreateNotificationAsync(mission.EmployeeId,
                $"Your mission request to {mission.Destination} has been rejected. Reason: {reason}",
                "High", "Mission");
        }
    }

    // ========== COMPONENT 5: NOTIFICATIONS, ANALYTICS & HIERARCHY ==========

    public async Task SendTeamNotificationAsync(int managerId, string message, string urgency = "Normal")
    {
        await _conn.OpenAsync();

        // Get next notification ID
        var newIdCmd = new SqlCommand("SELECT ISNULL(MAX(notification_id), 0) + 1 FROM Notification", _conn);
        int notificationId = Convert.ToInt32(await newIdCmd.ExecuteScalarAsync());

        // Create notification
        var notifCmd = new SqlCommand(@"
            INSERT INTO Notification (notification_id, message_content, timestamp, urgency, read_status, notification_type)
            VALUES (@nid, @msg, GETDATE(), @urgency, 0, 'TeamMessage')", _conn);

        notifCmd.Parameters.AddWithValue("@nid", notificationId);
        notifCmd.Parameters.AddWithValue("@msg", message);
        notifCmd.Parameters.AddWithValue("@urgency", urgency);

        await notifCmd.ExecuteNonQueryAsync();

        // Send to all team members
        var linkCmd = new SqlCommand(@"
            INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
            SELECT employee_id, @nid, 'Delivered', GETDATE()
            FROM Employee
            WHERE manager_id = @managerId", _conn);

        linkCmd.Parameters.AddWithValue("@nid", notificationId);
        linkCmd.Parameters.AddWithValue("@managerId", managerId);

        await linkCmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();
    }

    public async Task<List<DepartmentStats>> GetDepartmentEmployeeStatsAsync()
    {
        var list = new List<DepartmentStats>();
        var cmd = new SqlCommand(@"
            SELECT 
                d.department_id,
                d.department_name,
                COUNT(e.employee_id) AS employee_count,
                COUNT(CASE WHEN e.is_active = 1 THEN 1 END) AS active_count,
                COUNT(CASE WHEN e.is_active = 0 THEN 1 END) AS inactive_count
            FROM Department d
            LEFT JOIN Employee e ON e.department_id = d.department_id
            GROUP BY d.department_id, d.department_name
            ORDER BY d.department_name", _conn);

        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            list.Add(new DepartmentStats
            {
                DepartmentId = (int)r["department_id"],
                DepartmentName = r["department_name"]?.ToString() ?? "",
                EmployeeCount = Convert.ToInt32(r["employee_count"]),
                ActiveCount = Convert.ToInt32(r["active_count"]),
                InactiveCount = Convert.ToInt32(r["inactive_count"])
            });
        }

        await _conn.CloseAsync();
        return list;
    }

    public async Task<ComplianceReport> GetComplianceReportAsync()
    {
        var report = new ComplianceReport();
        
        await _conn.OpenAsync();

        // Get employees with incomplete profiles
        var incompleteCmd = new SqlCommand(@"
            SELECT COUNT(*) FROM Employee WHERE profile_completion < 100", _conn);
        report.IncompleteProfiles = Convert.ToInt32(await incompleteCmd.ExecuteScalarAsync());

        // Get employees with expired contracts
        var expiredCmd = new SqlCommand(@"
            SELECT COUNT(*) 
            FROM Employee e
            INNER JOIN Contract c ON e.contract_id = c.contract_id
            WHERE c.end_date IS NOT NULL AND c.end_date < GETDATE()", _conn);
        report.ExpiredContracts = Convert.ToInt32(await expiredCmd.ExecuteScalarAsync());

        // Get employees without managers
        var noManagerCmd = new SqlCommand(@"
            SELECT COUNT(*) FROM Employee WHERE manager_id IS NULL AND is_active = 1", _conn);
        report.EmployeesWithoutManagers = Convert.ToInt32(await noManagerCmd.ExecuteScalarAsync());

        // Get employees without departments
        var noDeptCmd = new SqlCommand(@"
            SELECT COUNT(*) FROM Employee WHERE department_id IS NULL AND is_active = 1", _conn);
        report.EmployeesWithoutDepartments = Convert.ToInt32(await noDeptCmd.ExecuteScalarAsync());

        await _conn.CloseAsync();
        return report;
    }

    public async Task<DiversityReport> GetDiversityReportAsync()
    {
        var report = new DiversityReport();
        
        await _conn.OpenAsync();

        // Get gender distribution (if available in future)
        var totalCmd = new SqlCommand("SELECT COUNT(*) FROM Employee WHERE is_active = 1", _conn);
        report.TotalEmployees = Convert.ToInt32(await totalCmd.ExecuteScalarAsync());

        // Get department distribution
        var deptCmd = new SqlCommand(@"
            SELECT 
                d.department_name,
                COUNT(e.employee_id) AS count
            FROM Department d
            LEFT JOIN Employee e ON e.department_id = d.department_id AND e.is_active = 1
            GROUP BY d.department_name
            ORDER BY count DESC", _conn);

        report.DepartmentDistribution = new Dictionary<string, int>();
        using var r = await deptCmd.ExecuteReaderAsync();
        while (await r.ReadAsync())
        {
            var deptName = r["department_name"]?.ToString() ?? "Unassigned";
            var count = Convert.ToInt32(r["count"]);
            report.DepartmentDistribution[deptName] = count;
        }

        await _conn.CloseAsync();
        return report;
    }

    public async Task<List<HierarchyNode>> GetOrganizationalHierarchyAsync()
    {
        var nodes = new List<HierarchyNode>();
        var cmd = new SqlCommand(@"
            SELECT 
                e.employee_id,
                e.full_name,
                e.department_id,
                d.department_name,
                e.manager_id,
                mgr.full_name AS manager_name,
                e.is_active,
                (SELECT COUNT(*) FROM Employee WHERE manager_id = e.employee_id) AS team_size
            FROM Employee e
            LEFT JOIN Department d ON e.department_id = d.department_id
            LEFT JOIN Employee mgr ON e.manager_id = mgr.employee_id
            WHERE e.is_active = 1
            ORDER BY d.department_name, e.full_name", _conn);

        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        while (await r.ReadAsync())
        {
            nodes.Add(new HierarchyNode
            {
                EmployeeId = (int)r["employee_id"],
                EmployeeName = r["full_name"]?.ToString() ?? "",
                DepartmentId = r["department_id"] != DBNull.Value ? (int?)r["department_id"] : null,
                DepartmentName = r["department_name"]?.ToString(),
                ManagerId = r["manager_id"] != DBNull.Value ? (int?)r["manager_id"] : null,
                ManagerName = r["manager_name"]?.ToString(),
                IsActive = (bool)r["is_active"],
                TeamSize = Convert.ToInt32(r["team_size"])
            });
        }

        await _conn.CloseAsync();
        return nodes;
    }

    public async Task ReassignEmployeeHierarchyAsync(int employeeId, int? newDepartmentId, int? newManagerId)
    {
        await _conn.OpenAsync();

        var cmd = new SqlCommand(@"
            UPDATE Employee 
            SET department_id = @deptId, manager_id = @mgrId
            WHERE employee_id = @empId", _conn);

        cmd.Parameters.AddWithValue("@empId", employeeId);
        cmd.Parameters.AddWithValue("@deptId", newDepartmentId ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("@mgrId", newManagerId ?? (object)DBNull.Value);

        await cmd.ExecuteNonQueryAsync();
        await _conn.CloseAsync();

        // Create notification
        var emp = await GetEmployeeByIdAsync(employeeId);
        if (emp != null)
        {
            string message = "Your organizational assignment has been updated.";
            if (newDepartmentId.HasValue)
            {
                var dept = await GetDepartmentByIdAsync(newDepartmentId.Value);
                if (dept != null)
                    message += $" New department: {dept.DepartmentName}.";
            }
            if (newManagerId.HasValue)
            {
                var mgr = await GetEmployeeByIdAsync(newManagerId.Value);
                if (mgr != null)
                    message += $" New manager: {mgr.FullName}.";
            }
            await CreateNotificationAsync(employeeId, message, "Normal", "Hierarchy");
        }
    }

    public async Task<Department?> GetDepartmentByIdAsync(int departmentId)
    {
        var cmd = new SqlCommand("SELECT department_id, department_name, purpose FROM Department WHERE department_id = @id", _conn);
        cmd.Parameters.AddWithValue("@id", departmentId);

        await _conn.OpenAsync();
        using var r = await cmd.ExecuteReaderAsync();

        if (await r.ReadAsync())
        {
            var dept = new Department
            {
                DepartmentId = (int)r["department_id"],
                DepartmentName = r["department_name"]?.ToString() ?? "",
                Purpose = r["purpose"]?.ToString()
            };
            await _conn.CloseAsync();
            return dept;
        }

        await _conn.CloseAsync();
        return null;
    }

}

// ========== COMPONENT 5 MODELS ==========

public class DepartmentStats
{
    public int DepartmentId { get; set; }
    public string DepartmentName { get; set; } = "";
    public int EmployeeCount { get; set; }
    public int ActiveCount { get; set; }
    public int InactiveCount { get; set; }
}

public class ComplianceReport
{
    public int IncompleteProfiles { get; set; }
    public int ExpiredContracts { get; set; }
    public int EmployeesWithoutManagers { get; set; }
    public int EmployeesWithoutDepartments { get; set; }
}

public class DiversityReport
{
    public int TotalEmployees { get; set; }
    public Dictionary<string, int> DepartmentDistribution { get; set; } = new();
}

public class HierarchyNode
{
    public int EmployeeId { get; set; }
    public string EmployeeName { get; set; } = "";
    public int? DepartmentId { get; set; }
    public string? DepartmentName { get; set; }
    public int? ManagerId { get; set; }
    public string? ManagerName { get; set; }
    public bool IsActive { get; set; }
    public int TeamSize { get; set; }
}
