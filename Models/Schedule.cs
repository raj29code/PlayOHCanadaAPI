using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models;

public class Schedule
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int SportId { get; set; }

    [Required]
    [StringLength(200)]
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

    [Required]
    public int CreatedByAdminId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Sport Sport { get; set; } = null!;
    public User CreatedByAdmin { get; set; } = null!;
    public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
}
