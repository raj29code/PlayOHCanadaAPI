using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models.DTOs;

public class UpdateScheduleDto
{
    [StringLength(200, MinimumLength = 3)]
    public string? Venue { get; set; }

    public DateTime? StartTime { get; set; }

    public DateTime? EndTime { get; set; }

    [Range(1, 100)]
    public int? MaxPlayers { get; set; }

    [StringLength(500)]
    public string? EquipmentDetails { get; set; }
}
