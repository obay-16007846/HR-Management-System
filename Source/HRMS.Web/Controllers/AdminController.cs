using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[Authorize]
public class AdminController : Controller
{
    private readonly EmployeeRepository _repo;

    public AdminController(EmployeeRepository repo)
    {
        _repo = repo;
    }

    [HttpGet]
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

        await _repo.CreateEmployeeAsync(
            firstName, lastName, email, phone, departmentId, roleId);

        return RedirectToAction("LoginSuccess", "Account");
    }

    [Authorize(Roles = "System Admin")]
    [HttpGet]
    public async Task<IActionResult> AssignRole(int id)
    {
        var employee = await _repo.GetEmployeeByIdAsync(id);
        if (employee == null)
            return NotFound();

        var currentRoles = await _repo.GetEmployeeRoles(id);
        ViewBag.EmployeeId = id;
        ViewBag.EmployeeName = employee.FullName;
        ViewBag.CurrentRoles = currentRoles;
        
        return View();
    }

    [Authorize(Roles = "System Admin")]
    [HttpPost]
    public async Task<IActionResult> AssignRole(int employeeId, int roleId, string action)
    {
        if (action == "Add")
        {
            await _repo.AssignRoleToEmployee(employeeId, roleId);
        }
        else if (action == "Remove")
        {
            await _repo.RemoveRoleFromEmployee(employeeId, roleId);
        }

        return RedirectToAction("AssignRole", new { id = employeeId });
    }

}
