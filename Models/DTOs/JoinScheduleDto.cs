using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models.DTOs;

public class JoinScheduleDto
{
    [Required]
    public int ScheduleId { get; set; }

    [StringLength(100, MinimumLength = 2)]
    public string? GuestName { get; set; }

    [Phone]
    [StringLength(20)]
    public string? GuestMobile { get; set; }
}
