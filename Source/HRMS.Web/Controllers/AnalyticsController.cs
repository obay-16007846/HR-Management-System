using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRMS.Web.Controllers
{
    [Authorize(Roles = "HR Admin")]
    public class AnalyticsController : Controller
    {
        private readonly EmployeeRepository _repo;

        public AnalyticsController(EmployeeRepository repo)
        {
            _repo = repo;
        }

        public async Task<IActionResult> DepartmentStatistics()
        {
            var stats = await _repo.GetDepartmentEmployeeStatsAsync();
            return View(stats);
        }

        public async Task<IActionResult> ComplianceReport()
        {
            var report = await _repo.GetComplianceReportAsync();
            return View(report);
        }

        public async Task<IActionResult> DiversityReport()
        {
            var report = await _repo.GetDiversityReportAsync();
            return View(report);
        }
    }
}

