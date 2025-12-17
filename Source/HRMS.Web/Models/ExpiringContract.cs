public class ExpiringContract
{
    public int EmployeeId { get; set; }
    public int ContractId { get; set; }
    public string? FullName { get; set; }
    public string? Email { get; set; }
    public string? ContractType { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string? CurrentState { get; set; }
}

