using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

[Authorize]
public class AttendanceController : Controller
{
    private readonly EmployeeRepository _repo;

    public AttendanceController(EmployeeRepository repo)
    {
        _repo = repo;
    }

    // Employee: Record Daily Attendance
    [Authorize]
    [HttpGet]
    public async Task<IActionResult> RecordAttendance()
    {
        int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
        var todayAttendance = await _repo.GetTodayAttendanceAsync(employeeId);
        
        if (todayAttendance != null && todayAttendance.ExitTime.HasValue)
        {
            ViewBag.Message = "You have already completed your attendance for today.";
            ViewBag.Attendance = todayAttendance;
            return View("AttendanceComplete", todayAttendance);
        }
        
        ViewBag.TodayAttendance = todayAttendance;
        var shifts = await _repo.GetEmployeeShiftsAsync(employeeId);
        ViewBag.Shifts = shifts;
        
        return View();
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> RecordAttendanceEntry(int? shiftId, string loginMethod)
    {
        int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
        
        try
        {
            var attendanceId = await _repo.RecordAttendanceAsync(employeeId, shiftId, DateTime.Now, loginMethod ?? "Web");
            TempData["Success"] = "Attendance recorded successfully. Don't forget to record your exit time.";
            return RedirectToAction("RecordAttendance");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error recording attendance: {ex.Message}";
            return RedirectToAction("RecordAttendance");
        }
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> RecordAttendanceExit(int attendanceId, string logoutMethod)
    {
        try
        {
            await _repo.UpdateAttendanceExitAsync(attendanceId, DateTime.Now, logoutMethod ?? "Web");
            TempData["Success"] = "Exit time recorded successfully.";
            return RedirectToAction("RecordAttendance");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error recording exit time: {ex.Message}";
            return RedirectToAction("RecordAttendance");
        }
    }

    // Employee: View Attendance History
    [Authorize]
    public async Task<IActionResult> MyAttendance(DateTime? startDate, DateTime? endDate)
    {
        int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
        var attendance = await _repo.GetEmployeeAttendanceAsync(employeeId, startDate, endDate);
        
        ViewBag.StartDate = startDate?.ToString("yyyy-MM-dd");
        ViewBag.EndDate = endDate?.ToString("yyyy-MM-dd");
        
        return View(attendance);
    }

    // Employee: Submit Attendance Correction Request
    [Authorize]
    [HttpGet]
    public IActionResult SubmitCorrectionRequest()
    {
        return View();
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> SubmitCorrectionRequest(DateTime date, string correctionType, string reason)
    {
        int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
        
        try
        {
            await _repo.SubmitAttendanceCorrectionRequestAsync(employeeId, date, correctionType, reason);
            TempData["Success"] = "Correction request submitted successfully. It will be reviewed by your manager.";
            return RedirectToAction("MyCorrectionRequests");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error submitting correction request: {ex.Message}";
            return View();
        }
    }

    [Authorize]
    public async Task<IActionResult> MyCorrectionRequests()
    {
        int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
        var requests = await _repo.GetAttendanceCorrectionRequestsAsync(employeeId);
        return View(requests);
    }

    // System Admin: Sync Leave with Attendance
    [Authorize(Roles = "System Admin")]
    [HttpGet]
    public IActionResult SyncLeaveToAttendance()
    {
        return View();
    }

    [Authorize(Roles = "System Admin")]
    [HttpPost]
    public async Task<IActionResult> SyncLeaveToAttendance(int leaveRequestId)
    {
        try
        {
            await _repo.SyncLeaveToAttendanceAsync(leaveRequestId);
            TempData["Success"] = "Leave synchronized with attendance system successfully.";
            return RedirectToAction("SyncLeaveToAttendance");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error syncing leave: {ex.Message}";
            return View();
        }
    }

    // Manager: View Team Attendance Summary
    [Authorize(Roles = "Line Manager")]
    [HttpGet]
    public async Task<IActionResult> TeamAttendanceSummary(DateTime? startDate, DateTime? endDate)
    {
        int managerId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
        var summary = await _repo.GetTeamAttendanceSummaryAsync(managerId, startDate, endDate);
        
        ViewBag.StartDate = startDate?.ToString("yyyy-MM-dd") ?? DateTime.Today.AddDays(-30).ToString("yyyy-MM-dd");
        ViewBag.EndDate = endDate?.ToString("yyyy-MM-dd") ?? DateTime.Today.ToString("yyyy-MM-dd");
        
        return View(summary);
    }

    // System Admin: Sync Offline Attendance
    [Authorize(Roles = "System Admin")]
    [HttpGet]
    public IActionResult SyncOfflineAttendance()
    {
        return View();
    }

    [Authorize(Roles = "System Admin")]
    [HttpPost]
    public async Task<IActionResult> SyncOfflineAttendance(
        int employeeId, int deviceId, DateTime clockTime, string type)
    {
        try
        {
            await _repo.SyncOfflineAttendanceAsync(employeeId, deviceId, clockTime, type);
            TempData["Success"] = "Offline attendance synced successfully.";
            return RedirectToAction("SyncOfflineAttendance");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error syncing offline attendance: {ex.Message}";
            return View();
        }
    }
}

