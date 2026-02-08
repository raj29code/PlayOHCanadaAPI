using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models.DTOs;

public class CreateScheduleDto
{
    [Required]
    public int SportId { get; set; }

    [Required]
    [StringLength(200, MinimumLength = 3)]
    public string Venue { get; set; } = string.Empty;

    /// <summary>
    /// Start date for the schedule or first occurrence (date only, time will be taken from StartTime)
    /// Example: "2026-01-15" for January 15, 2026
    /// </summary>
    [Required]
    public DateOnly StartDate { get; set; }

    /// <summary>
    /// Time of day when the game starts (time only, e.g., 19:00 for 7 PM)
    /// Example: "19:00:00" for 7:00 PM in the specified timezone
    /// </summary>
    [Required]
    public TimeOnly StartTime { get; set; }

    /// <summary>
    /// Time of day when the game ends (time only, e.g., 20:00 for 8 PM)
    /// Must be after StartTime
    /// Example: "20:00:00" for 8:00 PM in the specified timezone
    /// </summary>
    [Required]
    public TimeOnly EndTime { get; set; }

    /// <summary>
    /// Timezone offset from UTC in minutes (e.g., -300 for EST/UTC-5, -240 for EDT/UTC-4, 0 for UTC)
    /// Used to convert the local date/time to UTC for storage
    /// If not provided, assumes UTC
    /// Common values:
    /// - EST (Eastern Standard Time): -300
    /// - EDT (Eastern Daylight Time): -240
    /// - CST (Central Standard Time): -360
    /// - PST (Pacific Standard Time): -480
    /// </summary>
    [Range(-720, 720)]
    public int TimezoneOffsetMinutes { get; set; } = 0;

    [Required]
    [Range(1, 100)]
    public int MaxPlayers { get; set; }

    [StringLength(500)]
    public string? EquipmentDetails { get; set; }

    /// <summary>
    /// Optional recurrence settings for repeating schedules
    /// If null, creates a single schedule on StartDate
    /// </summary>
    public RecurrenceDto? Recurrence { get; set; }
}
