using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace HRMS.Web.Controllers
{
    [Authorize(Roles = "System Admin")]
    public class HierarchyController : Controller
    {
        private readonly EmployeeRepository _repo;

        public HierarchyController(EmployeeRepository repo)
        {
            _repo = repo;
        }

        public async Task<IActionResult> ViewHierarchy()
        {
            var hierarchy = await _repo.GetOrganizationalHierarchyAsync();
            return View(hierarchy);
        }

        [HttpGet]
        public async Task<IActionResult> ReassignEmployee(int id)
        {
            var employee = await _repo.GetEmployeeByIdAsync(id);
            if (employee == null)
                return NotFound();

            var departments = await _repo.GetAllDepartmentsAsync();
            var managers = await _repo.GetAllEmployeesAsync();

            ViewBag.Employee = employee;
            ViewBag.Departments = departments;
            ViewBag.Managers = managers;

            return View();
        }

        [HttpPost]
        public async Task<IActionResult> ReassignEmployee(int employeeId, int? departmentId, int? managerId)
        {
            await _repo.ReassignEmployeeHierarchyAsync(employeeId, departmentId, managerId);
            TempData["Success"] = "Employee reassigned successfully";
            return RedirectToAction("ViewHierarchy");
        }
    }
}

