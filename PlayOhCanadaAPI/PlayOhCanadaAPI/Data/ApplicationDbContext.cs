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
        public DbSet<Sport> Sports { get; set; }
        public DbSet<Schedule> Schedules { get; set; }
        public DbSet<Booking> Bookings { get; set; }
        public DbSet<RevokedToken> RevokedTokens { get; set; }

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

            // Configure Sport entity
            modelBuilder.Entity<Sport>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.HasIndex(e => e.Name)
                    .IsUnique();
            });

            // Configure Schedule entity
            modelBuilder.Entity<Schedule>(entity =>
            {
                entity.HasKey(e => e.Id);

                entity.HasIndex(e => new { e.SportId, e.StartTime });

                entity.HasOne(e => e.Sport)
                    .WithMany(s => s.Schedules)
                    .HasForeignKey(e => e.SportId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.CreatedByAdmin)
                    .WithMany()
                    .HasForeignKey(e => e.CreatedByAdminId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.Property(e => e.CreatedAt)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
            });

            // Configure Booking entity
            modelBuilder.Entity<Booking>(entity =>
            {
                entity.HasKey(e => e.Id);

                // Unique constraint: A user cannot book the same schedule twice
                entity.HasIndex(e => new { e.ScheduleId, e.UserId })
                    .IsUnique()
                    .HasFilter("\"UserId\" IS NOT NULL");

                entity.HasOne(e => e.Schedule)
                    .WithMany(s => s.Bookings)
                    .HasForeignKey(e => e.ScheduleId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.Property(e => e.BookingTime)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");

                // Validation: Either UserId or GuestName must be present
                entity.HasCheckConstraint(
                    "CK_Booking_UserOrGuest",
                    "\"UserId\" IS NOT NULL OR \"GuestName\" IS NOT NULL"
                );
            });

            // Configure RevokedToken entity
            modelBuilder.Entity<RevokedToken>(entity =>
            {
                entity.HasKey(e => e.Id);

                entity.HasIndex(e => e.Token);

                entity.HasIndex(e => e.ExpiresAt);

                entity.Property(e => e.Token)
                    .IsRequired()
                    .HasMaxLength(500);

                entity.Property(e => e.RevokedAt)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
            });
        }
    }
}
