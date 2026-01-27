using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models;

public class Sport
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [StringLength(500)]
    public string? IconUrl { get; set; }

    // Navigation property
    public ICollection<Schedule> Schedules { get; set; } = new List<Schedule>();
}
