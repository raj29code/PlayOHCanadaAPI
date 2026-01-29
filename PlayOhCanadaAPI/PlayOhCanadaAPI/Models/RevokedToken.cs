using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models
{
    public class RevokedToken
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(500)]
        public string Token { get; set; } = string.Empty;

        [Required]
        public int UserId { get; set; }

        [Required]
        public DateTime RevokedAt { get; set; } = DateTime.UtcNow;

        [Required]
        public DateTime ExpiresAt { get; set; }
    }
}
