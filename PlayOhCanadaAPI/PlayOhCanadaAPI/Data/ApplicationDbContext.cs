using Microsoft.EntityFrameworkCore;
using PlayOhCanadaAPI.Models;

namespace PlayOhCanadaAPI.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure User entity
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.HasIndex(e => e.Email)
                    .IsUnique();

                entity.HasIndex(e => e.Phone)
                    .IsUnique()
                    .HasFilter("\"Phone\" IS NOT NULL"); // Partial index for nullable column

                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.Email)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.Phone)
                    .HasMaxLength(20);

                entity.Property(e => e.PasswordHash)
                    .IsRequired();

                entity.Property(e => e.Role)
                    .IsRequired()
                    .HasMaxLength(20)
                    .HasDefaultValue(UserRoles.User);

                entity.Property(e => e.CreatedAt)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");

                entity.Property(e => e.ExternalProvider)
                    .HasMaxLength(50);

                entity.Property(e => e.ExternalProviderId)
                    .HasMaxLength(200);
            });

        }
    }
}
