public class Attendance
{
    public int AttendanceId { get; set; }
    public int EmployeeId { get; set; }
    public string? EmployeeName { get; set; }
    public int? ShiftId { get; set; }
    public string? ShiftName { get; set; }
    public DateTime? EntryTime { get; set; }
    public DateTime? ExitTime { get; set; }
    public int? Duration { get; set; }
    public string? LoginMethod { get; set; }
    public string? LogoutMethod { get; set; }
    public string? Status { get; set; }
}

public class AttendanceCorrectionRequest
{
    public int RequestId { get; set; }
    public int EmployeeId { get; set; }
    public string? EmployeeName { get; set; }
    public DateTime Date { get; set; }
    public string? CorrectionType { get; set; }
    public string? Reason { get; set; }
    public string? Status { get; set; }
    public int? RecordedBy { get; set; }
}

public class TeamAttendanceSummary
{
    public int EmployeeId { get; set; }
    public string? EmployeeName { get; set; }
    public DateTime Date { get; set; }
    public DateTime? EntryTime { get; set; }
    public DateTime? ExitTime { get; set; }
    public int? Duration { get; set; }
    public string? Status { get; set; }
}

