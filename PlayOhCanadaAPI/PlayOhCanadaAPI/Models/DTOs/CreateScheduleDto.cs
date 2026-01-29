using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models.DTOs;

public class CreateScheduleDto
{
    [Required]
    public int SportId { get; set; }

    [Required]
    [StringLength(200, MinimumLength = 3)]
    public string Venue { get; set; } = string.Empty;

    [Required]
    public DateTime StartTime { get; set; }

    [Required]
    public DateTime EndTime { get; set; }

    [Required]
    [Range(1, 100)]
    public int MaxPlayers { get; set; }

    [StringLength(500)]
    public string? EquipmentDetails { get; set; }

    public RecurrenceDto? Recurrence { get; set; }
}
