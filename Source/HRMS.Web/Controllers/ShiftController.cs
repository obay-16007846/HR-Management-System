using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

[Authorize]
public class ShiftController : Controller
{
    private readonly EmployeeRepository _repo;

    public ShiftController(EmployeeRepository repo)
    {
        _repo = repo;
    }

    // System Admin: Create Shift Type
    [Authorize(Roles = "System Admin")]
    [HttpGet]
    public IActionResult CreateShiftType()
    {
        return View();
    }

    [Authorize(Roles = "System Admin")]
    [HttpPost]
    public async Task<IActionResult> CreateShiftType(
        string name, string type, TimeSpan startTime, TimeSpan endTime, 
        int breakDuration, DateTime? shiftDate, string status)
    {
        try
        {
            await _repo.CreateShiftTypeAsync(name, type, startTime, endTime, breakDuration, shiftDate, status);
            TempData["Success"] = "Shift type created successfully.";
            return RedirectToAction("ListShiftTypes");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error creating shift type: {ex.Message}";
            return View();
        }
    }

    [Authorize(Roles = "System Admin,HR Admin")]
    public async Task<IActionResult> ListShiftTypes()
    {
        var shifts = await _repo.GetAllShiftTypesAsync();
        return View(shifts);
    }

    // System Admin & Manager: Assign Shift to Employee
    [Authorize(Roles = "System Admin,Line Manager")]
    [HttpGet]
    public async Task<IActionResult> AssignShiftToEmployee(int? employeeId)
    {
        if (employeeId.HasValue)
        {
            var shifts = await _repo.GetAllShiftTypesAsync();
            ViewBag.Shifts = shifts;
            ViewBag.EmployeeId = employeeId.Value;
            return View();
        }
        
        // Show employee selection
        var employees = await _repo.GetAllEmployeesAsync();
        return View("SelectEmployeeForShift", employees);
    }

    [Authorize(Roles = "System Admin,Line Manager")]
    [HttpPost]
    public async Task<IActionResult> AssignShiftToEmployee(int employeeId, int shiftId, DateTime startDate, DateTime endDate)
    {
        try
        {
            await _repo.AssignShiftToEmployeeAsync(employeeId, shiftId, startDate, endDate);
            
            // Create notification
            await _repo.CreateNotificationAsync(
                employeeId,
                $"You have been assigned a new shift starting {startDate:yyyy-MM-dd}.",
                "Normal",
                "ShiftAssignment"
            );
            
            TempData["Success"] = "Shift assigned successfully.";
            return RedirectToAction("AssignShiftToEmployee");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error assigning shift: {ex.Message}";
            return RedirectToAction("AssignShiftToEmployee", new { employeeId });
        }
    }

    // System Admin & Manager: Assign Shift to Department
    [Authorize(Roles = "System Admin,Line Manager")]
    [HttpGet]
    public async Task<IActionResult> AssignShiftToDepartment()
    {
        var shifts = await _repo.GetAllShiftTypesAsync();
        var departments = await _repo.GetAllDepartmentsAsync();
        ViewBag.Shifts = shifts;
        ViewBag.Departments = departments;
        return View();
    }

    [Authorize(Roles = "System Admin,Line Manager")]
    [HttpPost]
    public async Task<IActionResult> AssignShiftToDepartment(int departmentId, int shiftId, DateTime startDate, DateTime endDate)
    {
        try
        {
            await _repo.AssignShiftToDepartmentAsync(departmentId, shiftId, startDate, endDate);
            TempData["Success"] = "Shift assigned to department successfully.";
            return RedirectToAction("AssignShiftToDepartment");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error assigning shift to department: {ex.Message}";
            return View();
        }
    }

    // System Admin: Create Custom/Special Shift
    [Authorize(Roles = "System Admin")]
    [HttpGet]
    public async Task<IActionResult> CreateCustomShift(int? employeeId)
    {
        if (employeeId.HasValue)
        {
            ViewBag.EmployeeId = employeeId.Value;
            return View();
        }
        
        var employees = await _repo.GetAllEmployeesAsync();
        return View("SelectEmployeeForCustomShift", employees);
    }

    [Authorize(Roles = "System Admin")]
    [HttpPost]
    public async Task<IActionResult> CreateCustomShift(
        int employeeId, string shiftName, string shiftType, 
        TimeSpan startTime, TimeSpan endTime, int breakDuration, 
        DateTime startDate, DateTime endDate)
    {
        try
        {
            await _repo.CreateCustomShiftAsync(employeeId, shiftName, shiftType, startTime, endTime, breakDuration, startDate, endDate);
            
            await _repo.CreateNotificationAsync(
                employeeId,
                $"You have been assigned a custom shift: {shiftName} starting {startDate:yyyy-MM-dd}.",
                "Normal",
                "ShiftAssignment"
            );
            
            TempData["Success"] = "Custom shift created and assigned successfully.";
            return RedirectToAction("CreateCustomShift");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error creating custom shift: {ex.Message}";
            return View();
        }
    }

    // HR Admin: Configure Split Shift
    [Authorize(Roles = "HR Admin")]
    [HttpGet]
    public IActionResult ConfigureSplitShift()
    {
        return View();
    }

    [Authorize(Roles = "HR Admin")]
    [HttpPost]
    public async Task<IActionResult> ConfigureSplitShift(
        string shiftName, TimeSpan firstStart, TimeSpan firstEnd, 
        TimeSpan secondStart, TimeSpan secondEnd, int breakDuration)
    {
        try
        {
            await _repo.ConfigureSplitShiftAsync(shiftName, firstStart, firstEnd, secondStart, secondEnd, breakDuration);
            TempData["Success"] = "Split shift configured successfully.";
            return RedirectToAction("ListShiftTypes");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error configuring split shift: {ex.Message}";
            return View();
        }
    }

    // System Admin: Assign Rotational Shift
    [Authorize(Roles = "System Admin")]
    [HttpGet]
    public async Task<IActionResult> AssignRotationalShift(int? employeeId)
    {
        if (employeeId.HasValue)
        {
            ViewBag.EmployeeId = employeeId.Value;
            return View();
        }
        
        var employees = await _repo.GetAllEmployeesAsync();
        return View("SelectEmployeeForRotationalShift", employees);
    }

    [Authorize(Roles = "System Admin")]
    [HttpPost]
    public async Task<IActionResult> AssignRotationalShift(
        int employeeId, int shiftCycle, DateTime startDate, DateTime endDate, string status)
    {
        try
        {
            await _repo.AssignRotationalShiftAsync(employeeId, shiftCycle, startDate, endDate, status);
            
            await _repo.CreateNotificationAsync(
                employeeId,
                $"You have been assigned a rotational shift starting {startDate:yyyy-MM-dd}.",
                "Normal",
                "ShiftAssignment"
            );
            
            TempData["Success"] = "Rotational shift assigned successfully.";
            return RedirectToAction("AssignRotationalShift");
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Error assigning rotational shift: {ex.Message}";
            return View();
        }
    }

    // Employee: View My Shifts
    [Authorize]
    public async Task<IActionResult> MyShifts()
    {
        int employeeId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
        var shifts = await _repo.GetEmployeeShiftsAsync(employeeId);
        return View(shifts);
    }

    // System Admin: View All Shift Assignments
    [Authorize(Roles = "System Admin")]
    public async Task<IActionResult> ViewAllShiftAssignments()
    {
        var assignments = await _repo.GetAllShiftAssignmentsAsync();
        return View(assignments);
    }
}

