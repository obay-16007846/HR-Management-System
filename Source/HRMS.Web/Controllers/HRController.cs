using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[Authorize]
public class HRController : Controller
{
    private readonly EmployeeRepository _repo;

    public HRController(EmployeeRepository repo)
    {
        _repo = repo;
    }

    [HttpGet]
    [Authorize(Roles = "System Admin,HR Admin")]
    public async Task<IActionResult> EditEmployee(int? id)
    {
        if (id.HasValue)
        {
            var employee = await _repo.GetEmployeeByIdAsync(id.Value);
            if (employee == null)
            {
                return NotFound();
            }
            ViewBag.EmployeeID = id.Value;
            ViewBag.Email = employee.Email ?? "";
            ViewBag.Phone = employee.Phone ?? "";
            ViewBag.Address = employee.Address ?? "";
            return View();
        }
        else
        {
            // No ID provided - show list of employees to select from
            // Check if there's a search term
            var searchTerm = Request.Query["search"].ToString();
            List<Employee> employees;
            
            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                employees = await _repo.SearchEmployeesAsync(searchTerm);
                ViewBag.SearchTerm = searchTerm;
            }
            else
            {
                employees = await _repo.GetAllEmployeesAsync();
            }
            
            return View("SelectEmployee", employees);
        }
    }

    [HttpPost]
    [Authorize(Roles = "System Admin,HR Admin")]
    public async Task<IActionResult> EditEmployee(
        int employeeId,
        string email,
        string phone,
        string address)
    {
        await _repo.UpdateEmployeeAsync(employeeId, email, phone, address);
        return RedirectToAction("Index", "Home");
    }

    public IActionResult SelectEmployee()
    {
        return View();
    }

    [Authorize(Roles = "System Admin,HR Admin")]
    public IActionResult CreateEmployee()
    {
        var roles = new List<string>();

        if (User.IsInRole("System Admin"))
        {
            roles.AddRange(new[] { "System Admin", "HR Admin", "Line Manager", "Employee" });
        }
        else if (User.IsInRole("HR Admin"))
        {
            roles.AddRange(new[] { "HR Admin", "Line Manager", "Employee" });
        }

        ViewBag.AllowedRoles = roles;
        return View();
    }

    [HttpPost]
    [Authorize(Roles = "System Admin,HR Admin")]
    public async Task<IActionResult> CreateEmployee(
        string firstName,
        string lastName,
        string email,
        string phone,
        int departmentId,
        string RoleName)
    {
        if (User.IsInRole("HR Admin") && RoleName == "System Admin")
            return Forbid();

        var roleIdMap = new Dictionary<string, int>
        {
            { "System Admin", 1 },
            { "HR Admin", 2 },
            { "Line Manager", 3 },
            { "Employee", 4 }
        };

        var roleId = roleIdMap[RoleName];

        await _repo.CreateEmployeeAsync(firstName, lastName, email, phone, departmentId, roleId);
        return RedirectToAction("Index", "Home");
    }


    [Authorize(Roles = "HR Admin")]
    public async Task<IActionResult> IncompleteProfiles()
    {
        var profiles = await _repo.GetIncompleteProfilesAsync();
        return View(profiles);
    }

    [Authorize(Roles = "HR Admin")]
    [HttpGet]
    public IActionResult CreateContract()
    {
        return View();
    }

    [Authorize(Roles = "HR Admin")]
    [HttpPost]
    public async Task<IActionResult> CreateContract(
        int employeeId,
        string type,
        DateTime startDate,
        DateTime endDate)
    {
        await _repo.CreateContractAsync(
            type,
            startDate,
            endDate,
            "Active",
            employeeId
        );

        await _repo.CreateNotificationAsync(
            employeeId,
            "Your employment contract has been created.",
            "High"
        );

        return RedirectToAction("IncompleteProfiles");
    }

    [Authorize(Roles = "HR Admin")]
    public async Task<IActionResult> RenewContract(int employeeId, int contractId)
    {
        var contract = await _repo.GetContractByIdAsync(contractId);
        if (contract == null)
        {
            return NotFound();
        }

        ViewBag.EmployeeId = employeeId;
        ViewBag.ContractId = contractId;
        ViewBag.EmployeeName = contract.FullName;
        ViewBag.CurrentType = contract.ContractType;
        ViewBag.CurrentStartDate = contract.StartDate.ToString("yyyy-MM-dd");
        ViewBag.CurrentEndDate = contract.EndDate.ToString("yyyy-MM-dd");
        return View();
    }

    [HttpPost]
    [Authorize(Roles = "HR Admin")]
    public async Task<IActionResult> RenewContract(
        int employeeId,
        int contractId,
        DateTime startDate,
        DateTime endDate,
        string type)
    {
        await _repo.RenewContractAsync(employeeId, contractId, startDate, endDate, type);
        
        await _repo.CreateNotificationAsync(
            employeeId,
            "Your contract has been renewed.",
            "High"
        );

        return RedirectToAction("ExpiringContracts");
    }

    [Authorize(Roles = "HR Admin")]
    public async Task<IActionResult> ExpiringContracts()
    {
        var contracts = await _repo.GetExpiringContractsAsync();
        return View(contracts);
    }
}
