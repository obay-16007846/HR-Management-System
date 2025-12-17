using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

public class AccountController : Controller
{
    private readonly EmployeeRepository _repo;

    public AccountController(EmployeeRepository repo)
    {
        _repo = repo;
    }

    [HttpGet]
    public IActionResult Login() => View();

    [HttpPost]
    public async Task<IActionResult> Login(string email, string nationalId)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            ViewBag.Error = "Email is required";
            return View();
        }

        // First, check if employee exists by email (for first-time login detection)
        var empByEmail = await _repo.GetEmployeeByEmailAsync(email);
        
        if (empByEmail == null)
        {
            ViewBag.Error = "Invalid email address";
            return View();
        }

        // Check if this is a first-time login (national_id is NULL)
        if (empByEmail.AccountStatus == "FirstTimeLogin")
        {
            // Redirect to first-time login page
            TempData["Email"] = email;
            TempData["EmployeeId"] = empByEmail.EmployeeId;
            return RedirectToAction("FirstTimeLogin");
        }

        // Regular login - national ID is required
        if (string.IsNullOrWhiteSpace(nationalId))
        {
            ViewBag.Error = "National ID (Password) is required";
            return View();
        }

        // Check credentials
        var emp = await _repo.LoginAsync(email, nationalId);
        if (emp == null)
        {
            ViewBag.Error = "Invalid credentials";
            return View();
        }

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, emp.EmployeeId.ToString()),
            new Claim(ClaimTypes.Name, emp.FullName ?? ""),
            new Claim(ClaimTypes.Email, emp.Email ?? ""),
            new Claim(ClaimTypes.Role, emp.RoleName ?? "Employee")
        };

        var identity = new ClaimsIdentity(
            claims, CookieAuthenticationDefaults.AuthenticationScheme);

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity));

        return RedirectToAction("LoginSuccess");
    }

    [HttpGet]
    public IActionResult FirstTimeLogin()
    {
        if (TempData["Email"] == null)
        {
            return RedirectToAction("Login");
        }

        ViewBag.Email = TempData["Email"];
        ViewBag.EmployeeId = TempData["EmployeeId"];
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> FirstTimeLogin(string email, int employeeId, string nationalId)
    {
        if (string.IsNullOrWhiteSpace(nationalId))
        {
            ViewBag.Error = "National ID is required";
            ViewBag.Email = email;
            ViewBag.EmployeeId = employeeId;
            return View();
        }

        // Set the national ID for the employee
        await _repo.SetNationalIdAsync(employeeId, nationalId);

        // Now authenticate the user
        var emp = await _repo.LoginAsync(email, nationalId);
        if (emp == null)
        {
            ViewBag.Error = "Error setting up account. Please contact HR.";
            ViewBag.Email = email;
            ViewBag.EmployeeId = employeeId;
            return View();
        }

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, emp.EmployeeId.ToString()),
            new Claim(ClaimTypes.Name, emp.FullName ?? ""),
            new Claim(ClaimTypes.Email, emp.Email ?? ""),
            new Claim(ClaimTypes.Role, emp.RoleName ?? "Employee")
        };

        var identity = new ClaimsIdentity(
            claims, CookieAuthenticationDefaults.AuthenticationScheme);

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity));

        // Redirect to complete profile page
        return RedirectToAction("EditMyProfile", "Employee");
    }

    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync();
        return RedirectToAction("Login");
    }

    [Authorize]
    public IActionResult LoginSuccess()
    {
        return View();
    }

    [HttpGet]
    public IActionResult AccessDenied()
    {
        return View();
    }

    [HttpGet]
    public IActionResult Register()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Register(
        string firstName,
        string lastName,
        string email,
        string phone,
        string nationalId,
        int departmentId,
        string roleName)
    {
        // Validate inputs
        if (string.IsNullOrWhiteSpace(firstName) || string.IsNullOrWhiteSpace(lastName))
        {
            ViewBag.Error = "First name and last name are required";
            return View();
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            ViewBag.Error = "Email is required";
            return View();
        }

        if (string.IsNullOrWhiteSpace(nationalId))
        {
            ViewBag.Error = "National ID (Password) is required";
            return View();
        }

        // Validate role - only System Admin, HR Admin, or Line Manager can self-register
        var allowedRoles = new[] { "System Admin", "HR Admin", "Line Manager" };
        if (!allowedRoles.Contains(roleName))
        {
            ViewBag.Error = "Invalid role. Only System Admin, HR Admin, and Line Manager can self-register.";
            return View();
        }

        // Map role name to role ID
        var roleIdMap = new Dictionary<string, int>
        {
            { "System Admin", 1 },
            { "HR Admin", 2 },
            { "Line Manager", 3 }
        };

        if (!roleIdMap.ContainsKey(roleName))
        {
            ViewBag.Error = "Invalid role selected";
            return View();
        }

        int roleId = roleIdMap[roleName];

        try
        {
            // Create the account
            int employeeId = await _repo.SelfRegisterAsync(
                firstName,
                lastName,
                email,
                phone ?? "",
                nationalId,
                departmentId,
                roleId
            );

            // Automatically log in the user
            var emp = await _repo.LoginAsync(email, nationalId);
            if (emp == null)
            {
                ViewBag.Error = "Account created but login failed. Please try logging in manually.";
                return View();
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, emp.EmployeeId.ToString()),
                new Claim(ClaimTypes.Name, emp.FullName ?? ""),
                new Claim(ClaimTypes.Email, emp.Email ?? ""),
                new Claim(ClaimTypes.Role, emp.RoleName ?? "Employee")
            };

            var identity = new ClaimsIdentity(
                claims, CookieAuthenticationDefaults.AuthenticationScheme);

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                new ClaimsPrincipal(identity));

            TempData["Success"] = "Account created successfully! Welcome to HRMS.";
            return RedirectToAction("LoginSuccess");
        }
        catch (Exception ex)
        {
            ViewBag.Error = ex.Message;
            return View();
        }
    }
}
