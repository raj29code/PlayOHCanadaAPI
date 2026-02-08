using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models.DTOs;

public class UpdateScheduleDto
{
    [StringLength(200, MinimumLength = 3)]
    public string? Venue { get; set; }

    /// <summary>
    /// New date for the schedule
    /// </summary>
    public DateOnly? Date { get; set; }

    /// <summary>
    /// New start time (time of day in the specified timezone)
    /// </summary>
    public TimeOnly? StartTime { get; set; }

    /// <summary>
    /// New end time (time of day in the specified timezone)
    /// Must be after StartTime if provided
    /// </summary>
    public TimeOnly? EndTime { get; set; }

    /// <summary>
    /// Timezone offset from UTC in minutes (e.g., -300 for EST, -240 for EDT)
    /// Only used when updating Date, StartTime, or EndTime
    /// If not provided, assumes UTC
    /// </summary>
    [Range(-720, 720)]
    public int TimezoneOffsetMinutes { get; set; } = 0;

    [Range(1, 100)]
    public int? MaxPlayers { get; set; }

    [StringLength(500)]
    public string? EquipmentDetails { get; set; }
}
