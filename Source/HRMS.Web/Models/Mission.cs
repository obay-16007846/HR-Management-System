namespace HRMS.Web.Models
{
    public class Mission
    {
        public int MissionId { get; set; }
        public string? Destination { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string? Status { get; set; }
        public int EmployeeId { get; set; }
        public int? ManagerId { get; set; }
        public string? EmployeeName { get; set; }
        public string? ManagerName { get; set; }
        public string? Description { get; set; }
        public string? Purpose { get; set; }
    }
}

