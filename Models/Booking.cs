using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models;

public class Booking
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int ScheduleId { get; set; }

    public DateTime BookingTime { get; set; } = DateTime.UtcNow;

    // For registered users
    public int? UserId { get; set; }

    // For guest users
    [StringLength(100)]
    public string? GuestName { get; set; }

    [Phone]
    [StringLength(20)]
    public string? GuestMobile { get; set; }

    // Navigation properties
    public Schedule Schedule { get; set; } = null!;
    public User? User { get; set; }
}
