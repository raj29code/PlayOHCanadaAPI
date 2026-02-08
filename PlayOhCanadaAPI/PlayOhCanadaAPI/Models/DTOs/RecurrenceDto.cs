using System.Text.Json.Serialization;

namespace PlayOhCanadaAPI.Models.DTOs;

public class RecurrenceDto
{
    /// <summary>
    /// Indicates if this schedule should repeat
    /// </summary>
    public bool IsRecurring { get; set; }
    
    /// <summary>
    /// Frequency of recurrence (Daily, Weekly, etc.)
    /// </summary>
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public RecurrenceFrequency? Frequency { get; set; }
    
    /// <summary>
    /// End date for the recurring schedule (date only, inclusive)
    /// Example: "2026-02-28" to end on February 28, 2026
    /// The time from StartTime/EndTime will be applied to each occurrence
    /// </summary>
    public DateOnly? EndDate { get; set; }
    
    /// <summary>
    /// Specific days of the week for Weekly/BiWeekly recurrence (e.g., [DayOfWeek.Monday, DayOfWeek.Wednesday])
    /// Sunday = 0, Monday = 1, Tuesday = 2, Wednesday = 3, Thursday = 4, Friday = 5, Saturday = 6
    /// Example: [3] for every Wednesday
    /// </summary>
    public List<DayOfWeek>? DaysOfWeek { get; set; }
    
    /// <summary>
    /// For BiWeekly or custom intervals, specify the interval count
    /// </summary>
    public int? IntervalCount { get; set; }
}

public enum RecurrenceFrequency
{
    /// <summary>
    /// Occurs every day
    /// </summary>
    Daily = 1,
    
    /// <summary>
    /// Occurs on specific days of the week (use DaysOfWeek property)
    /// </summary>
    Weekly = 2,
    
    /// <summary>
    /// Occurs every two weeks on specified days
    /// </summary>
    BiWeekly = 3,
    
    /// <summary>
    /// Occurs on the same day each month
    /// </summary>
    Monthly = 4
}
