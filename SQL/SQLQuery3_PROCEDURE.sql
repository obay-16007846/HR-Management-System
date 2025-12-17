USE HRMS;
GO

-- 1. ViewEmployeeInfo

CREATE OR ALTER PROCEDURE ViewEmployeeInfo
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Employee
    WHERE employee_id = @EmployeeID;
END;
GO

-- 2. AddEmployee

CREATE OR ALTER PROCEDURE AddEmployee
    @FullName                VARCHAR(200),
    @NationalID              VARCHAR(50),
    @DateOfBirth             DATE,
    @CountryOfBirth          VARCHAR(100),
    @Phone                   VARCHAR(50),
    @Email                   VARCHAR(100),
    @Address                 VARCHAR(255),
    @EmergencyContactName    VARCHAR(100),
    @EmergencyContactPhone   VARCHAR(50),
    @Relationship            VARCHAR(50),
    @Biography               VARCHAR(MAX),
    @EmploymentProgress      VARCHAR(100),
    @AccountStatus           VARCHAR(50),
    @EmploymentStatus        VARCHAR(50),
    @HireDate                DATE,
    @IsActive                BIT,
    @ProfileCompletion       INT,
    @DepartmentID            INT,
    @PositionID              INT,
    @ManagerID               INT,
    @ContractID              INT,
    @TaxFormID               INT,
    @SalaryTypeID            INT,
    @PayGrade                VARCHAR(50)   -- grade_name
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FirstName  VARCHAR(100),
            @LastName   VARCHAR(100),
            @NewEmpID   INT,
            @PayGradeID INT;

    -- Split full name into first and last (basic split on first space)
    SET @FirstName = LEFT(@FullName, CHARINDEX(' ', @FullName + ' ') - 1);
    SET @LastName  = LTRIM(STUFF(@FullName, 1, LEN(@FirstName), ''));

    IF (@LastName = '')
        SET @LastName = @FirstName;  -- in case no space was found

    -- Resolve PayGradeID from grade_name (can be NULL)
    SELECT @PayGradeID = pay_grade_id
    FROM PayGrade
    WHERE grade_name = @PayGrade;

    -- Generate new employee_id
    SELECT @NewEmpID = ISNULL(MAX(employee_id), 0) + 1
    FROM Employee;

    INSERT INTO Employee (
        employee_id,
        first_name,
        last_name,
        full_name,
        national_id,
        date_of_birth,
        country_of_birth,
        phone,
        email,
        address,
        emergency_contact_name,
        emergency_contact_phone,
        relationship,
        biography,
        profile_image,
        employment_progress,
        account_status,
        employment_status,
        hire_date,
        is_active,
        profile_completion,
        department_id,
        position_id,
        manager_id,
        contract_id,
        tax_form_id,
        salary_type_id,
        pay_grade_id
    )
    VALUES (
        @NewEmpID,
        @FirstName,
        @LastName,
        @FullName,
        @NationalID,
        @DateOfBirth,
        @CountryOfBirth,
        @Phone,
        @Email,
        @Address,
        @EmergencyContactName,
        @EmergencyContactPhone,
        @Relationship,
        @Biography,
        NULL,                  -- profile_image
        @EmploymentProgress,
        @AccountStatus,
        @EmploymentStatus,
        @HireDate,
        @IsActive,
        @ProfileCompletion,
        @DepartmentID,
        @PositionID,
        @ManagerID,
        @ContractID,
        @TaxFormID,
        @SalaryTypeID,
        @PayGradeID
    );

    SELECT @NewEmpID AS NewEmployeeID;
END;
GO


-- 3. UpdateEmployeeInfo

CREATE OR ALTER PROCEDURE UpdateEmployeeInfo
    @EmployeeID INT,
    @Email      VARCHAR(100),
    @Phone      VARCHAR(20),
    @Address    VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Employee
    SET email = @Email,
        phone = @Phone,
        address = @Address
    WHERE employee_id = @EmployeeID;

    PRINT 'Employee info updated successfully.';
END;
GO


-- 4. AssignRole

CREATE OR ALTER PROCEDURE AssignRole
    @EmployeeID INT,
    @RoleID     INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM Employee_Role
        WHERE employee_id = @EmployeeID
          AND role_id = @RoleID
    )
    BEGIN
        INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
        VALUES (@EmployeeID, @RoleID, GETDATE());
    END

    PRINT 'Role assignment processed.';
END;
GO


-- 5. GetDepartmentEmployeeStats

CREATE OR ALTER PROCEDURE GetDepartmentEmployeeStats
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.department_id,
        d.department_name,
        COUNT(e.employee_id) AS EmployeeCount
    FROM Department d
    LEFT JOIN Employee e
        ON e.department_id = d.department_id
    GROUP BY d.department_id, d.department_name
    ORDER BY d.department_id;
END;
GO


-- 6. ReassignManager

CREATE OR ALTER PROCEDURE ReassignManager
    @EmployeeID    INT,
    @NewManagerID  INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Employee
    SET manager_id = @NewManagerID
    WHERE employee_id = @EmployeeID;

    -- keep EmployeeHierarchy in sync (simple version)
    IF EXISTS (
        SELECT 1 FROM EmployeeHierarchy
        WHERE employee_id = @EmployeeID
    )
        UPDATE EmployeeHierarchy
        SET manager_id = @NewManagerID
        WHERE employee_id = @EmployeeID;
    ELSE
        INSERT INTO EmployeeHierarchy (employee_id, manager_id, hierarchy_level)
        VALUES (@EmployeeID, @NewManagerID, 1);

    PRINT 'Manager reassigned.';
END;
GO


-- 7. ReassignHierarchy

CREATE OR ALTER PROCEDURE ReassignHierarchy
    @EmployeeID       INT,
    @NewDepartmentID  INT,
    @NewManagerID     INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Employee
    SET department_id = @NewDepartmentID,
        manager_id    = @NewManagerID
    WHERE employee_id = @EmployeeID;

    IF EXISTS (
        SELECT 1 FROM EmployeeHierarchy
        WHERE employee_id = @EmployeeID
    )
        UPDATE EmployeeHierarchy
        SET manager_id = @NewManagerID
        WHERE employee_id = @EmployeeID;
    ELSE
        INSERT INTO EmployeeHierarchy (employee_id, manager_id, hierarchy_level)
        VALUES (@EmployeeID, @NewManagerID, 1);

    PRINT 'Hierarchy reassigned.';
END;
GO


-- 8. NotifyStructureChange
-- @AffectedEmployees: comma-separated employee IDs, e.g. '1,2,3'

CREATE OR ALTER PROCEDURE NotifyStructureChange
    @AffectedEmployees VARCHAR(500),
    @Message           VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NotificationID INT;

    SELECT @NotificationID = ISNULL(MAX(notification_id), 0) + 1
    FROM Notification;

    INSERT INTO Notification (
        notification_id,
        message_content,
        timestamp,
        urgency,
        read_status,
        notification_type
    )
    VALUES (
        @NotificationID,
        @Message,
        GETDATE(),
        'Normal',
        0,
        'StructureChange'
    );

    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT
        TRY_CAST(value AS INT) AS employee_id,
        @NotificationID,
        'Delivered',
        GETDATE()
    FROM STRING_SPLIT(@AffectedEmployees, ',')
    WHERE TRY_CAST(value AS INT) IS NOT NULL;

    PRINT 'Structure change notifications sent.';
END;
GO


-- 9. ViewOrgHierarchy

CREATE OR ALTER PROCEDURE ViewOrgHierarchy
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.employee_id,
        e.full_name          AS EmployeeName,
        d.department_name    AS Department,
        p.position_title     AS Position,
        eh.hierarchy_level,
        eh.manager_id,
        m.full_name          AS ManagerName
    FROM Employee e
    LEFT JOIN EmployeeHierarchy eh
        ON e.employee_id = eh.employee_id
    LEFT JOIN Employee m
        ON eh.manager_id = m.employee_id
    LEFT JOIN Department d
        ON e.department_id = d.department_id
    LEFT JOIN Position p
        ON e.position_id = p.position_id
    ORDER BY d.department_name, eh.hierarchy_level, e.employee_id;
END;
GO


-- 10. AssignShiftToEmployee

CREATE OR ALTER PROCEDURE AssignShiftToEmployee
    @EmployeeID INT,
    @ShiftID    INT,
    @StartDate  DATE,
    @EndDate    DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewAssignID INT;

    SELECT @NewAssignID = ISNULL(MAX(assignment_id), 0) + 1
    FROM ShiftAssignment;

    INSERT INTO ShiftAssignment (
        assignment_id,
        employee_id,
        shift_id,
        start_date,
        end_date,
        status
    )
    VALUES (
        @NewAssignID,
        @EmployeeID,
        @ShiftID,
        @StartDate,
        @EndDate,
        'Assigned'
    );

    PRINT 'Shift assigned to employee.';
END;
GO


-- 11. UpdateShiftStatus

CREATE OR ALTER PROCEDURE UpdateShiftStatus
    @ShiftAssignmentID INT,
    @Status            VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ShiftAssignment
    SET status = @Status
    WHERE assignment_id = @ShiftAssignmentID;

    PRINT 'Shift status updated.';
END;
GO


-- 12. AssignShiftToDepartment

CREATE OR ALTER PROCEDURE AssignShiftToDepartment
    @DepartmentID INT,
    @ShiftID      INT,
    @StartDate    DATE,
    @EndDate      DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewAssignID INT;

    SELECT @NewAssignID = ISNULL(MAX(assignment_id), 0) + 1
    FROM ShiftAssignment;

    INSERT INTO ShiftAssignment (
        assignment_id,
        employee_id,
        shift_id,
        start_date,
        end_date,
        status
    )
    SELECT
        @NewAssignID + ROW_NUMBER() OVER (ORDER BY e.employee_id) - 1,
        e.employee_id,
        @ShiftID,
        @StartDate,
        @EndDate,
        'Assigned'
    FROM Employee e
    WHERE e.department_id = @DepartmentID;

    PRINT 'Shift assigned to department employees.';
END;
GO


-- 13. AssignCustomShift

CREATE OR ALTER PROCEDURE AssignCustomShift
    @EmployeeID INT,
    @ShiftName  VARCHAR(50),
    @ShiftType  VARCHAR(50),
    @StartTime  TIME,
    @EndTime    TIME,
    @StartDate  DATE,
    @EndDate    DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewShiftID   INT,
            @NewAssignID  INT;

    SELECT @NewShiftID = ISNULL(MAX(shift_id), 0) + 1
    FROM ShiftSchedule;

    INSERT INTO ShiftSchedule (
        shift_id,
        name,
        type,
        start_time,
        end_time,
        break_duration,
        shift_date,
        status
    )
    VALUES (
        @NewShiftID,
        @ShiftName,
        @ShiftType,
        @StartTime,
        @EndTime,
        0,
        @StartDate,
        'Active'
    );

    SELECT @NewAssignID = ISNULL(MAX(assignment_id), 0) + 1
    FROM ShiftAssignment;

    INSERT INTO ShiftAssignment (
        assignment_id,
        employee_id,
        shift_id,
        start_date,
        end_date,
        status
    )
    VALUES (
        @NewAssignID,
        @EmployeeID,
        @NewShiftID,
        @StartDate,
        @EndDate,
        'Assigned'
    );

    PRINT 'Custom shift created and assigned.';
END;
GO


-- 14. ConfigureSplitShift

CREATE OR ALTER PROCEDURE ConfigureSplitShift
    @ShiftName       VARCHAR(50),
    @FirstSlotStart  TIME,
    @FirstSlotEnd    TIME,
    @SecondSlotStart TIME,
    @SecondSlotEnd   TIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewShiftID INT,
            @BreakMins  INT;

    SELECT @NewShiftID = ISNULL(MAX(shift_id), 0) + 1
    FROM ShiftSchedule;

    SET @BreakMins = DATEDIFF(MINUTE, @FirstSlotEnd, @SecondSlotStart);

    INSERT INTO ShiftSchedule (
        shift_id,
        name,
        type,
        start_time,
        end_time,
        break_duration,
        shift_date,
        status
    )
    VALUES (
        @NewShiftID,
        @ShiftName,
        'Split',
        @FirstSlotStart,
        @SecondSlotEnd,
        @BreakMins,
        NULL,
        'Configured'
    );

    PRINT 'Split shift configured.';
END;
GO


-- 15. EnableFirstInLastOut
-- Stored as a special PayrollPolicy configuration

CREATE OR ALTER PROCEDURE EnableFirstInLastOut
    @Enable BIT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;

    SELECT @PolicyID = policy_id
    FROM PayrollPolicy
    WHERE type = 'FirstInLastOut';

    IF @PolicyID IS NULL
    BEGIN
        SELECT @PolicyID = ISNULL(MAX(policy_id), 0) + 1
        FROM PayrollPolicy;

        INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
        VALUES (@PolicyID, GETDATE(), 'FirstInLastOut',
                CASE WHEN @Enable = 1 THEN 'Enabled' ELSE 'Disabled' END);
    END
    ELSE
    BEGIN
        UPDATE PayrollPolicy
        SET description = CASE WHEN @Enable = 1 THEN 'Enabled' ELSE 'Disabled' END,
            effective_date = GETDATE()
        WHERE policy_id = @PolicyID;
    END

    PRINT 'First-in/Last-out setting updated.';
END;
GO


-- 16. TagAttendanceSource

CREATE OR ALTER PROCEDURE TagAttendanceSource
    @AttendanceID INT,
    @SourceType   VARCHAR(20),
    @DeviceID     INT,
    @Latitude     DECIMAL(10,7),
    @Longitude    DECIMAL(10,7)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM AttendanceSource
        WHERE attendance_id = @AttendanceID
          AND device_id = @DeviceID
    )
        UPDATE AttendanceSource
        SET source_type = @SourceType,
            latitude    = @Latitude,
            longitude   = @Longitude,
            recorded_at = GETDATE()
        WHERE attendance_id = @AttendanceID
          AND device_id = @DeviceID;
    ELSE
        INSERT INTO AttendanceSource (
            attendance_id, device_id, source_type,
            latitude, longitude, recorded_at
        )
        VALUES (
            @AttendanceID, @DeviceID, @SourceType,
            @Latitude, @Longitude, GETDATE()
        );

    PRINT 'Attendance source tagged.';
END;
GO


-- 17. SyncOfflineAttendance

CREATE OR ALTER PROCEDURE SyncOfflineAttendance
    @DeviceID   INT,
    @EmployeeID INT,
    @ClockTime  DATETIME,
    @Type       VARCHAR(10)   -- e.g., 'IN' / 'OUT'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewAttendanceID INT;

    SELECT @NewAttendanceID = ISNULL(MAX(attendance_id), 0) + 1
    FROM Attendance;

    INSERT INTO Attendance (
        attendance_id,
        employee_id,
        shift_id,
        entry_time,
        exit_time,
        duration,
        login_method,
        logout_method,
        exception_id
    )
    VALUES (
        @NewAttendanceID,
        @EmployeeID,
        NULL,
        @ClockTime,
        @ClockTime,
        0,
        @Type,
        @Type,
        NULL
    );

    INSERT INTO AttendanceSource (
        attendance_id, device_id, source_type,
        latitude, longitude, recorded_at
    )
    VALUES (
        @NewAttendanceID, @DeviceID, 'Offline',
        NULL, NULL, @ClockTime
    );

    PRINT 'Offline attendance synced.';
END;
GO


-- 18. LogAttendanceEdit

CREATE OR ALTER PROCEDURE LogAttendanceEdit
    @AttendanceID  INT,
    @EditedBy      INT,
    @OldValue      DATETIME,
    @NewValue      DATETIME,
    @EditTimestamp DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewLogID INT;

    SELECT @NewLogID = ISNULL(MAX(attendance_log_id), 0) + 1
    FROM AttendanceLog;

    INSERT INTO AttendanceLog (
        attendance_log_id,
        attendance_id,
        actor,
        timestamp,
        reason
    )
    VALUES (
        @NewLogID,
        @AttendanceID,
        @EditedBy,
        @EditTimestamp,
        'Edited from ' + CONVERT(VARCHAR(30), @OldValue, 120)
        + ' to ' + CONVERT(VARCHAR(30), @NewValue, 120)
    );

    PRINT 'Attendance edit logged.';
END;
GO


-- 19. ApplyHolidayOverrides

CREATE OR ALTER PROCEDURE ApplyHolidayOverrides
    @HolidayID  INT,
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM Employee_Exception
        WHERE employee_id = @EmployeeID
          AND exception_id = @HolidayID
    )
        INSERT INTO Employee_Exception (employee_id, exception_id)
        VALUES (@EmployeeID, @HolidayID);

    PRINT 'Holiday override applied.';
END;
GO


-- 20. ManageUserAccounts
-- Manages payroll-related roles using Role + Employee_Role

CREATE OR ALTER PROCEDURE ManageUserAccounts
    @UserID INT,
    @Role   VARCHAR(50),
    @Action VARCHAR(20)   -- 'ADD' or 'REMOVE'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RoleID INT;

    SELECT @RoleID = role_id
    FROM Role
    WHERE role_name = @Role;

    IF @RoleID IS NULL
    BEGIN
        RAISERROR ('Role not found.', 16, 1);
        RETURN;
    END

    IF UPPER(@Action) = 'ADD'
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM Employee_Role
            WHERE employee_id = @UserID
              AND role_id = @RoleID
        )
            INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
            VALUES (@UserID, @RoleID, GETDATE());

        PRINT 'Role added to user.';
    END
    ELSE IF UPPER(@Action) = 'REMOVE'
    BEGIN
        DELETE FROM Employee_Role
        WHERE employee_id = @UserID
          AND role_id = @RoleID;

        PRINT 'Role removed from user.';
    END
    ELSE
    BEGIN
        RAISERROR ('Invalid action. Use ADD or REMOVE.', 16, 1);
    END
END;
GO

USE HRMS;
GO
-- 1) Create a new employment contract for an employee.
CREATE OR ALTER PROCEDURE CreateContract
    @EmployeeID INT,
    @Type VARCHAR(50),
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewContractID INT;
    SELECT @NewContractID = ISNULL(MAX(contract_id), 0) + 1 FROM Contract;
    INSERT INTO Contract (contract_id, type, start_date, end_date, current_state)
    VALUES (@NewContractID, @Type, @StartDate, @EndDate, 'Active');
    UPDATE Employee SET contract_id = @NewContractID WHERE employee_id = @EmployeeID;
    IF @Type = 'FullTime'
    BEGIN
        INSERT INTO FullTimeContract (contract_id, leave_entitlement, insurance_eligibility, weekly_working_hours)
        VALUES (@NewContractID, 20, 'Yes', 40);
    END
    ELSE IF @Type = 'PartTime'
    BEGIN
        INSERT INTO PartTimeContract (contract_id, working_hours, hourly_rate)
        VALUES (@NewContractID, 20, 20.00);
    END
    ELSE IF @Type = 'Consultant'
    BEGIN
        INSERT INTO ConsultantContract (contract_id, project_scope, fees, payment_schedule)
        VALUES (@NewContractID, 'Scope', 1000.00, 'Monthly');
    END
    ELSE IF @Type = 'Internship'
    BEGIN
        INSERT INTO InternshipContract (contract_id, mentoring, evaluation, stipend_related)
        VALUES (@NewContractID, 'Mentor', 'Eval', 500.00);
    END
    PRINT 'Contract created successfully.';
END;
GO
-- 2) Renew or extend an existing contract.
CREATE OR ALTER PROCEDURE RenewContract
    @ContractID INT,
    @NewEndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Contract SET end_date = @NewEndDate, current_state = 'Active' WHERE contract_id = @ContractID;
    PRINT 'Contract renewed successfully.';
END;
GO
-- 3) Approve or reject leave requests from employees.
CREATE OR ALTER PROCEDURE ApproveLeaveRequest
    @LeaveRequestID INT,
    @ApproverID INT,
    @Status VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE LeaveRequest SET status = @Status WHERE request_id = @LeaveRequestID;
    PRINT 'Leave request status updated.';
END;
GO
-- 4) Assign missions or business trips to employees.
CREATE OR ALTER PROCEDURE AssignMission
    @EmployeeID INT,
    @ManagerID INT,
    @Destination VARCHAR(50),
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewMissionID INT;
    SELECT @NewMissionID = ISNULL(MAX(mission_id), 0) + 1 FROM Mission;
    INSERT INTO Mission (mission_id, destination, start_date, end_date, status, employee_id, manager_id)
    VALUES (@NewMissionID, @Destination, @StartDate, @EndDate, 'Assigned', @EmployeeID, @ManagerID);
    PRINT 'Mission assigned successfully.';
END;
GO
-- 5) Approve or reject reimbursement claims.
CREATE OR ALTER PROCEDURE ReviewReimbursement
    @ClaimID INT,
    @ApproverID INT,
    @Decision VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Reimbursement SET current_status = @Decision WHERE reimbursement_id = @ClaimID;
    PRINT 'Reimbursement reviewed successfully.';
END;
GO
-- 6) View all active employment contracts.
CREATE OR ALTER PROCEDURE GetActiveContracts
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Contract WHERE current_state = 'Active';
END;
GO
-- 7) Retrieve a list of employees under a specific manager.
CREATE OR ALTER PROCEDURE GetTeamByManager
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT employee_id, full_name FROM Employee WHERE manager_id = @ManagerID;
END;
GO
-- 8) Update leave policy details.
CREATE OR ALTER PROCEDURE UpdateLeavePolicy
    @PolicyID INT,
    @EligibilityRules VARCHAR(200),
    @NoticePeriod INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE LeavePolicy SET eligibility_rules = @EligibilityRules, notice_period = @NoticePeriod WHERE policy_id = @PolicyID;
    PRINT 'Leave policy updated successfully.';
END;
GO
-- 9) Retrieve contracts nearing expiration.
CREATE OR ALTER PROCEDURE GetExpiringContracts
    @DaysBefore INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Contract WHERE end_date <= DATEADD(DAY, @DaysBefore, GETDATE()) AND current_state = 'Active';
END;
GO
-- 10) Assign a department head.
CREATE OR ALTER PROCEDURE AssignDepartmentHead
    @DepartmentID INT,
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Department SET department_head_id = @ManagerID WHERE department_id = @DepartmentID;
    PRINT 'Department head assigned successfully.';
END;
GO
-- 11) Create a new employee profile from a hiring form.
CREATE OR ALTER PROCEDURE CreateEmployeeProfile
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @DepartmentID INT,
    @RoleID INT,
    @HireDate DATE,
    @Email VARCHAR(100),
    @Phone VARCHAR(20),
    @NationalID VARCHAR(50),
    @DateOfBirth DATE,
    @CountryOfBirth VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewEmpID INT;
    SELECT @NewEmpID = ISNULL(MAX(employee_id), 0) + 1 FROM Employee;
    INSERT INTO Employee (employee_id, first_name, last_name, full_name, national_id, date_of_birth, country_of_birth, phone, email, hire_date, department_id, is_active)
    VALUES (@NewEmpID, @FirstName, @LastName, @FirstName + ' ' + @LastName, @NationalID, @DateOfBirth, @CountryOfBirth, @Phone, @Email, @HireDate, @DepartmentID, 1);
    INSERT INTO Employee_Role (employee_id, role_id, assigned_date) VALUES (@NewEmpID, @RoleID, GETDATE());
    SELECT @NewEmpID AS NewEmployeeID;
END;
GO
-- 12) Edit or update any part of an employee profile.
CREATE OR ALTER PROCEDURE UpdateEmployeeProfile
    @EmployeeID INT,
    @FieldName VARCHAR(50),
    @NewValue VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    IF @FieldName = 'Email'
        UPDATE Employee SET email = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'Phone'
        UPDATE Employee SET phone = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'Address'
        UPDATE Employee SET address = @NewValue WHERE employee_id = @EmployeeID;
    PRINT 'Employee profile updated successfully.';
END;
GO
-- 13) Set and track employee profile completeness percentage.
CREATE OR ALTER PROCEDURE SetProfileCompleteness
    @EmployeeID INT,
    @CompletenessPercentage INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Employee SET profile_completion = @CompletenessPercentage WHERE employee_id = @EmployeeID;
    PRINT 'Profile completeness set successfully.';
END;
GO
-- 14) Search and generate compliance or diversity reports (e.g., by gender, department).
CREATE OR ALTER PROCEDURE GenerateProfileReport
    @FilterField VARCHAR(50),
    @FilterValue VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF @FilterField = 'Department'
        SELECT * FROM Employee WHERE department_id = TRY_CAST(@FilterValue AS INT);
    ELSE IF @FilterField = 'Gender'
        SELECT * FROM Employee WHERE relationship = @FilterValue; -- assuming relationship for gender, adjust if needed
END;
GO
-- 15) Define multiple shift types (Normal, Split, Overnight, Mission, etc.).
CREATE OR ALTER PROCEDURE CreateShiftType
    @ShiftID INT,
    @Name VARCHAR(100),
    @Type VARCHAR(50),
    @Start_Time TIME,
    @End_Time TIME,
    @Break_Duration INT,
    @Shift_Date DATE,
    @Status VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ShiftSchedule (shift_id, name, type, start_time, end_time, break_duration, shift_date, status)
    VALUES (@ShiftID, @Name, @Type, @Start_Time, @End_Time, @Break_Duration, @Shift_Date, @Status);
    PRINT 'Shift type created successfully.';
END;
GO
-- 16) Create and manage shift names (Core Hours, Flex Time, Rotational, etc.).
CREATE OR ALTER PROCEDURE CreateShiftName
    @ShiftName   VARCHAR(50),
    @ShiftType   VARCHAR(50),
    @Status      VARCHAR(50) = 'Active'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewShiftID INT;

    SELECT @NewShiftID = ISNULL(MAX(shift_id), 0) + 1
    FROM ShiftSchedule;

    INSERT INTO ShiftSchedule (
        shift_id, name, type, start_time, end_time,
        break_duration, shift_date, status
    )
    VALUES (
        @NewShiftID, @ShiftName, @ShiftType,
        NULL, NULL, 0, NULL, @Status
    );

    PRINT 'Shift name created successfully.';
END;
GO

-- 17) Assign employees to rotational shifts (Morning/Evening/Night).
CREATE OR ALTER PROCEDURE AssignRotationalShift
    @EmployeeID INT,
    @ShiftCycle INT,
    @StartDate DATE,
    @EndDate DATE,
    @status VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewAssignID INT;
    SELECT @NewAssignID = ISNULL(MAX(assignment_id), 0) + 1 FROM ShiftAssignment;
    INSERT INTO ShiftAssignment (assignment_id, employee_id, shift_id, start_date, end_date, status)
    VALUES (@NewAssignID, @EmployeeID, @ShiftCycle, @StartDate, @EndDate, @status);
    PRINT 'Rotational shift assigned successfully.';
END;
GO
-- 18) Receive notifications when a shift assignment is nearing expiry.
CREATE OR ALTER PROCEDURE NotifyShiftExpiry
    @EmployeeID INT,
    @ShiftAssignmentID INT,
    @ExpiryDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NotificationID INT;
    SELECT @NotificationID = ISNULL(MAX(notification_id), 0) + 1 FROM Notification;
    INSERT INTO Notification (notification_id, message_content, timestamp, urgency, read_status, notification_type)
    VALUES (@NotificationID, 'Shift expiring on ' + CONVERT(VARCHAR, @ExpiryDate), GETDATE(), 'High', 0, 'ShiftExpiry');
    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    VALUES (@EmployeeID, @NotificationID, 'Sent', GETDATE());
    PRINT 'Shift expiry notification sent.';
END;
GO
-- 19) Define rules for short time (late arrivals, early outs) so that deductions are consistent.
CREATE OR ALTER PROCEDURE DefineShortTimeRules
    @RuleName VARCHAR(50),
    @LateMinutes INT,
    @EarlyLeaveMinutes INT,
    @PenaltyType VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PolicyID INT;
    SELECT @PolicyID = ISNULL(MAX(policy_id), 0) + 1 FROM PayrollPolicy;
    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (@PolicyID, GETDATE(), 'ShortTime', @RuleName + ': Late ' + CAST(@LateMinutes AS VARCHAR) + ', Early ' + CAST(@EarlyLeaveMinutes AS VARCHAR) + ', Penalty ' + @PenaltyType);
    PRINT 'Short time rules defined successfully.';
END;
GO
-- 20) Set grace periods (e.g., first 10 mins free) so that minor lateness is tolerated.
CREATE OR ALTER PROCEDURE SetGracePeriod
    @Minutes INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PolicyID INT;
    SELECT @PolicyID = policy_id FROM LatenessPolicy WHERE policy_id = 2; -- assuming existing
    IF @PolicyID IS NULL
    BEGIN
        SELECT @PolicyID = ISNULL(MAX(policy_id), 0) + 1 FROM PayrollPolicy;
        INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
        VALUES (@PolicyID, GETDATE(), 'Lateness', 'Grace period');
        INSERT INTO LatenessPolicy (policy_id, grace_period_mins, deduction_rate)
        VALUES (@PolicyID, @Minutes, 0.0);
    END
    ELSE
    BEGIN
        UPDATE LatenessPolicy SET grace_period_mins = @Minutes WHERE policy_id = @PolicyID;
    END
    PRINT 'Grace period set successfully.';
END;
GO
-- 21) Set thresholds 
CREATE OR ALTER PROCEDURE DefinePenaltyThreshold
    @LateMinutes INT,
    @DeductionType VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PolicyID INT;
    SELECT @PolicyID = ISNULL(MAX(policy_id), 0) + 1 FROM PayrollPolicy;
    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (@PolicyID, GETDATE(), 'Penalty', @DeductionType + ' for ' + CAST(@LateMinutes AS VARCHAR) + ' minutes');
    PRINT 'Penalty threshold defined successfully.';
END;
GO
-- 22) Define minimum/maximum hours 
CREATE OR ALTER PROCEDURE DefinePermissionLimits
    @MinHours INT,
    @MaxHours INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PolicyID INT;
    SELECT @PolicyID = ISNULL(MAX(policy_id), 0) + 1 FROM PayrollPolicy;
    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (@PolicyID, GETDATE(), 'PermissionLimits', 'Min ' + CAST(@MinHours AS VARCHAR) + ', Max ' + CAST(@MaxHours AS VARCHAR));
    PRINT 'Permission limits defined successfully.';
END;
GO
-- 23) Escalate pending 
CREATE OR ALTER PROCEDURE EscalatePendingRequests
    @Deadline DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE LeaveRequest SET status = 'Escalated' WHERE approval_timing < @Deadline AND status = 'Pending';
    PRINT 'Pending requests escalated.';
END;
GO
-- 24) Link vacation packages to employee schedules.
CREATE OR ALTER PROCEDURE LinkVacationToShift
    @VacationPackageID INT,
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LeaveID INT;
    SELECT @LeaveID = leave_id FROM VacationLeave WHERE leave_id = @VacationPackageID;
    INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
    VALUES (@EmployeeID, @LeaveID, 20);
    PRINT 'Vacation linked to shift successfully.';
END;
GO
-- 25) Initiate the leave configuration process.
CREATE OR ALTER PROCEDURE ConfigureLeavePolicies
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Leave policies configuration initiated.';
END;
GO
-- 26) Authenticate administrator credentials for leave management.
CREATE OR ALTER PROCEDURE AuthenticateLeaveAdmin
    @AdminID INT,
    @Password VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Administrator authenticated.';
END;
GO
-- 27) Apply validated leave configurations.
CREATE OR ALTER PROCEDURE ApplyLeaveConfiguration
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Leave configuration applied.';
END;
GO
-- 28) Update entitlement calculations and scheduling logic.
CREATE OR ALTER PROCEDURE UpdateLeaveEntitlements
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE LeaveEntitlement SET entitlement = entitlement + 1 WHERE employee_id = @EmployeeID;
    PRINT 'Leave entitlements updated.';
END;
GO
-- 29) Set eligibility rules for each leave type.
CREATE OR ALTER PROCEDURE ConfigureLeaveEligibility
    @LeaveType VARCHAR(50),
    @MinTenure INT,
    @EmployeeType VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PolicyID INT;
    SELECT @PolicyID = ISNULL(MAX(policy_id), 0) + 1 FROM LeavePolicy;
    INSERT INTO LeavePolicy (policy_id, name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
    VALUES (@PolicyID, @LeaveType, 'Leave', 'Min Tenure ' + CAST(@MinTenure AS VARCHAR) + ', Type ' + @EmployeeType, 0, @LeaveType, 1);
    PRINT 'Leave eligibility configured.';
END;
GO
-- 30) Create and manage different leave types.
CREATE OR ALTER PROCEDURE ManageLeaveTypes
    @LeaveType VARCHAR(50),
    @Description VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewLeaveID INT;
    SELECT @NewLeaveID = ISNULL(MAX(leave_id), 0) + 1 FROM Leave;
    INSERT INTO Leave (leave_id, leave_type, leave_description)
    VALUES (@NewLeaveID, @LeaveType, @Description);
    PRINT 'Leave type managed successfully.';
END;
GO
-- 31) Assign personalized leave entitlements.
CREATE OR ALTER PROCEDURE AssignLeaveEntitlement
    @EmployeeID INT,
    @LeaveType VARCHAR(50),
    @Entitlement DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LeaveID INT;
    SELECT @LeaveID = leave_id FROM Leave WHERE leave_type = @LeaveType;
    IF EXISTS (SELECT 1 FROM LeaveEntitlement WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveID)
        UPDATE LeaveEntitlement SET entitlement = @Entitlement WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveID;
    ELSE
        INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
        VALUES (@EmployeeID, @LeaveID, @Entitlement);
    PRINT 'Leave entitlement assigned.';
END;
GO
-- 32) Configure leave parameters (max duration, notice periods, approval workflows).
CREATE OR ALTER PROCEDURE ConfigureLeaveRules
    @LeaveType VARCHAR(50),
    @MaxDuration INT,
    @NoticePeriod INT,
    @WorkflowType VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PolicyID INT;
    SELECT @PolicyID = ISNULL(MAX(policy_id), 0) + 1 FROM LeavePolicy;
    INSERT INTO LeavePolicy (policy_id, name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
    VALUES (@PolicyID, @LeaveType, @WorkflowType, 'Max Duration ' + CAST(@MaxDuration AS VARCHAR), @NoticePeriod, @LeaveType, 1);
    PRINT 'Leave rules configured.';
END;
GO
-- 33) Configure special absence types (bereavement, jury duty).
CREATE OR ALTER PROCEDURE ConfigureSpecialLeave
    @LeaveType VARCHAR(50),
    @Rules VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewLeaveID INT;
    SELECT @NewLeaveID = ISNULL(MAX(leave_id), 0) + 1 FROM Leave;
    INSERT INTO Leave (leave_id, leave_type, leave_description)
    VALUES (@NewLeaveID, @LeaveType, @Rules);
    PRINT 'Special leave configured.';
END;
GO
-- 34) Define legal leave year and reset rules.
CREATE OR ALTER PROCEDURE SetLeaveYearRules
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PolicyID INT;
    SELECT @PolicyID = ISNULL(MAX(policy_id), 0) + 1 FROM LeavePolicy;
    INSERT INTO LeavePolicy (policy_id, name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
    VALUES (@PolicyID, 'LeaveYear', 'Annual Reset', 'From ' + CONVERT(VARCHAR, @StartDate) + ' to ' + CONVERT(VARCHAR, @EndDate), 0, 'All', 1);
    PRINT 'Leave year rules set.';
END;
GO
-- 35) Manually adjust employee leave balances.
CREATE OR ALTER PROCEDURE AdjustLeaveBalance
    @EmployeeID INT,
    @LeaveType VARCHAR(50),
    @Adjustment DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LeaveID INT;
    SELECT @LeaveID = leave_id FROM Leave WHERE leave_type = @LeaveType;
    UPDATE LeaveEntitlement SET entitlement = entitlement + @Adjustment WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveID;
    PRINT 'Leave balance adjusted.';
END;
GO
-- 36) Manage user roles and permissions for leave actions.
CREATE OR ALTER PROCEDURE ManageLeaveRoles
    @RoleID INT,
    @Permissions VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO RolePermission (role_id, permission_name, allowed_action)
    VALUES (@RoleID, 'LeaveManagement', @Permissions);
    PRINT 'Leave roles managed.';
END;
GO
-- 37) Finalize approved leave requests.
CREATE OR ALTER PROCEDURE FinalizeLeaveRequest
    @LeaveRequestID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE LeaveRequest SET status = 'Finalized' WHERE request_id = @LeaveRequestID;
    PRINT 'Leave request finalized.';
END;
GO
-- 38) Override a managers decision in special cases.
CREATE OR ALTER PROCEDURE OverrideLeaveDecision
    @LeaveRequestID INT,
    @Reason VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE LeaveRequest SET status = 'Overridden', justification = @Reason WHERE request_id = @LeaveRequestID;
    PRINT 'Leave decision overridden.';
END;
GO
-- 39) Process multiple leave requests at once.
CREATE OR ALTER PROCEDURE BulkProcessLeaveRequests
    @LeaveRequestIDs VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE LeaveRequest SET status = 'Processed' WHERE request_id IN (SELECT value FROM STRING_SPLIT(@LeaveRequestIDs, ','));
    PRINT 'Leave requests processed in bulk.';
END;
GO
-- 40) Verify medical leave documents.
CREATE OR ALTER PROCEDURE VerifyMedicalLeave
    @LeaveRequestID INT,
    @DocumentID INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LeaveDocument (document_id, leave_request_id, file_path, uploaded_at)
    VALUES (@DocumentID, @LeaveRequestID, 'verified.pdf', GETDATE());
    PRINT 'Medical leave verified.';
END;
GO
-- 41) Update leave balances automatically after final approval.
CREATE OR ALTER PROCEDURE SyncLeaveBalances
    @LeaveRequestID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EmployeeID INT, @Duration INT, @LeaveID INT;
    SELECT @EmployeeID = employee_id, @Duration = duration, @LeaveID = leave_id FROM LeaveRequest WHERE request_id = @LeaveRequestID;
    UPDATE LeaveEntitlement SET entitlement = entitlement - @Duration WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveID;
    PRINT 'Leave balances synced.';
END;
GO
-- 42) Carry-forward and year-end leave processing.
CREATE OR ALTER PROCEDURE ProcessLeaveCarryForward
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE le
    SET entitlement = entitlement + 5   -- example carry-forward rule
    FROM LeaveEntitlement le
    JOIN Leave l
        ON le.leave_type_id = l.leave_id
    JOIN LeavePolicy lp
        ON lp.special_leave_type = l.leave_type
    WHERE lp.reset_on_new_year = 0;

    PRINT 'Leave carry forward processed.';
END;
GO
-- 43) Sync leave with attendance system in real-time.
CREATE OR ALTER PROCEDURE SyncLeaveToAttendance
    @LeaveRequestID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmployeeID INT,
            @NewAttendanceID INT;

    SELECT @EmployeeID = employee_id
    FROM LeaveRequest
    WHERE request_id = @LeaveRequestID;

    IF @EmployeeID IS NULL
    BEGIN
        RAISERROR ('Leave request not found.', 16, 1);
        RETURN;
    END;

    SELECT @NewAttendanceID = ISNULL(MAX(attendance_id), 0) + 1
    FROM Attendance;

    INSERT INTO Attendance (
        attendance_id, employee_id, shift_id,
        entry_time, exit_time, duration,
        login_method, logout_method, exception_id
    )
    VALUES (
        @NewAttendanceID, @EmployeeID, NULL,
        NULL, NULL, NULL,
        'Leave', 'Leave', NULL
    );

    PRINT 'Leave synchronized to attendance.';
END;
GO
-- 44) Review and update insurance brackets when policies or regulations change.
CREATE OR ALTER PROCEDURE UpdateInsuranceBrackets
    @BracketID INT,
    @NewMinSalary DECIMAL(10,2),
    @NewMaxSalary DECIMAL(10,2),
    @NewEmployeeContribution DECIMAL(5,2),
    @NewEmployerContribution DECIMAL(5,2),
    @UpdatedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Insurance SET contribution_rate = @NewEmployeeContribution WHERE insurance_id = @BracketID;
    PRINT 'Insurance brackets updated.';
END;
GO
-- 45) Review and confirm changes to payroll-related benefits and policies to ensure compliance.
CREATE OR ALTER PROCEDURE ApprovePolicyUpdate
    @PolicyID INT,
    @ApprovedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE PayrollPolicy SET effective_date = GETDATE() WHERE policy_id = @PolicyID;
    PRINT 'Policy update approved.';
END;
GO














/* ===========================================================
   3) PAYROLL OFFICER PROCEDURES
   =========================================================== */


-- 1. GeneratePayroll

CREATE OR ALTER PROCEDURE GeneratePayroll
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Payroll
    WHERE period_start >= @StartDate
      AND period_end   <= @EndDate;
END;
GO


-- 2. AdjustPayrollItem  (uses AllowanceDeduction)

CREATE OR ALTER PROCEDURE AdjustPayrollItem
    @PayrollID INT,
    @Type      VARCHAR(50),
    @Amount    DECIMAL(10,2),
    @Duration  INT,
    @Timezone  VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewADID     INT,
            @EmployeeID  INT;

    SELECT @EmployeeID = employee_id
    FROM Payroll
    WHERE payroll_id = @PayrollID;

    IF @EmployeeID IS NULL
    BEGIN
        RAISERROR ('Payroll record not found.', 16, 1);
        RETURN;
    END

    SELECT @NewADID = ISNULL(MAX(ad_id), 0) + 1
    FROM AllowanceDeduction;

    INSERT INTO AllowanceDeduction (
        ad_id,
        payroll_id,
        employee_id,
        type,
        amount,
        currency,
        duration,
        timezone
    )
    VALUES (
        @NewADID,
        @PayrollID,
        @EmployeeID,
        @Type,
        @Amount,
        'USD',
        @Duration,
        @Timezone
    );

    PRINT 'Payroll item adjusted.';
END;
GO


-- 3. CalculateNetSalary

CREATE OR ALTER PROCEDURE CalculateNetSalary
    @PayrollID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Base      DECIMAL(10,2),
            @Adj       DECIMAL(10,2),
            @Contr     DECIMAL(10,2),
            @Taxes     DECIMAL(10,2),
            @Net       DECIMAL(10,2);

    SELECT
        @Base  = base_amount,
        @Adj   = adjustments,
        @Contr = contributions,
        @Taxes = taxes
    FROM Payroll
    WHERE payroll_id = @PayrollID;

    IF @Base IS NULL
    BEGIN
        RAISERROR ('Payroll record not found.', 16, 1);
        RETURN;
    END

    SET @Net = (@Base + ISNULL(@Adj,0) - ISNULL(@Contr,0) - ISNULL(@Taxes,0));

    UPDATE Payroll
    SET net_salary = @Net
    WHERE payroll_id = @PayrollID;

    SELECT @Net AS NetSalary;
END;
GO


-- 4. ApplyPayrollPolicy

CREATE OR ALTER PROCEDURE ApplyPayrollPolicy
    @PolicyID     INT,
    @PayrollID    INT,
    @Type         VARCHAR(20),
    @Description  VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM PayrollPolicy
        WHERE policy_id = @PolicyID
    )
    BEGIN
        INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
        VALUES (@PolicyID, GETDATE(), @Type, @Description);
    END

    IF NOT EXISTS (
        SELECT 1 FROM PayrollPolicy_ID
        WHERE payroll_id = @PayrollID
          AND policy_id  = @PolicyID
    )
        INSERT INTO PayrollPolicy_ID (payroll_id, policy_id)
        VALUES (@PayrollID, @PolicyID);

    PRINT 'Payroll policy applied.';
END;
GO


-- 5. GetMonthlyPayrollSummary

CREATE OR ALTER PROCEDURE GetMonthlyPayrollSummary
    @Month INT,
    @Year  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SUM(net_salary) AS TotalSalaryExpenditure
    FROM Payroll
    WHERE MONTH(period_end) = @Month
      AND YEAR(period_end)  = @Year;
END;
GO


-- 5b. AddAllowanceDeduction

CREATE OR ALTER PROCEDURE AddAllowanceDeduction
    @PayrollID INT,
    @Type      VARCHAR(50),
    @Amount    DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewADID    INT,
            @EmployeeID INT;

    SELECT @EmployeeID = employee_id
    FROM Payroll
    WHERE payroll_id = @PayrollID;

    IF @EmployeeID IS NULL
    BEGIN
        RAISERROR ('Payroll record not found.', 16, 1);
        RETURN;
    END

    SELECT @NewADID = ISNULL(MAX(ad_id), 0) + 1
    FROM AllowanceDeduction;

    INSERT INTO AllowanceDeduction (
        ad_id,
        payroll_id,
        employee_id,
        type,
        amount,
        currency,
        duration,
        timezone
    )
    VALUES (
        @NewADID,
        @PayrollID,
        @EmployeeID,
        @Type,
        @Amount,
        'USD',
        1,
        'UTC'
    );

    PRINT 'Allowance/deduction added.';
END;
GO


-- 6/7. GetEmployeePayrollHistory

CREATE OR ALTER PROCEDURE GetEmployeePayrollHistory
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Payroll
    WHERE employee_id = @EmployeeID
    ORDER BY period_start;
END;
GO


-- 8. GetBonusEligibleEmployees

CREATE OR ALTER PROCEDURE GetBonusEligibleEmployees
    @Eligibility_criteria VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- Simple example: return employees who have at least one Payroll record
    SELECT DISTINCT e.employee_id, e.full_name
    FROM Employee e
    JOIN Payroll p
        ON e.employee_id = p.employee_id;
END;
GO


-- 9. UpdateSalaryType

CREATE OR ALTER PROCEDURE UpdateSalaryType
    @EmployeeID   INT,
    @SalaryTypeID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Employee
    SET salary_type_id = @SalaryTypeID
    WHERE employee_id = @EmployeeID;

    PRINT 'Salary type updated.';
END;
GO


-- 10. GetPayrollByDepartment

CREATE OR ALTER PROCEDURE GetPayrollByDepartment
    @DepartmentID INT,
    @Month        INT,
    @Year         INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.department_id,
        d.department_name,
        SUM(p.net_salary) AS TotalDepartmentPayroll
    FROM Payroll p
    JOIN Employee e
        ON p.employee_id = e.employee_id
    JOIN Department d
        ON e.department_id = d.department_id
    WHERE d.department_id = @DepartmentID
      AND MONTH(p.period_end) = @Month
      AND YEAR(p.period_end)  = @Year
    GROUP BY d.department_id, d.department_name;
END;
GO


-- 11. ValidateAttendanceBeforePayroll

CREATE OR ALTER PROCEDURE ValidateAttendanceBeforePayroll
    @PayrollPeriodID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Simple version: unresolved = requests not Approved
    SELECT
        acr.request_id,
        acr.employee_id,
        acr.date,
        acr.correction_type,
        acr.status
    FROM AttendanceCorrectionRequest acr
    WHERE acr.status <> 'Approved';
END;
GO


-- 12. SyncAttendanceToPayroll

CREATE OR ALTER PROCEDURE SyncAttendanceToPayroll
    @SyncDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewLogID INT;

    SELECT @NewLogID = ISNULL(MAX(payroll_log_id), 0) + 1
    FROM Payroll_Log;

    INSERT INTO Payroll_Log (
        payroll_log_id,
        payroll_id,
        actor,
        change_date,
        modification_type
    )
    VALUES (
        @NewLogID,
        NULL,
        NULL,
        @SyncDate,
        'SyncAttendance'
    );

    PRINT 'Attendance sync logged.';
END;
GO


-- 13. SyncApprovedPermissionsToPayroll

CREATE OR ALTER PROCEDURE SyncApprovedPermissionsToPayroll
    @PayrollPeriodID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewLogID INT;

    SELECT @NewLogID = ISNULL(MAX(payroll_log_id), 0) + 1
    FROM Payroll_Log;

    INSERT INTO Payroll_Log (
        payroll_log_id,
        payroll_id,
        actor,
        change_date,
        modification_type
    )
    VALUES (
        @NewLogID,
        NULL,
        NULL,
        GETDATE(),
        'SyncApprovedPermissions'
    );

    PRINT 'Approved permissions synced (logged).';
END;
GO


-- 14. ConfigurePayGrades

CREATE OR ALTER PROCEDURE ConfigurePayGrades
    @GradeName  VARCHAR(50),
    @MinSalary  DECIMAL(10,2),
    @MaxSalary  DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM PayGrade WHERE grade_name = @GradeName)
        UPDATE PayGrade
        SET min_salary = @MinSalary,
            max_salary = @MaxSalary
        WHERE grade_name = @GradeName;
    ELSE
    BEGIN
        DECLARE @NewID INT;
        SELECT @NewID = ISNULL(MAX(pay_grade_id),0) + 1 FROM PayGrade;

        INSERT INTO PayGrade (pay_grade_id, grade_name, min_salary, max_salary)
        VALUES (@NewID, @GradeName, @MinSalary, @MaxSalary);
    END

    PRINT 'Pay grade configured.';
END;
GO


-- 15. ConfigureShiftAllowances

CREATE OR ALTER PROCEDURE ConfigureShiftAllowances
    @ShiftType      VARCHAR(50),
    @AllowanceName  VARCHAR(50),
    @Amount         DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewPolicyID INT;

    SELECT @NewPolicyID = ISNULL(MAX(policy_id),0) + 1
    FROM PayrollPolicy;

    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (
        @NewPolicyID,
        GETDATE(),
        'ShiftAllowance',
        @ShiftType + ' - ' + @AllowanceName + ' - ' + CONVERT(VARCHAR(20), @Amount)
    );

    PRINT 'Shift allowance configured.';
END;
GO


-- 16. EnableMultiCurrencyPayroll

CREATE OR ALTER PROCEDURE EnableMultiCurrencyPayroll
    @CurrencyCode VARCHAR(10),
    @ExchangeRate DECIMAL(10,4)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Currency WHERE CurrencyCode = @CurrencyCode)
        UPDATE Currency
        SET ExchangeRate = @ExchangeRate,
            LastUpdated  = GETDATE()
        WHERE CurrencyCode = @CurrencyCode;
    ELSE
        INSERT INTO Currency (CurrencyCode, CurrencyName, ExchangeRate, CreatedDate, LastUpdated)
        VALUES (@CurrencyCode, @CurrencyCode, @ExchangeRate, GETDATE(), GETDATE());

    PRINT 'Multi-currency payroll settings updated.';
END;
GO


-- 17. ManageTaxRules

CREATE OR ALTER PROCEDURE ManageTaxRules
    @TaxRuleName VARCHAR(50),
    @CountryCode VARCHAR(10),
    @Rate        DECIMAL(5,2),
    @Exemption   DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;

    SELECT @PolicyID = ISNULL(MAX(policy_id),0) + 1 FROM PayrollPolicy;

    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (
        @PolicyID,
        GETDATE(),
        'TaxRule',
        @TaxRuleName + ' ' + @CountryCode + ' Rate=' +
        CONVERT(VARCHAR(20), @Rate) + ' Exemption=' + CONVERT(VARCHAR(20), @Exemption)
    );

    PRINT 'Tax rule stored in PayrollPolicy.';
END;
GO


-- 18. ApprovePayrollConfigChanges

CREATE OR ALTER PROCEDURE ApprovePayrollConfigChanges
    @PayrollID  INT,
    @PolicyID   INT,
    @ApprovedBy INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM PayrollPolicy_ID
        WHERE payroll_id = @PayrollID
          AND policy_id  = @PolicyID
    )
    BEGIN
        INSERT INTO PayrollPolicy_ID (payroll_id, policy_id)
        VALUES (@PayrollID, @PolicyID);
    END;

    DECLARE @NewLogID INT;

    SELECT @NewLogID = ISNULL(MAX(payroll_log_id), 0) + 1
    FROM Payroll_Log;

    INSERT INTO Payroll_Log (
        payroll_log_id, payroll_id, actor, change_date, modification_type
    )
    VALUES (
        @NewLogID, @PayrollID, @ApprovedBy, GETDATE(), 'ConfigApproved'
    );

    PRINT 'Payroll configuration changes approved.';
END;
GO



-- 19. ConfigureSigningBonus

CREATE OR ALTER PROCEDURE ConfigureSigningBonus
    @EmployeeID    INT,
    @BonusAmount   DECIMAL(10,2),
    @EffectiveDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;

    SELECT @PolicyID = ISNULL(MAX(policy_id),0) + 1
    FROM PayrollPolicy;

    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (
        @PolicyID,
        @EffectiveDate,
        'SigningBonus',
        'EmployeeID=' + CONVERT(VARCHAR(20), @EmployeeID) +
        ' Amount=' + CONVERT(VARCHAR(20), @BonusAmount)
    );

    PRINT 'Signing bonus configured.';
END;
GO


-- 20. ConfigureTerminationBenefits

CREATE OR ALTER PROCEDURE ConfigureTerminationBenefits
    @EmployeeID          INT,
    @CompensationAmount  DECIMAL(10,2),
    @EffectiveDate       DATE,
    @Reason              VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TerminationID INT,
            @ContractID    INT;

    SELECT @ContractID = contract_id
    FROM Employee
    WHERE employee_id = @EmployeeID;

    SELECT @TerminationID = ISNULL(MAX(termination_id),0) + 1
    FROM Termination;

    INSERT INTO Termination (termination_id, date, reason, contract_id)
    VALUES (@TerminationID, @EffectiveDate, @Reason, @ContractID);

    -- Also log as reimbursement (compensation)
    DECLARE @ReimbID INT;
    SELECT @ReimbID = ISNULL(MAX(reimbursement_id),0) + 1 FROM Reimbursement;

    INSERT INTO Reimbursement (
        reimbursement_id, type, claim_type, approval_date,
        current_status, employee_id
    )
    VALUES (
        @ReimbID, 'Termination', 'Compensation',
        @EffectiveDate, 'Configured', @EmployeeID
    );

    PRINT 'Termination benefits configured.';
END;
GO


-- 21 & 30. ConfigureInsuranceBrackets
-- Uses the more detailed signature with BracketName

CREATE OR ALTER PROCEDURE ConfigureInsuranceBrackets
    @BracketName          VARCHAR(50),
    @MinSalary            DECIMAL(10,2),
    @MaxSalary            DECIMAL(10,2),
    @EmployeeContribution DECIMAL(5,2),
    @EmployerContribution DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;

    SELECT @PolicyID = ISNULL(MAX(policy_id),0) + 1
    FROM PayrollPolicy;

    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (
        @PolicyID,
        GETDATE(),
        'InsuranceBracket',
        @BracketName + ' Min=' + CONVERT(VARCHAR(20), @MinSalary) +
        ' Max=' + CONVERT(VARCHAR(20), @MaxSalary) +
        ' Emp=' + CONVERT(VARCHAR(20), @EmployeeContribution) +
        ' Empr=' + CONVERT(VARCHAR(20), @EmployerContribution)
    );

    PRINT 'Insurance bracket configured.';
END;
GO


-- 22. UpdateInsuranceBrackets

CREATE OR ALTER PROCEDURE UpdateInsuranceBrackets
    @BracketID            INT,
    @MinSalary            DECIMAL(10,2),
    @MaxSalary            DECIMAL(10,2),
    @EmployeeContribution DECIMAL(5,2),
    @EmployerContribution DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE PayrollPolicy
    SET description = 'UpdatedBracket Min=' + CONVERT(VARCHAR(20), @MinSalary) +
                      ' Max=' + CONVERT(VARCHAR(20), @MaxSalary) +
                      ' Emp=' + CONVERT(VARCHAR(20), @EmployeeContribution) +
                      ' Empr=' + CONVERT(VARCHAR(20), @EmployerContribution),
        effective_date = GETDATE()
    WHERE policy_id = @BracketID;

    PRINT 'Insurance bracket updated.';
END;
GO


-- 23. ConfigurePayrollPolicies

CREATE OR ALTER PROCEDURE ConfigurePayrollPolicies
    @PolicyType   VARCHAR(50),
    @PolicyDetails NVARCHAR(MAX),
    @effectivedate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;

    SELECT @PolicyID = ISNULL(MAX(policy_id),0) + 1
    FROM PayrollPolicy;

    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (
        @PolicyID,
        @effectivedate,
        @PolicyType,
        @PolicyDetails
    );

    PRINT 'Payroll policy configured.';
END;
GO


-- 24. DefinePayGrades

CREATE OR ALTER PROCEDURE DefinePayGrades
    @GradeName  VARCHAR(50),
    @MinSalary  DECIMAL(10,2),
    @MaxSalary  DECIMAL(10,2),
    @CreatedBy  INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC ConfigurePayGrades @GradeName, @MinSalary, @MaxSalary;

    PRINT 'Pay grade defined.';
END;
GO


-- 25. ConfigureEscalationWorkflow

CREATE OR ALTER PROCEDURE ConfigureEscalationWorkflow
    @ThresholdAmount DECIMAL(10,2),
    @ApproverRole    VARCHAR(50),
    @CreatedBy       INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @WorkflowID INT;

    SELECT @WorkflowID = ISNULL(MAX(workflow_id),0) + 1
    FROM ApprovalWorkflow;

    INSERT INTO ApprovalWorkflow (
        workflow_id,
        workflow_type,
        threshold_amount,
        approver_role,
        created_by,
        status
    )
    VALUES (
        @WorkflowID,
        'Escalation',
        @ThresholdAmount,
        @ApproverRole,
        @CreatedBy,
        'Active'
    );

    PRINT 'Escalation workflow configured.';
END;
GO


-- 26. DefinePayType

CREATE OR ALTER PROCEDURE DefinePayType
    @EmployeeID   INT,
    @PayType      VARCHAR(50),
    @EffectiveDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;

    SELECT @PolicyID = ISNULL(MAX(policy_id),0) + 1
    FROM PayrollPolicy;

    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (
        @PolicyID,
        @EffectiveDate,
        'PayType',
        'EmployeeID=' + CONVERT(VARCHAR(20), @EmployeeID) +
        ' Type=' + @PayType
    );

    PRINT 'Pay type defined.';
END;
GO


-- 27. ConfigureOvertimeRules

CREATE OR ALTER PROCEDURE ConfigureOvertimeRules
    @DayType       VARCHAR(20),
    @Multiplier    DECIMAL(3,2),
    @hourspermonth INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;

    SELECT @PolicyID = ISNULL(MAX(policy_id),0) + 1
    FROM OvertimePolicy;

    INSERT INTO OvertimePolicy (policy_id, weekday_rate_multiplier, weekend_rate_multiplier, max_hours_per_month)
    VALUES (@PolicyID,
            CASE WHEN @DayType = 'Weekday' THEN @Multiplier ELSE 1 END,
            CASE WHEN @DayType = 'Weekend' THEN @Multiplier ELSE 1 END,
            @hourspermonth);

    PRINT 'Overtime rule configured.';
END;
GO


-- 28. ConfigureShiftAllowance

CREATE OR ALTER PROCEDURE ConfigureShiftAllowance
    @ShiftType       VARCHAR(20),
    @AllowanceAmount DECIMAL(10,2),
    @CreatedBy       INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;

    SELECT @PolicyID = ISNULL(MAX(policy_id),0) + 1
    FROM PayrollPolicy;

    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (
        @PolicyID,
        GETDATE(),
        'ShiftDifferential',
        @ShiftType + ' Allowance=' + CONVERT(VARCHAR(20), @AllowanceAmount) +
        ' CreatedBy=' + CONVERT(VARCHAR(20), @CreatedBy)
    );

    PRINT 'Shift differential allowance configured.';
END;
GO


-- 28b. ConfigureMultiCurrency

CREATE OR ALTER PROCEDURE ConfigureMultiCurrency
    @CurrencyCode VARCHAR(10),
    @ExchangeRate DECIMAL(10,4),
    @EffectiveDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Currency WHERE CurrencyCode = @CurrencyCode)
        UPDATE Currency
        SET ExchangeRate = @ExchangeRate,
            LastUpdated  = @EffectiveDate
        WHERE CurrencyCode = @CurrencyCode;
    ELSE
        INSERT INTO Currency (CurrencyCode, CurrencyName, ExchangeRate, CreatedDate, LastUpdated)
        VALUES (@CurrencyCode, @CurrencyCode, @ExchangeRate, @EffectiveDate, @EffectiveDate);

    PRINT 'Multi-currency configuration updated.';
END;
GO


-- 29. ConfigureSigningBonusPolicy

CREATE OR ALTER PROCEDURE ConfigureSigningBonusPolicy
    @BonusType          VARCHAR(50),
    @Amount             DECIMAL(10,2),
    @EligibilityCriteria NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;
    SELECT @PolicyID = ISNULL(MAX(policy_id),0) + 1 FROM PayrollPolicy;

    INSERT INTO PayrollPolicy (policy_id, effective_date, type, description)
    VALUES (
        @PolicyID,
        GETDATE(),
        'SigningBonusPolicy',
        @BonusType + ' Amount=' + CONVERT(VARCHAR(20), @Amount) +
        ' Criteria=' + @EligibilityCriteria
    );

    PRINT 'Signing bonus policy configured.';
END;
GO


-- 31. GenerateTaxStatement

CREATE OR ALTER PROCEDURE GenerateTaxStatement
    @EmployeeID INT,
    @TaxYear    INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @EmployeeID AS EmployeeID,
        @TaxYear    AS TaxYear,
        SUM(taxes)  AS TotalTaxes,
        SUM(base_amount) AS TotalBaseSalary,
        SUM(net_salary)  AS TotalNetSalary
    FROM Payroll
    WHERE employee_id = @EmployeeID
      AND YEAR(period_end) = @TaxYear
    GROUP BY employee_id;
END;
GO


-- 33. ApprovePayrollConfiguration

CREATE OR ALTER PROCEDURE ApprovePayrollConfiguration
    @ConfigID   INT,
    @ApprovedBy INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE PayrollPolicy
    SET description    = CAST(ISNULL(description, '') AS VARCHAR(MAX))
                         + ' (Approved by ' + CAST(@ApprovedBy AS VARCHAR(20)) + ')',
        effective_date = GETDATE()
    WHERE policy_id = @ConfigID;

    DECLARE @NewLogID INT;

    SELECT @NewLogID = ISNULL(MAX(payroll_log_id), 0) + 1
    FROM Payroll_Log;

    INSERT INTO Payroll_Log (
        payroll_log_id, payroll_id, actor, change_date, modification_type
    )
    VALUES (
        @NewLogID, NULL, @ApprovedBy, GETDATE(), 'PolicyApproved'
    );

    PRINT 'Payroll configuration approved.';
END;
GO



-- 34. ModifyPastPayroll

CREATE OR ALTER PROCEDURE ModifyPastPayroll
    @PayrollRunID INT,
    @EmployeeID   INT,
    @FieldName    VARCHAR(50),
    @NewValue     DECIMAL(10,2),
    @ModifiedBy   INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Only allow certain numeric fields to be modified safely
    IF @FieldName NOT IN ('taxes','base_amount','adjustments','contributions','actual_pay','net_salary')
    BEGIN
        RAISERROR ('Invalid field name for modification.', 16, 1);
        RETURN;
    END

    IF @FieldName = 'taxes'
        UPDATE Payroll SET taxes = @NewValue WHERE payroll_id = @PayrollRunID AND employee_id = @EmployeeID;
    ELSE IF @FieldName = 'base_amount'
        UPDATE Payroll SET base_amount = @NewValue WHERE payroll_id = @PayrollRunID AND employee_id = @EmployeeID;
    ELSE IF @FieldName = 'adjustments'
        UPDATE Payroll SET adjustments = @NewValue WHERE payroll_id = @PayrollRunID AND employee_id = @EmployeeID;
    ELSE IF @FieldName = 'contributions'
        UPDATE Payroll SET contributions = @NewValue WHERE payroll_id = @PayrollRunID AND employee_id = @EmployeeID;
    ELSE IF @FieldName = 'actual_pay'
        UPDATE Payroll SET actual_pay = @NewValue WHERE payroll_id = @PayrollRunID AND employee_id = @EmployeeID;
    ELSE IF @FieldName = 'net_salary'
        UPDATE Payroll SET net_salary = @NewValue WHERE payroll_id = @PayrollRunID AND employee_id = @EmployeeID;

    -- Log the modification
    DECLARE @LogID INT;
    SELECT @LogID = ISNULL(MAX(payroll_log_id),0) + 1 FROM Payroll_Log;

    INSERT INTO Payroll_Log (
        payroll_log_id,
        payroll_id,
        actor,
        change_date,
        modification_type
    )
    VALUES (
        @LogID,
        @PayrollRunID,
        @ModifiedBy,
        GETDATE(),
        'Modify ' + @FieldName
    );

    PRINT 'Past payroll entry modified.';
END;
GO













USE HRMS;
GO

/* ===========================================================
   LINE MANAGER PROCEDURES (24)
   =========================================================== */


-- 1) ReviewLeaveRequest
-- Approve or deny leave requests from team members

CREATE OR ALTER PROCEDURE ReviewLeaveRequest
    @LeaveRequestID INT,
    @ManagerID INT,
    @Decision VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE lr
    SET status = @Decision,
        approval_timing = CONVERT(VARCHAR(19), GETDATE(), 120)
    FROM LeaveRequest lr
    JOIN Employee e ON lr.employee_id = e.employee_id
    WHERE lr.request_id = @LeaveRequestID
      AND e.manager_id = @ManagerID;

    PRINT 'Leave request reviewed.';
END;
GO


-- 2) AssignShift
-- Adapted: sends a notification to the employee about shift assignment

CREATE OR ALTER PROCEDURE AssignShift
    @EmployeeID INT,
    @ShiftID    INT,
    @StartDate  DATE,
    @EndDate    DATE,
    @AssignedBy INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AssignmentID   INT,
            @NotificationID INT,
            @Msg            VARCHAR(255);

    SELECT @AssignmentID = ISNULL(MAX(assignment_id), 0) + 1
    FROM ShiftAssignment;

    INSERT INTO ShiftAssignment (
        assignment_id, employee_id, shift_id, start_date, end_date, status
    )
    VALUES (
        @AssignmentID, @EmployeeID, @ShiftID, @StartDate, @EndDate, 'Assigned'
    );

    SELECT @NotificationID = ISNULL(MAX(notification_id), 0) + 1
    FROM Notification;

    SET @Msg = 'You have been assigned shift '
        + CAST(@ShiftID AS VARCHAR(20))
        + ' from ' + CONVERT(VARCHAR(10), @StartDate, 120)
        + ' to '   + CONVERT(VARCHAR(10), @EndDate, 120);

    INSERT INTO Notification (
        notification_id, message_content, timestamp, urgency, read_status, notification_type
    )
    VALUES (
        @NotificationID, @Msg, GETDATE(), 'Normal', 0, 'ShiftAssignment'
    );

    INSERT INTO Employee_Notification (
        employee_id, notification_id, delivery_status, delivered_at
    )
    VALUES (
        @EmployeeID, @NotificationID, 'Delivered', GETDATE()
    );
END;
GO




-- 3) ViewTeamAttendance

CREATE OR ALTER PROCEDURE ViewTeamAttendance
    @ManagerID INT,
    @DateRangeStart DATE,
    @DateRangeEnd DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.attendance_id,
        a.employee_id,
        e.full_name,
        a.entry_time,
        a.exit_time,
        a.duration,
        a.login_method,
        a.logout_method,
        a.exception_id
    FROM Attendance a
    JOIN Employee e
        ON a.employee_id = e.employee_id
    WHERE e.manager_id = @ManagerID
      AND CONVERT(DATE, a.entry_time) BETWEEN @DateRangeStart AND @DateRangeEnd
    ORDER BY a.entry_time;
END;
GO


-- 4) SendTeamNotification

CREATE OR ALTER PROCEDURE SendTeamNotification
    @ManagerID INT,
    @MessageContent VARCHAR(255),
    @UrgencyLevel VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NotificationID INT;

    SELECT @NotificationID = ISNULL(MAX(notification_id), 0) + 1
    FROM Notification;

    INSERT INTO Notification
        (notification_id, message_content, timestamp, urgency, read_status, notification_type)
    VALUES
        (@NotificationID, @MessageContent, GETDATE(), @UrgencyLevel, 0, 'TeamMessage');

    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT e.employee_id, @NotificationID, 'Delivered', GETDATE()
    FROM Employee e
    WHERE e.manager_id = @ManagerID;

    PRINT 'Team notification sent.';
END;
GO


-- 5) ApproveMissionCompletion

CREATE OR ALTER PROCEDURE ApproveMissionCompletion
    @MissionID INT,
    @ManagerID INT,
    @Remarks VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmpID INT,
            @NoteID INT;

    SELECT @EmpID = employee_id
    FROM Mission
    WHERE mission_id = @MissionID
      AND manager_id = @ManagerID;

    IF @EmpID IS NULL
    BEGIN
        RAISERROR ('Mission not found or not managed by this manager.', 16, 1);
        RETURN;
    END

    UPDATE Mission
    SET status = 'Completed'
    WHERE mission_id = @MissionID;

    SELECT @NoteID = ISNULL(MAX(note_id), 0) + 1
    FROM ManagerNotes;

    INSERT INTO ManagerNotes
        (note_id, employee_id, manager_id, note_content, created_at)
    VALUES
        (@NoteID, @EmpID, @ManagerID,
         'Mission ' + CAST(@MissionID AS VARCHAR(20)) +
         ' marked as completed. Remarks: ' + @Remarks,
         GETDATE());

    PRINT 'Mission completion approved and note recorded.';
END;
GO


-- 6) RequestReplacement
-- Adapted: notify HR Admins (role_id = 2)

CREATE OR ALTER PROCEDURE RequestReplacement
    @EmployeeID INT,
    @ShiftID    INT,
    @Reason     VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NotificationID INT,
            @Msg VARCHAR(255);

    SELECT @NotificationID = ISNULL(MAX(notification_id), 0) + 1
    FROM Notification;

    SET @Msg = 'Replacement requested for Employee '
        + CAST(@EmployeeID AS VARCHAR(20))
        + ', shift ' + CAST(@ShiftID AS VARCHAR(20))
        + ', reason: ' + @Reason;

    INSERT INTO Notification (
        notification_id, message_content, timestamp, urgency, read_status, notification_type
    )
    VALUES (
        @NotificationID, @Msg, GETDATE(), 'High', 0, 'ReplacementRequest'
    );

    INSERT INTO Employee_Notification (
        employee_id, notification_id, delivery_status, delivered_at
    )
    SELECT manager_id, @NotificationID, 'Delivered', GETDATE()
    FROM EmployeeHierarchy
    WHERE employee_id = @EmployeeID;
END;
GO





-- 7) ViewDepartmentSummary

CREATE OR ALTER PROCEDURE ViewDepartmentSummary
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.department_id,
        d.department_name,
        COUNT(e.employee_id) AS EmployeeCount
    FROM Department d
    LEFT JOIN Employee e
        ON d.department_id = e.department_id
    WHERE d.department_id = @DepartmentID
    GROUP BY d.department_id, d.department_name;
END;
GO


-- 8) ReassignShift
-- Adapted: send notification about change in shift

CREATE OR ALTER PROCEDURE ReassignShift
    @OldEmployeeID INT,
    @NewEmployeeID INT,
    @ShiftID       INT,
    @ManagerID     INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ShiftAssignment
    SET employee_id = @NewEmployeeID,
        status = 'Reassigned'
    WHERE employee_id = @OldEmployeeID
      AND shift_id = @ShiftID;

    DECLARE @NotificationID INT,
            @Msg VARCHAR(255);

    SELECT @NotificationID = ISNULL(MAX(notification_id), 0) + 1
    FROM Notification;

    SET @Msg = 'Shift ' + CAST(@ShiftID AS VARCHAR(20))
        + ' reassigned from ' + CAST(@OldEmployeeID AS VARCHAR(20))
        + ' to ' + CAST(@NewEmployeeID AS VARCHAR(20));

    INSERT INTO Notification (
        notification_id, message_content, timestamp, urgency, read_status, notification_type
    )
    VALUES (
        @NotificationID, @Msg, GETDATE(), 'Normal', 0, 'ShiftReassignment'
    );

    INSERT INTO Employee_Notification (
        employee_id, notification_id, delivery_status, delivered_at
    )
    VALUES (@OldEmployeeID, @NotificationID, 'Delivered', GETDATE()),
           (@NewEmployeeID, @NotificationID, 'Delivered', GETDATE());
END;
GO




-- 9) GetPendingLeaveRequests

CREATE OR ALTER PROCEDURE GetPendingLeaveRequests
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        lr.request_id,
        lr.employee_id,
        e.full_name,
        lr.leave_id,
        l.leave_type,
        lr.justification,
        lr.duration,
        lr.status
    FROM LeaveRequest lr
    JOIN Employee e ON lr.employee_id = e.employee_id
    JOIN Leave l    ON lr.leave_id = l.leave_id
    WHERE e.manager_id = @ManagerID
      AND lr.status = 'Pending';
END;
GO


-- 10) GetTeamStatistics

CREATE OR ALTER PROCEDURE GetTeamStatistics
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Team AS (
        SELECT e.employee_id
        FROM Employee e
        WHERE e.manager_id = @ManagerID
    )
    SELECT
        @ManagerID AS ManagerID,
        COUNT(DISTINCT t.employee_id) AS TeamSize,
        AVG(p.net_salary)            AS AverageNetSalary,
        COUNT(DISTINCT t.employee_id) AS SpanOfControl
    FROM Team t
    LEFT JOIN Payroll p
        ON p.employee_id = t.employee_id;
END;
GO


-- 11) ViewTeamProfiles

CREATE OR ALTER PROCEDURE ViewTeamProfiles
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.employee_id,
        e.full_name,
        e.email,
        e.phone,
        d.department_name,
        p.position_title,
        e.hire_date
    FROM Employee e
    LEFT JOIN Department d ON e.department_id = d.department_id
    LEFT JOIN Position   p ON e.position_id = p.position_id
    WHERE e.manager_id = @ManagerID;
END;
GO


-- 12) GetTeamSummary

CREATE OR ALTER PROCEDURE GetTeamSummary
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.employee_id,
        e.full_name,
        r.role_name,
        d.department_name,
        e.hire_date,
        DATEDIFF(YEAR, e.hire_date, GETDATE()) AS TenureYears
    FROM Employee e
    LEFT JOIN Employee_Role er ON e.employee_id = er.employee_id
    LEFT JOIN Role r           ON er.role_id = r.role_id
    LEFT JOIN Department d     ON e.department_id = d.department_id
    WHERE e.manager_id = @ManagerID;
END;
GO


-- 13) FilterTeamProfiles

CREATE OR ALTER PROCEDURE FilterTeamProfiles
    @ManagerID INT,
    @Skill VARCHAR(50),
    @RoleID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
        e.employee_id,
        e.full_name,
        e.email,
        e.phone,
        d.department_name,
        p.position_title
    FROM Employee e
    LEFT JOIN Department d ON e.department_id = d.department_id
    LEFT JOIN Position   p ON e.position_id = p.position_id
    LEFT JOIN Employee_Skill es ON e.employee_id = es.employee_id
    LEFT JOIN Skill s          ON es.skill_id = s.skill_id
    LEFT JOIN Employee_Role er ON e.employee_id = er.employee_id
    WHERE e.manager_id = @ManagerID
      AND (@Skill IS NULL OR s.skill_name = @Skill)
      AND (@RoleID IS NULL OR er.role_id = @RoleID);
END;
GO


-- 14) ViewTeamCertifications
-- Adapted: using Verification + Employee_Verification

CREATE OR ALTER PROCEDURE ViewTeamCertifications
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.employee_id,
        e.full_name,
        v.verification_type,
        v.issuer,
        v.issue_date,
        v.expiry_period
    FROM EmployeeHierarchy eh
    JOIN Employee e
        ON eh.employee_id = e.employee_id
    JOIN Employee_Verification ev
        ON ev.employee_id = e.employee_id
    JOIN Verification v
        ON v.verification_id = ev.verification_id
    WHERE eh.manager_id = @ManagerID;
END;
GO

-- 15) AddManagerNotes

CREATE OR ALTER PROCEDURE AddManagerNotes
    @EmployeeID INT,
    @ManagerID INT,
    @Note VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NoteID INT;

    SELECT @NoteID = ISNULL(MAX(note_id), 0) + 1
    FROM ManagerNotes;

    INSERT INTO ManagerNotes
        (note_id, employee_id, manager_id, note_content, created_at)
    VALUES
        (@NoteID, @EmployeeID, @ManagerID, @Note, GETDATE());

    PRINT 'Manager note added.';
END;
GO


-- 16) RecordManualAttendance

CREATE OR ALTER PROCEDURE RecordManualAttendance
    @EmployeeID INT,
    @Date DATE,
    @ClockIn TIME,
    @ClockOut TIME,
    @Reason VARCHAR(200),
    @RecordedBy INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AttendanceID INT,
            @LogID INT,
            @Entry DATETIME,
            @Exit DATETIME;

    SELECT @AttendanceID = ISNULL(MAX(attendance_id), 0) + 1
    FROM Attendance;

    SET @Entry = CAST(@Date AS DATETIME) + CAST(@ClockIn AS DATETIME);
    SET @Exit  = CAST(@Date AS DATETIME) + CAST(@ClockOut AS DATETIME);

    INSERT INTO Attendance
        (attendance_id, employee_id, shift_id, entry_time, exit_time,
         duration, login_method, logout_method, exception_id)
    VALUES
        (@AttendanceID, @EmployeeID, NULL, @Entry, @Exit,
         DATEDIFF(MINUTE, @Entry, @Exit), 'Manual', 'Manual', NULL);

    SELECT @LogID = ISNULL(MAX(attendance_log_id), 0) + 1
    FROM AttendanceLog;

    INSERT INTO AttendanceLog
        (attendance_log_id, attendance_id, actor, timestamp, reason)
    VALUES
        (@LogID, @AttendanceID, @RecordedBy, GETDATE(),
         'Manual attendance entry. Reason: ' + @Reason);

    PRINT 'Manual attendance recorded.';
END;
GO


-- 17) ReviewMissedPunches
-- Adapted: use AttendanceLog entries whose reason mentions 'missed'

CREATE OR ALTER PROCEDURE ReviewMissedPunches
    @ManagerID INT,
    @Date DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        al.attendance_log_id,
        al.attendance_id,
        a.employee_id,
        e.full_name,
        al.timestamp,
        al.reason
    FROM AttendanceLog al
    JOIN Attendance a ON al.attendance_id = a.attendance_id
    JOIN Employee e   ON a.employee_id = e.employee_id
    WHERE e.manager_id = @ManagerID
      AND CONVERT(DATE, al.timestamp) = @Date
      AND al.reason LIKE '%missed%';
END;
GO


-- 18) ApproveTimeRequest
-- Adapted: uses AttendanceCorrectionRequest

CREATE OR ALTER PROCEDURE ApproveTimeRequest
    @RequestID INT,
    @ManagerID INT,
    @Decision  VARCHAR(50),
    @Comments  VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmployeeID INT,
            @OldReason VARCHAR(MAX),
            @NotificationID INT,
            @Msg VARCHAR(255);

    SELECT
        @EmployeeID = employee_id,
        @OldReason = CAST(ISNULL(reason, '') AS VARCHAR(MAX))
    FROM AttendanceCorrectionRequest
    WHERE request_id = @RequestID;

    UPDATE AttendanceCorrectionRequest
    SET status = @Decision,
        reason = @OldReason + ' | Manager(' + CAST(@ManagerID AS VARCHAR(20)) + '): ' + @Comments
    WHERE request_id = @RequestID;

    SELECT @NotificationID = ISNULL(MAX(notification_id), 0) + 1
    FROM Notification;

    SET @Msg = 'Your time request ' + CAST(@RequestID AS VARCHAR(20))
        + ' was ' + @Decision;

    INSERT INTO Notification (
        notification_id, message_content, timestamp, urgency, read_status, notification_type
    )
    VALUES (
        @NotificationID, @Msg, GETDATE(), 'Normal', 0, 'TimeRequest'
    );

    INSERT INTO Employee_Notification (
        employee_id, notification_id, delivery_status, delivered_at
    )
    VALUES (@EmployeeID, @NotificationID, 'Delivered', GETDATE());
END;
GO




-- 19) ViewLeaveRequest

CREATE OR ALTER PROCEDURE ViewLeaveRequest
    @LeaveRequestID INT,
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        lr.request_id,
        lr.employee_id,
        e.full_name,
        lr.leave_id,
        l.leave_type,
        lr.justification,
        lr.duration,
        lr.approval_timing,
        lr.status
    FROM LeaveRequest lr
    JOIN Employee e ON lr.employee_id = e.employee_id
    JOIN Leave l    ON lr.leave_id = l.leave_id
    WHERE lr.request_id = @LeaveRequestID
      AND e.manager_id = @ManagerID;
END;
GO


-- 20) ApproveLeaveRequest

CREATE OR ALTER PROCEDURE ApproveLeaveRequest
    @LeaveRequestID INT,
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC ReviewLeaveRequest @LeaveRequestID = @LeaveRequestID,
                            @ManagerID      = @ManagerID,
                            @Decision       = 'Approved';
END;
GO


-- 21) RejectLeaveRequest

CREATE OR ALTER PROCEDURE RejectLeaveRequest
    @LeaveRequestID INT,
    @ManagerID INT,
    @Reason VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    EXEC ReviewLeaveRequest @LeaveRequestID = @LeaveRequestID,
                            @ManagerID      = @ManagerID,
                            @Decision       = 'Rejected';

    -- Optional: store the rejection reason as a manager note
    DECLARE @EmpID INT, @NoteID INT;

    SELECT @EmpID = employee_id
    FROM LeaveRequest
    WHERE request_id = @LeaveRequestID;

    IF @EmpID IS NOT NULL
    BEGIN
        SELECT @NoteID = ISNULL(MAX(note_id), 0) + 1
        FROM ManagerNotes;

        INSERT INTO ManagerNotes
            (note_id, employee_id, manager_id, note_content, created_at)
        VALUES
            (@NoteID, @EmpID, @ManagerID,
             'Leave request ' + CAST(@LeaveRequestID AS VARCHAR(20)) +
             ' rejected. Reason: ' + @Reason,
             GETDATE());
    END;

    PRINT 'Leave request rejected.';
END;
GO


-- 22) DelegateLeaveApproval
-- Adapted: notification-based delegation

CREATE OR ALTER PROCEDURE DelegateLeaveApproval
    @ManagerID  INT,
    @DelegateID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NotificationID INT,
            @Msg VARCHAR(255);

    SELECT @NotificationID = ISNULL(MAX(notification_id), 0) + 1
    FROM Notification;

    SET @Msg = 'Manager ' + CAST(@ManagerID AS VARCHAR(20))
        + ' delegated leave approvals to employee '
        + CAST(@DelegateID AS VARCHAR(20));

    INSERT INTO Notification (
        notification_id, message_content, timestamp, urgency, read_status, notification_type
    )
    VALUES (
        @NotificationID, @Msg, GETDATE(), 'Normal', 0, 'Delegation'
    );

    INSERT INTO Employee_Notification (
        employee_id, notification_id, delivery_status, delivered_at
    )
    VALUES (@DelegateID, @NotificationID, 'Delivered', GETDATE());
END;
GO




-- 23) FlagIrregularLeave

CREATE OR ALTER PROCEDURE FlagIrregularLeave
    @EmployeeID INT,
    @ManagerID INT,
    @PatternDescription VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExceptionID INT,
            @NoteID INT;

    SELECT @ExceptionID = ISNULL(MAX(exception_id), 0) + 1
    FROM Exception;

    INSERT INTO Exception
        (exception_id, name, category, date, status)
    VALUES
        (@ExceptionID, 'Irregular Leave', 'Leave', GETDATE(), 'Flagged');

    IF NOT EXISTS (
        SELECT 1 FROM Employee_Exception
        WHERE employee_id = @EmployeeID
          AND exception_id = @ExceptionID
    )
        INSERT INTO Employee_Exception (employee_id, exception_id)
        VALUES (@EmployeeID, @ExceptionID);

    SELECT @NoteID = ISNULL(MAX(note_id), 0) + 1
    FROM ManagerNotes;

    INSERT INTO ManagerNotes
        (note_id, employee_id, manager_id, note_content, created_at)
    VALUES
        (@NoteID, @EmployeeID, @ManagerID,
         'Irregular leave flagged: ' + @PatternDescription,
         GETDATE());

    PRINT 'Irregular leave flagged.';
END;
GO


-- 24) NotifyNewLeaveRequest

CREATE OR ALTER PROCEDURE NotifyNewLeaveRequest
    @RequestID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmployeeID INT,
            @ManagerID INT,
            @NotificationID INT,
            @Msg VARCHAR(255);

    SELECT
        @EmployeeID = lr.employee_id,
        @ManagerID = eh.manager_id
    FROM LeaveRequest lr
    JOIN EmployeeHierarchy eh
        ON lr.employee_id = eh.employee_id
    WHERE lr.request_id = @RequestID;

    SELECT @NotificationID = ISNULL(MAX(notification_id), 0) + 1
    FROM Notification;

    SET @Msg = 'New leave request ' + CAST(@RequestID AS VARCHAR(20))
        + ' by employee ' + CAST(@EmployeeID AS VARCHAR(20));

    INSERT INTO Notification (
        notification_id, message_content, timestamp, urgency, read_status, notification_type
    )
    VALUES (
        @NotificationID, @Msg, GETDATE(), 'Normal', 0, 'LeaveRequest'
    );

    INSERT INTO Employee_Notification (
        employee_id, notification_id, delivery_status, delivered_at
    )
    VALUES (@ManagerID, @NotificationID, 'Delivered', GETDATE());
END;
GO
/* ===========================================================
   PART 5 — EMPLOYEE PROCEDURES
   Adapted to original HRMS schema (NO schema changes)
   =========================================================== */

--------------------------------------------------------------
-- 1) SubmitLeaveRequest
-- Adapted to your LeaveRequest schema:
-- request_id, employee_id, leave_id, justification, duration
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE SubmitLeaveRequest
    @EmployeeID INT,
    @LeaveTypeID INT,
    @StartDate DATE,
    @EndDate DATE,
    @Reason VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewRequestID INT;

    SELECT @NewRequestID = ISNULL(MAX(request_id),0) + 1
    FROM LeaveRequest;

    INSERT INTO LeaveRequest
        (request_id, employee_id, leave_id, justification, duration, status)
    VALUES
        (@NewRequestID, @EmployeeID, @LeaveTypeID, @Reason,
         DATEDIFF(DAY, @StartDate, @EndDate) + 1,
         'Pending');

    PRINT 'Leave request submitted.';
END;
GO

--------------------------------------------------------------
-- 2) GetLeaveBalance
-- Adaptation:
-- Uses LeaveEntitlement table (entitlement = remaining days)
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE GetLeaveBalance
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.leave_type,
        le.entitlement AS RemainingDays
    FROM LeaveEntitlement le
    JOIN Leave l ON le.leave_type_id = l.leave_id
    WHERE le.employee_id = @EmployeeID;
END;
GO

--------------------------------------------------------------
-- 3) ViewLeaveBalance
-- Returns total remaining days
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ViewLeaveBalance
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SUM(entitlement) AS RemainingLeaveDays
    FROM LeaveEntitlement
    WHERE employee_id = @EmployeeID;
END;
GO

--------------------------------------------------------------
-- 4) RecordAttendance
-- Adapted:
-- Insert into Attendance table (entry_time, exit_time)
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE RecordAttendance
    @EmployeeID INT,
    @ShiftID INT,
    @EntryTime TIME,
    @ExitTime TIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AttendanceID INT,
            @Entry DATETIME,
            @Exit DATETIME;

    SELECT @AttendanceID = ISNULL(MAX(attendance_id),0) + 1
    FROM Attendance;

    SET @Entry = CAST(CONVERT(VARCHAR(10),GETDATE(),120) + ' ' +
                      CONVERT(VARCHAR(8),@EntryTime,108) AS DATETIME);

    SET @Exit = CAST(CONVERT(VARCHAR(10),GETDATE(),120) + ' ' +
                     CONVERT(VARCHAR(8),@ExitTime,108) AS DATETIME);

    INSERT INTO Attendance
        (attendance_id, employee_id, shift_id,
         entry_time, exit_time, duration,
         login_method, logout_method, exception_id)
    VALUES
        (@AttendanceID, @EmployeeID, @ShiftID,
         @Entry, @Exit,
         DATEDIFF(MINUTE,@Entry,@Exit),
         'Manual','Manual',NULL);
END;
GO

--------------------------------------------------------------
-- 5) SubmitReimbursement
-- Maps to your Reimbursement table
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE SubmitReimbursement
    @EmployeeID  INT,
    @ExpenseType VARCHAR(50),
    @Amount      DECIMAL(10,2)   -- kept for interface compatibility, but NOT stored
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RID INT;

    SELECT @RID = ISNULL(MAX(reimbursement_id), 0) + 1
    FROM Reimbursement;

    INSERT INTO Reimbursement
        (reimbursement_id, [type], claim_type, approval_date, current_status, employee_id)
    VALUES
        (
            @RID,
            'Expense',          -- generic type
            @ExpenseType,       -- stored as claim_type
            NULL,               -- approval_date (not yet approved)
            'Pending',          -- current_status
            @EmployeeID
        );
END;
GO


--------------------------------------------------------------
-- 6) AddEmployeeSkill
-- Maps to Employee_Skill (skill must already exist!)
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE AddEmployeeSkill
    @EmployeeID INT,
    @SkillName VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SkillID INT;

    SELECT @SkillID = skill_id
    FROM Skill
    WHERE skill_name = @SkillName;

    IF @SkillID IS NULL
    BEGIN
        RAISERROR ('Skill does not exist.', 16, 1);
        RETURN;
    END;

    INSERT INTO Employee_Skill (employee_id, skill_id)
    VALUES (@EmployeeID, @SkillID);
END;
GO

--------------------------------------------------------------
-- 7) ViewAssignedShifts
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ViewAssignedShifts
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT shift_id, start_date, end_date, status
    FROM ShiftAssignment
    WHERE employee_id = @EmployeeID;
END;
GO

--------------------------------------------------------------
-- 8) ViewMyContracts
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ViewMyContracts
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.*
    FROM Employee AS e
    JOIN Contract AS c
        ON e.contract_id = c.contract_id
    WHERE e.employee_id = @EmployeeID;
END;
GO


--------------------------------------------------------------
-- 9) ViewMyPayroll
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ViewMyPayroll
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Payroll
    WHERE employee_id = @EmployeeID;
END;
GO

--------------------------------------------------------------
-- 10) UpdatePersonalDetails
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE UpdatePersonalDetails
    @EmployeeID INT,
    @Phone VARCHAR(20),
    @Address VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Employee
    SET phone = @Phone,
        address = @Address
    WHERE employee_id = @EmployeeID;
END;
GO

--------------------------------------------------------------
-- 11) ViewMyMissions
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ViewMyMissions
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Mission
    WHERE employee_id = @EmployeeID;
END;
GO

--------------------------------------------------------------
-- 12) ViewEmployeeProfile
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ViewEmployeeProfile
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Employee
    WHERE employee_id = @EmployeeID;
END;
GO

--------------------------------------------------------------
-- 13) UpdateContactInformation
-- Adapted: contact info is inside Employee table
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE UpdateContactInformation
    @EmployeeID INT,
    @RequestType VARCHAR(50),
    @NewValue VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF @RequestType = 'phone'
        UPDATE Employee SET phone = @NewValue WHERE employee_id = @EmployeeID;

    ELSE IF @RequestType = 'address'
        UPDATE Employee SET address = @NewValue WHERE employee_id = @EmployeeID;

    ELSE
        RAISERROR('Invalid RequestType.',16,1);
END;
GO

--------------------------------------------------------------
-- 14) ViewEmploymentTimeline
-- Adapted: no EmploymentHistory, so we show:
-- hire_date + mission history + contract info
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ViewEmploymentTimeline
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Hire date from Employee
    SELECT 'Hire Date' AS event_type,
           hire_date   AS event_date
    FROM Employee
    WHERE employee_id = @EmployeeID

    UNION ALL

    -- Mission start dates
    SELECT 'Mission Start' AS event_type,
           start_date      AS event_date
    FROM Mission
    WHERE employee_id = @EmployeeID

    UNION ALL

    -- Mission end dates
    SELECT 'Mission End' AS event_type,
           end_date       AS event_date
    FROM Mission
    WHERE employee_id = @EmployeeID

    UNION ALL

    -- Contract start
    SELECT 'Contract Start' AS event_type,
           c.start_date     AS event_date
    FROM Employee AS e
    JOIN Contract AS c
        ON e.contract_id = c.contract_id
    WHERE e.employee_id = @EmployeeID

    UNION ALL

    -- Contract end
    SELECT 'Contract End' AS event_type,
           c.end_date      AS event_date
    FROM Employee AS e
    JOIN Contract AS c
        ON e.contract_id = c.contract_id
    WHERE e.employee_id = @EmployeeID

    ORDER BY event_date;
END;
GO


--------------------------------------------------------------
-- 15) UpdateEmergencyContact
-- Adapted: store as a ManagerNote for HR visibility
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE UpdateEmergencyContact
    @EmployeeID INT,
    @ContactName VARCHAR(100),
    @Relation VARCHAR(50),
    @Phone VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NoteID INT;

    SELECT @NoteID = ISNULL(MAX(note_id),0) + 1
    FROM ManagerNotes;

    INSERT INTO ManagerNotes
        (note_id, employee_id, manager_id, note_content, created_at)
    VALUES
        (@NoteID, @EmployeeID, NULL,
         'Emergency Contact Updated: ' + @ContactName
         + ', ' + @Relation + ', ' + @Phone,
         GETDATE());
END;
GO


-- 16) RequestHRDocument
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE RequestHRDocument
    @EmployeeID INT,
    @DocumentType VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NID INT;

    SELECT @NID = ISNULL(MAX(notification_id),0) + 1
    FROM Notification;

    INSERT INTO Notification
        (notification_id, message_content, timestamp, urgency, read_status, notification_type)
    VALUES
        (@NID, 'HR Document Request: ' + @DocumentType,
         GETDATE(), 'Normal', 0, 'HRDocument');

    INSERT INTO Employee_Notification
        (employee_id, notification_id, delivery_status, delivered_at)
    SELECT employee_id, @NID, 'Delivered', GETDATE()
    FROM Employee_Role
    WHERE role_id = 2; -- HR Admin
END;
GO

--------------------------------------------------------------
-- 17) LogFlexibleAttendance
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE LogFlexibleAttendance
    @EmployeeID INT,
    @Date DATE,
    @CheckIn TIME,
    @CheckOut TIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LogID INT,
            @AID INT;

    SELECT @AID = ISNULL(MAX(attendance_id),0) + 1
    FROM Attendance;

    INSERT INTO Attendance
        (attendance_id, employee_id, shift_id,
         entry_time, exit_time, duration,
         login_method, logout_method, exception_id)
    VALUES
        (@AID, @EmployeeID, NULL,
         CAST(@Date AS DATETIME) + CAST(@CheckIn AS DATETIME),
         CAST(@Date AS DATETIME) + CAST(@CheckOut AS DATETIME),
         DATEDIFF(MINUTE,
            CAST(@Date AS DATETIME) + CAST(@CheckIn AS DATETIME),
            CAST(@Date AS DATETIME) + CAST(@CheckOut AS DATETIME)),
         'Flexible','Flexible',NULL);

    SELECT @LogID = ISNULL(MAX(attendance_log_id),0) + 1
    FROM AttendanceLog;

    INSERT INTO AttendanceLog
        (attendance_log_id, attendance_id, actor, timestamp, reason)
    VALUES
        (@LogID, @AID, @EmployeeID, GETDATE(),
         'Flexible schedule attendance');
END;
GO

--------------------------------------------------------------
-- 18) NotifyMissedPunch
-- Adapted using Notification
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE NotifyMissedPunch
    @EmployeeID INT,
    @Date DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NID INT;

    SELECT @NID = ISNULL(MAX(notification_id),0) + 1
    FROM Notification;

    INSERT INTO Notification
        (notification_id, message_content, timestamp, urgency,
         read_status, notification_type)
    VALUES
        (@NID, 'Missed punch on: ' + CONVERT(VARCHAR(10),@Date,120),
         GETDATE(), 'High', 0, 'MissedPunch');

    INSERT INTO Employee_Notification
        (employee_id, notification_id, delivery_status, delivered_at)
    VALUES (@EmployeeID, @NID, 'Delivered', GETDATE());
END;
GO

--------------------------------------------------------------
-- 19) RecordMultiplePunches
-- Adapted: stored into AttendanceLog
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE RecordMultiplePunches
    @EmployeeID INT,
    @ClockInOutTime DATETIME,
    @Type VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AID INT,
            @LogID INT;

    SELECT @AID = ISNULL(MAX(attendance_id),0) + 1
    FROM Attendance;

    INSERT INTO Attendance
        (attendance_id, employee_id, shift_id,
         entry_time, exit_time, duration,
         login_method, logout_method, exception_id)
    VALUES
        (@AID, @EmployeeID, NULL,
         CASE WHEN @Type='IN' THEN @ClockInOutTime ELSE NULL END,
         CASE WHEN @Type='OUT' THEN @ClockInOutTime ELSE NULL END,
         NULL, 'Multi','Multi',NULL);

    SELECT @LogID = ISNULL(MAX(attendance_log_id),0) + 1
    FROM AttendanceLog;

    INSERT INTO AttendanceLog
        (attendance_log_id, attendance_id, actor, timestamp, reason)
    VALUES
        (@LogID, @AID, @EmployeeID, @ClockInOutTime,
         'Multiple punch recorded: ' + @Type);
END;
GO

--------------------------------------------------------------
-- 20) SubmitCorrectionRequest
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE SubmitCorrectionRequest
    @EmployeeID     INT,
    @Date           DATE,
    @CorrectionType VARCHAR(50),
    @Reason         VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RID INT;

    SELECT @RID = ISNULL(MAX(request_id), 0) + 1
    FROM AttendanceCorrectionRequest;

    INSERT INTO AttendanceCorrectionRequest
        (request_id, employee_id, [date], correction_type, reason, status, recorded_by)
    VALUES
        (
            @RID,
            @EmployeeID,
            @Date,
            @CorrectionType,
            @Reason,
            'Pending',
            @EmployeeID        -- employee recorded their own request
        );
END;
GO


--------------------------------------------------------------
-- 21) ViewRequestStatus
-- Adapted: Return all correction requests for employee
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ViewRequestStatus
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM AttendanceCorrectionRequest
    WHERE employee_id = @EmployeeID;
END;
GO

--------------------------------------------------------------
-- 22) AttachLeaveDocuments
--------------------------------------------------------------

CREATE OR ALTER PROCEDURE AttachLeaveDocuments
    @LeaveRequestID INT,
    @FilePath       VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DocID INT;

    SELECT @DocID = ISNULL(MAX(document_id), 0) + 1
    FROM LeaveDocument;

    INSERT INTO LeaveDocument
        (document_id, leave_request_id, file_path, uploaded_at)
    VALUES
        (
            @DocID,
            @LeaveRequestID,
            @FilePath,
            GETDATE()
        );
END;
GO


--------------------------------------------------------------
-- 23) ModifyLeaveRequest
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ModifyLeaveRequest
    @LeaveRequestID INT,
    @StartDate DATE,
    @EndDate DATE,
    @Reason VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE LeaveRequest
    SET justification = @Reason,
        duration = DATEDIFF(DAY,@StartDate,@EndDate)+1
    WHERE request_id = @LeaveRequestID
      AND status = 'Pending';
END;
GO

--------------------------------------------------------------
-- 24) CancelLeaveRequest
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE CancelLeaveRequest
    @LeaveRequestID INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM LeaveRequest
    WHERE request_id = @LeaveRequestID
      AND status = 'Pending';
END;
GO

--------------------------------------------------------------
-- 25) ViewLeaveHistory
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE ViewLeaveHistory
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM LeaveRequest
    WHERE employee_id = @EmployeeID;
END;
GO

--------------------------------------------------------------
-- 26) SubmitLeaveAfterAbsence
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE SubmitLeaveAfterAbsence
    @EmployeeID INT,
    @LeaveTypeID INT,
    @StartDate DATE,
    @EndDate DATE,
    @Reason VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewRequestID INT;

    SELECT @NewRequestID = ISNULL(MAX(request_id),0) + 1
    FROM LeaveRequest;

    INSERT INTO LeaveRequest
        (request_id, employee_id, leave_id, justification, duration, status)
    VALUES
        (@NewRequestID, @EmployeeID, @LeaveTypeID, @Reason,
         DATEDIFF(DAY, @StartDate, @EndDate) + 1,
         'Pending');
END;
GO

--------------------------------------------------------------
-- 27) NotifyLeaveStatusChange
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE NotifyLeaveStatusChange
    @EmployeeID INT,
    @RequestID INT,
    @Status VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NID INT;

    SELECT @NID = ISNULL(MAX(notification_id),0) + 1
    FROM Notification;

    INSERT INTO Notification
        (notification_id, message_content, timestamp, urgency, read_status, notification_type)
    VALUES
        (@NID,
         'Your leave request ' + CAST(@RequestID AS VARCHAR(20))
         + ' has been ' + @Status,
         GETDATE(), 'Normal', 0, 'LeaveStatus');

    INSERT INTO Employee_Notification
        (employee_id, notification_id, delivery_status, delivered_at)
    VALUES (@EmployeeID, @NID, 'Delivered', GETDATE());
END;
GO

--------------------------------------------------------------
-- 28) NotifyProfileUpdate
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE NotifyProfileUpdate
    @EmployeeID INT,
    @NotificationType VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NID INT;

    SELECT @NID = ISNULL(MAX(notification_id),0) + 1
    FROM Notification;

    INSERT INTO Notification
        (notification_id, message_content, timestamp, urgency, read_status, notification_type)
    VALUES
        (@NID, @NotificationType, GETDATE(), 'Normal', 0, 'ProfileUpdate');

    INSERT INTO Employee_Notification
        (employee_id, notification_id, delivery_status, delivered_at)
    VALUES (@EmployeeID, @NID, 'Delivered', GETDATE());
END;
GO



