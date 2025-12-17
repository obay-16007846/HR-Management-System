public class Shift
{
    public int ShiftId { get; set; }
    public string? Name { get; set; }
    public string? Type { get; set; }
    public TimeSpan? StartTime { get; set; }
    public TimeSpan? EndTime { get; set; }
    public int? BreakDuration { get; set; }
    public DateTime? ShiftDate { get; set; }
    public string? Status { get; set; }
}

public class ShiftAssignment
{
    public int AssignmentId { get; set; }
    public int EmployeeId { get; set; }
    public string? EmployeeName { get; set; }
    public int ShiftId { get; set; }
    public string? ShiftName { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? Status { get; set; }
}

public class ShiftCycle
{
    public int CycleId { get; set; }
    public string? CycleName { get; set; }
    public string? Description { get; set; }
}

