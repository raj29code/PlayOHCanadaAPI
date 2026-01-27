namespace PlayOhCanadaAPI.Models.DTOs;

public class RecurrenceDto
{
    public bool IsRecurring { get; set; }
    
    public RecurrenceFrequency? Frequency { get; set; }
    
    public DateTime? EndDate { get; set; }
}

public enum RecurrenceFrequency
{
    Daily = 1,
    Weekly = 7,
    BiWeekly = 14,
    Monthly = 30
}
