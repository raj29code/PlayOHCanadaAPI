using System.ComponentModel.DataAnnotations;

namespace PlayOhCanadaAPI.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [StringLength(100)]
        public string Email { get; set; } = string.Empty;

        [Phone]
        [StringLength(20)]
        public string? Phone { get; set; }

        [Required]
        public string PasswordHash { get; set; } = string.Empty;

        [Required]
        [StringLength(20)]
        public string Role { get; set; } = "User";

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? LastLoginAt { get; set; }

        // Future: For SSO integration
        public string? ExternalProvider { get; set; }
        public string? ExternalProviderId { get; set; }

        // Future: For phone verification
        public bool IsPhoneVerified { get; set; } = false;
        public bool IsEmailVerified { get; set; } = false;
    }

    public static class UserRoles
    {
        public const string Admin = "Admin";
        public const string User = "User";
    }
}
