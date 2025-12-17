using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.IO;

namespace HRMS.Web.Controllers
{
    [Authorize]
    public class LeaveController : Controller
    {
        private readonly EmployeeRepository _repo;

        public LeaveController(EmployeeRepository repo)
        {
            _repo = repo;
        }

        [HttpGet]
        public async Task<IActionResult> SubmitRequest()
        {
            var leaveTypes = await _repo.GetAllLeaveTypesAsync();
            ViewBag.LeaveTypes = leaveTypes;
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SubmitRequest(int leaveId, DateTime startDate, DateTime endDate, string justification, IFormFile? attachment)
        {
            if (startDate > endDate)
            {
                ViewBag.Error = "Start date cannot be after end date";
                var leaveTypes = await _repo.GetAllLeaveTypesAsync();
                ViewBag.LeaveTypes = leaveTypes;
                return View();
            }

            int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));

            // Submit leave request
            int requestId = await _repo.SubmitLeaveRequestAsync(employeeId, leaveId, startDate, endDate, justification);

            // Handle file attachment if provided
            if (attachment != null && attachment.Length > 0)
            {
                // Generate unique filename
                string fileName = $"leave_{requestId}_{Path.GetFileName(attachment.FileName)}";
                
                // Save file
                string uploadPath = Path.Combine(
                    Directory.GetCurrentDirectory(),
                    "wwwroot/uploads/leave",
                    fileName
                );

                // Ensure directory exists
                Directory.CreateDirectory(Path.GetDirectoryName(uploadPath)!);

                using (var stream = new FileStream(uploadPath, FileMode.Create))
                {
                    await attachment.CopyToAsync(stream);
                }

                // Save document reference in database
                await _repo.UploadLeaveDocumentAsync(requestId, $"leave/{fileName}");
            }

            TempData["Success"] = "Leave request submitted successfully";
            return RedirectToAction("MyLeaveHistory");
        }

        public async Task<IActionResult> MyLeaveHistory()
        {
            int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
            var requests = await _repo.GetEmployeeLeaveRequestsAsync(employeeId);

            // Load documents for each request
            foreach (var request in requests)
            {
                request.Documents = await _repo.GetLeaveRequestDocumentsAsync(request.RequestId);
            }

            return View(requests);
        }

        public async Task<IActionResult> MyLeaveBalance()
        {
            int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
            var balance = await _repo.GetEmployeeLeaveBalanceAsync(employeeId);
            return View(balance);
        }

        [HttpGet]
        public async Task<IActionResult> ViewRequest(int id)
        {
            int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
            var request = await _repo.GetLeaveRequestByIdAsync(id);

            if (request == null)
                return NotFound();

            // Only allow employees to view their own requests, or managers/HR to view team requests
            if (request.EmployeeId != employeeId && !User.IsInRole("HR Admin") && !User.IsInRole("Manager"))
                return Forbid();

            // If manager, check if employee is in their team
            if (User.IsInRole("Manager") && request.EmployeeId != employeeId)
            {
                bool isTeamMember = await _repo.IsEmployeeInManagerTeam(employeeId, request.EmployeeId);
                if (!isTeamMember)
                    return Forbid();
            }

            request.Documents = await _repo.GetLeaveRequestDocumentsAsync(id);
            return View(request);
        }

        // ========== MANAGER LEAVE FEATURES ==========

        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> PendingRequests()
        {
            int managerId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
            var requests = await _repo.GetPendingLeaveRequestsAsync(managerId);

            // Load documents for each request
            foreach (var request in requests)
            {
                request.Documents = await _repo.GetLeaveRequestDocumentsAsync(request.RequestId);
            }

            return View(requests);
        }

        [HttpPost]
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> ApproveRequest(int requestId, string? comments)
        {
            int userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
            var request = await _repo.GetLeaveRequestByIdAsync(requestId);

            if (request == null)
                return NotFound();

            // Verify manager can approve this request (team member check)
            bool isTeamMember = await _repo.IsEmployeeInManagerTeam(userId, request.EmployeeId);
            if (!isTeamMember)
                return Forbid();

            // Only approve if status is Pending
            if (request.Status != "Pending")
            {
                TempData["Error"] = "This leave request has already been processed.";
                return RedirectToAction("PendingRequests");
            }

            await _repo.ApproveLeaveRequestAsync(requestId, userId, comments);
            
            // Sync with attendance after approval
            await _repo.SyncLeaveToAttendanceAsync(requestId);

            TempData["Success"] = "Leave request approved successfully and synced with attendance";
            return RedirectToAction("PendingRequests");
        }

        [HttpPost]
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> DenyRequest(int requestId, string reason)
        {
            if (string.IsNullOrWhiteSpace(reason))
            {
                TempData["Error"] = "Rejection reason is required";
                return RedirectToAction("ViewRequest", new { id = requestId });
            }

            int userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
            var request = await _repo.GetLeaveRequestByIdAsync(requestId);

            if (request == null)
                return NotFound();

            // Verify manager can deny this request (team member check)
            bool isTeamMember = await _repo.IsEmployeeInManagerTeam(userId, request.EmployeeId);
            if (!isTeamMember)
                return Forbid();

            // Only deny if status is Pending
            if (request.Status != "Pending")
            {
                TempData["Error"] = "This leave request has already been processed.";
                return RedirectToAction("PendingRequests");
            }

            await _repo.DenyLeaveRequestAsync(requestId, userId, reason);
            TempData["Success"] = "Leave request denied";
            return RedirectToAction("PendingRequests");
        }

        [HttpPost]
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> FlagIrregularPattern(int employeeId, string reason)
        {
            if (string.IsNullOrWhiteSpace(reason))
            {
                TempData["Error"] = "Reason is required";
                return RedirectToAction("PendingRequests");
            }

            int userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
            
            // Verify manager can flag this employee (team member check)
            bool isTeamMember = await _repo.IsEmployeeInManagerTeam(userId, employeeId);
            if (!isTeamMember)
                return Forbid();

            await _repo.FlagIrregularLeavePatternAsync(employeeId, reason);
            TempData["Success"] = "Irregular leave pattern flagged and HR has been notified";
            return RedirectToAction("PendingRequests");
        }

        // ========== HR ADMIN LEAVE FEATURES ==========

        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> ManageLeaveTypes()
        {
            var leaveTypes = await _repo.GetAllLeaveTypesAsync();
            return View(leaveTypes);
        }

        [HttpGet]
        [Authorize(Roles = "HR Admin")]
        public IActionResult CreateLeaveType()
        {
            return View();
        }

        [HttpPost]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> CreateLeaveType(string leaveType, string description)
        {
            if (string.IsNullOrWhiteSpace(leaveType))
            {
                ViewBag.Error = "Leave type name is required";
                return View();
            }

            await _repo.CreateLeaveTypeAsync(leaveType, description ?? "");
            TempData["Success"] = "Leave type created successfully";
            return RedirectToAction("ManageLeaveTypes");
        }

        [HttpGet]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> CreateLeavePolicy()
        {
            var leaveTypes = await _repo.GetAllLeaveTypesAsync();
            ViewBag.LeaveTypes = leaveTypes;
            return View();
        }

        [HttpPost]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> CreateLeavePolicy(string name, string purpose, string eligibilityRules, int noticePeriod, string specialLeaveType, bool resetOnNewYear)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                ViewBag.Error = "Policy name is required";
                var leaveTypes = await _repo.GetAllLeaveTypesAsync();
                ViewBag.LeaveTypes = leaveTypes;
                return View();
            }

            await _repo.CreateLeavePolicyAsync(name, purpose ?? "", eligibilityRules ?? "", noticePeriod, specialLeaveType ?? "", resetOnNewYear);
            TempData["Success"] = "Leave policy created successfully";
            return RedirectToAction("ManageLeaveTypes");
        }

        [HttpGet]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> AssignLeaveEntitlement()
        {
            var employees = await _repo.GetAllEmployeesAsync();
            var leaveTypes = await _repo.GetAllLeaveTypesAsync();
            ViewBag.Employees = employees;
            ViewBag.LeaveTypes = leaveTypes;
            return View();
        }

        [HttpPost]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> AssignLeaveEntitlement(int employeeId, int leaveTypeId, decimal entitlement)
        {
            if (entitlement < 0)
            {
                TempData["Error"] = "Entitlement cannot be negative";
                return RedirectToAction("AssignLeaveEntitlement");
            }

            await _repo.AssignLeaveEntitlementAsync(employeeId, leaveTypeId, entitlement);
            TempData["Success"] = "Leave entitlement assigned successfully";
            return RedirectToAction("AssignLeaveEntitlement");
        }

        [HttpGet]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> AdjustLeaveEntitlement()
        {
            var employees = await _repo.GetAllEmployeesAsync();
            var leaveTypes = await _repo.GetAllLeaveTypesAsync();
            ViewBag.Employees = employees;
            ViewBag.LeaveTypes = leaveTypes;
            return View();
        }

        [HttpPost]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> AdjustLeaveEntitlement(int employeeId, int leaveTypeId, decimal adjustment)
        {
            await _repo.AdjustLeaveEntitlementAsync(employeeId, leaveTypeId, adjustment);
            TempData["Success"] = $"Leave entitlement adjusted by {adjustment} days";
            return RedirectToAction("AdjustLeaveEntitlement");
        }

        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> AllLeaveRequests(string? status = null)
        {
            var requests = await _repo.GetAllLeaveRequestsAsync(status);

            // Load documents for each request
            foreach (var request in requests)
            {
                request.Documents = await _repo.GetLeaveRequestDocumentsAsync(request.RequestId);
            }

            ViewBag.Status = status;
            return View(requests);
        }

        [HttpGet]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> OverrideLeaveDecision(int id)
        {
            var request = await _repo.GetLeaveRequestByIdAsync(id);
            if (request == null)
                return NotFound();

            return View(request);
        }

        [HttpPost]
        [Authorize(Roles = "HR Admin")]
        public async Task<IActionResult> OverrideLeaveDecision(int requestId, string newStatus, string reason)
        {
            if (string.IsNullOrWhiteSpace(reason))
            {
                TempData["Error"] = "Reason is required for override";
                return RedirectToAction("OverrideLeaveDecision", new { id = requestId });
            }

            int userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
            await _repo.OverrideLeaveDecisionAsync(requestId, newStatus, reason, userId);
            
            // If overriding to Approved, sync with attendance
            if (newStatus == "Approved")
            {
                await _repo.SyncLeaveToAttendanceAsync(requestId);
            }

            TempData["Success"] = "Leave decision overridden successfully";
            return RedirectToAction("AllLeaveRequests");
        }
    }
}

