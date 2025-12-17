public class Leave
{
    public int LeaveId { get; set; }
    public string? LeaveType { get; set; }
    public string? LeaveDescription { get; set; }
}

public class LeaveRequest
{
    public int RequestId { get; set; }
    public int EmployeeId { get; set; }
    public string? EmployeeName { get; set; }
    public int LeaveId { get; set; }
    public string? LeaveType { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public int Duration { get; set; }
    public string? Justification { get; set; }
    public string? Status { get; set; }
    public string? ApprovalTiming { get; set; }
    public DateTime? SubmittedDate { get; set; }
    public List<LeaveDocument>? Documents { get; set; }
}

public class LeaveEntitlement
{
    public int EmployeeId { get; set; }
    public string? EmployeeName { get; set; }
    public int LeaveTypeId { get; set; }
    public string? LeaveType { get; set; }
    public decimal Entitlement { get; set; }
    public decimal Used { get; set; }
    public decimal Remaining { get; set; }
}

public class LeaveDocument
{
    public int DocumentId { get; set; }
    public int LeaveRequestId { get; set; }
    public string? FilePath { get; set; }
    public string? FileName { get; set; }
    public DateTime? UploadedAt { get; set; }
}

