public class Notification
{
    public int NotificationId { get; set; }
    public string? MessageContent { get; set; }
    public DateTime Timestamp { get; set; }
    public bool ReadStatus { get; set; }
    public string? Urgency { get; set; }
    public string? NotificationType { get; set; }
}

