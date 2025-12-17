using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.IO;
using System.Security.Claims;
using System.Threading.Tasks;

namespace HRMS.Web.Controllers
{
    [Authorize]
    public class EmployeeController : Controller
    {
        private readonly EmployeeRepository _repo;

        public EmployeeController(EmployeeRepository repo)
        {
            _repo = repo;
        }

        private bool IsHRAdmin()
        {
            return User.IsInRole("HR Admin");
        }

        [Authorize(Roles = "HR Admin,System Admin")]
        public async Task<IActionResult> Index()
        {
            var employees = await _repo.GetAllEmployeesAsync();
            return View(employees);
        }

        public async Task<IActionResult> MyProfile()
        {
            int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));

            var emp = await _repo.GetEmployeeById(employeeId);

            return View(emp);   
        }

        [Authorize]
        public async Task<IActionResult> View(int id)
        {
            int loggedInId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            bool isHR = User.IsInRole("HR Admin");
            bool isAdmin = User.IsInRole("System Admin");
            bool isManager = User.IsInRole("Manager");

            // Employees can ONLY view themselves
            // Managers can view their team members
            // HR Admin and System Admin can view anyone
            if (id != loggedInId && !isHR && !isAdmin)
            {
                if (isManager)
                {
                    // Check if the employee is in the manager's team
                    bool isTeamMember = await _repo.IsEmployeeInManagerTeam(loggedInId, id);
                    if (!isTeamMember)
                        return RedirectToAction("AccessDenied", "Account");
                }
                else
                {
                    return RedirectToAction("AccessDenied", "Account");
                }
            }

            var emp = await _repo.GetEmployeeByIdAsync(id);
            if (emp == null)
                return NotFound();

            return View(emp);
        }

        [Authorize]
        public async Task<IActionResult> EditMyProfile()
        {
            int id = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var emp = await _repo.GetEmployeeByIdAsync(id);
            return View(emp);
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> EditMyProfile(Employee e)
        {
            int id = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            if (e.EmployeeId != id)
                return Forbid();

            await _repo.UpdateMyProfileAsync(e);
            return RedirectToAction("MyProfile");
        }

        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> EditEmployee(int id)
        {
            var emp = await _repo.GetEmployeeByIdAsync(id);
            if (emp == null)
                return NotFound();

            return View(emp);
        }

        [HttpPost]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> EditEmployee(Employee e)
        {
            await _repo.HRUpdateEmployeeAsync(e);
            return RedirectToAction("View", new { id = e.EmployeeId });
        }

        [Authorize(Roles = "Manager,HR Admin,System Admin")]
        public async Task<IActionResult> MyTeam()
        {
            int managerId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));

            // HR / System Admin can see all (optional extension)
            if (User.IsInRole("HR Admin") || User.IsInRole("System Admin"))
            {
                return RedirectToAction("Index"); // your full employee list
            }

            var team = await _repo.GetTeamAsync(managerId);
            return View(team);
        }

        [HttpPost]
        public async Task<IActionResult> UploadProfileImage(IFormFile profileImage)
        {
            if (profileImage == null || profileImage.Length == 0)
                return RedirectToAction("MyProfile");

            // Get logged-in employee ID
            int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));

            // Generate filename
            string fileName = employeeId + Path.GetExtension(profileImage.FileName);

            // Save path
            string uploadPath = Path.Combine(
                Directory.GetCurrentDirectory(),
                "wwwroot/uploads",
                fileName
            );

            using (var stream = new FileStream(uploadPath, FileMode.Create))
            {
                await profileImage.CopyToAsync(stream);
            }

            // Save filename to DB
            await _repo.UpdateProfileImage(employeeId, fileName);

            return RedirectToAction("MyProfile");
        }

        [HttpGet]
        [Authorize]
        public async Task<IActionResult> GetProfileImage()
        {
            int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            var emp = await _repo.GetEmployeeById(employeeId);
            
            if (emp != null && !string.IsNullOrEmpty(emp.ProfileImage))
            {
                return Json(new { profileImage = emp.ProfileImage });
            }
            
            return Json(new { profileImage = (string?)null });
        }

        [Authorize]
        public async Task<IActionResult> Notifications()
        {
            int empId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));

            var notifications = await _repo.GetEmployeeNotifications(empId);
            return View(notifications);
        }

        [HttpGet]
        [Authorize]
        public async Task<IActionResult> GetUnreadNotificationCount()
        {
            int empId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            int count = await _repo.GetUnreadNotificationCountAsync(empId);
            return Json(new { count });
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> MarkNotificationAsRead([FromBody] int notificationId)
        {
            int empId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            await _repo.MarkNotificationAsReadAsync(notificationId, empId);
            return Json(new { success = true });
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> MarkAllNotificationsAsRead()
        {
            int empId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            await _repo.MarkAllNotificationsAsReadAsync(empId);
            return Json(new { success = true });
        }

        [Authorize]
        public async Task<IActionResult> MyContract()
        {
            int empId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            var contract = await _repo.GetEmployeeContract(empId);

            if (contract == null)
                return View("NoContract");

            return View(contract);
        }

        // ========== COMPONENT 5: MANAGER TEAM NOTIFICATIONS ==========

        [Authorize(Roles = "Manager")]
        [HttpGet]
        public IActionResult SendTeamNotification()
        {
            return View();
        }

        [HttpPost]
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> SendTeamNotification(string message, string urgency)
        {
            if (string.IsNullOrWhiteSpace(message))
            {
                ViewBag.Error = "Message is required";
                return View();
            }

            int managerId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            await _repo.SendTeamNotificationAsync(managerId, message, urgency ?? "Normal");
            
            TempData["Success"] = "Notification sent to all team members";
            return RedirectToAction("Notifications");
        }
    }
}
