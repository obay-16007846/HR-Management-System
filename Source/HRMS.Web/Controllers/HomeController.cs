using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using HRMS.Web.Models;
using Microsoft.AspNetCore.Authorization;

namespace HRMS.Web.Controllers;
[Authorize]
public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;

    public HomeController(ILogger<HomeController> logger)
    {
        _logger = logger;
    }

    public IActionResult Index()
    {
        // Redirect authenticated users to the dashboard
        if (User.Identity != null && User.Identity.IsAuthenticated)
        {
            return RedirectToAction("LoginSuccess", "Account");
        }
        // If not authenticated, redirect to login
        return RedirectToAction("Login", "Account");
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
