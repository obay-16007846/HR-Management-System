using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using HRMS.Web.Models;

namespace HRMS.Web.Controllers
{
    [Authorize]
    public class MissionController : Controller
    {
        private readonly EmployeeRepository _repo;

        public MissionController(EmployeeRepository repo)
        {
            _repo = repo;
        }

        // ========== EMPLOYEE FEATURES ==========

        public async Task<IActionResult> MyMissions()
        {
            int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            var missions = await _repo.GetEmployeeMissionsAsync(employeeId);
            return View(missions);
        }

        [HttpGet]
        public async Task<IActionResult> ViewMission(int id)
        {
            int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            var mission = await _repo.GetMissionByIdAsync(id);

            if (mission == null)
                return NotFound();

            // Employees can only view their own missions
            // Managers and HR Admins can view any mission
            if (mission.EmployeeId != employeeId && !User.IsInRole("HR Admin") && !User.IsInRole("Manager"))
                return Forbid();

            // If manager, check if employee is in their team
            if (User.IsInRole("Manager") && mission.EmployeeId != employeeId)
            {
                bool isTeamMember = await _repo.IsEmployeeInManagerTeam(employeeId, mission.EmployeeId);
                if (!isTeamMember)
                    return Forbid();
            }

            return View(mission);
        }

        // ========== MANAGER FEATURES ==========

        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> PendingRequests()
        {
            int managerId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            var requests = await _repo.GetPendingMissionRequestsAsync(managerId);
            return View(requests);
        }

        [HttpPost]
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> ApproveRequest(int missionId)
        {
            int managerId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            var mission = await _repo.GetMissionByIdAsync(missionId);

            if (mission == null)
                return NotFound();

            // Verify manager can approve this request
            if (mission.ManagerId != managerId)
                return Forbid();

            // Only approve if status is Pending or Requested
            if (mission.Status != "Pending" && mission.Status != "Requested")
            {
                TempData["Error"] = "This mission request has already been processed.";
                return RedirectToAction("PendingRequests");
            }

            await _repo.ApproveMissionRequestAsync(missionId, managerId);
            TempData["Success"] = "Mission request approved successfully";
            return RedirectToAction("PendingRequests");
        }

        [HttpPost]
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> RejectRequest(int missionId, string reason)
        {
            if (string.IsNullOrWhiteSpace(reason))
            {
                TempData["Error"] = "Rejection reason is required";
                return RedirectToAction("ViewMission", new { id = missionId });
            }

            int managerId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            var mission = await _repo.GetMissionByIdAsync(missionId);

            if (mission == null)
                return NotFound();

            // Verify manager can reject this request
            if (mission.ManagerId != managerId)
                return Forbid();

            // Only reject if status is Pending or Requested
            if (mission.Status != "Pending" && mission.Status != "Requested")
            {
                TempData["Error"] = "This mission request has already been processed.";
                return RedirectToAction("PendingRequests");
            }

            await _repo.RejectMissionRequestAsync(missionId, managerId, reason);
            TempData["Success"] = "Mission request rejected";
            return RedirectToAction("PendingRequests");
        }

        // ========== HR ADMIN FEATURES ==========

        [Authorize(Roles = "HR Admin")]
        [HttpGet]
        public async Task<IActionResult> AssignMission()
        {
            var employees = await _repo.GetAllEmployeesAsync();
            var managers = await _repo.GetAllEmployeesAsync(); // In a real system, filter by role
            ViewBag.Employees = employees;
            ViewBag.Managers = managers;
            return View();
        }

        [HttpPost]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> AssignMission(int employeeId, int managerId, string destination, DateTime startDate, DateTime endDate, string? description, string? purpose)
        {
            if (string.IsNullOrWhiteSpace(destination))
            {
                ViewBag.Error = "Destination is required";
                var employees = await _repo.GetAllEmployeesAsync();
                var managers = await _repo.GetAllEmployeesAsync();
                ViewBag.Employees = employees;
                ViewBag.Managers = managers;
                return View();
            }

            if (startDate > endDate)
            {
                ViewBag.Error = "Start date cannot be after end date";
                var employees = await _repo.GetAllEmployeesAsync();
                var managers = await _repo.GetAllEmployeesAsync();
                ViewBag.Employees = employees;
                ViewBag.Managers = managers;
                return View();
            }

            int hrAdminId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            await _repo.AssignMissionAsync(employeeId, managerId, destination, startDate, endDate, description, purpose);
            
            TempData["Success"] = "Mission assigned successfully";
            return RedirectToAction("AllMissions");
        }

        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> AllMissions()
        {
            var missions = await _repo.GetAllMissionsAsync();
            return View(missions);
        }
    }
}

