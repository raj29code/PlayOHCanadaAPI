using Microsoft.EntityFrameworkCore;
using PlayOhCanadaAPI.Data;

namespace PlayOhCanadaAPI.Services;

// TODO: FUTURE ENHANCEMENT - Move this cleanup service to Azure Function or AWS Lambda
// Benefits:
// - Separate from main API (better separation of concerns)
// - Can run on schedule without keeping API running
// - Cost-effective (serverless, pay-per-execution)
// - Easier scaling and monitoring
// - No impact on API performance
// Implementation options:
// 1. Azure Function with Timer Trigger (cron schedule)
// 2. AWS Lambda with EventBridge (cron schedule)
// 3. Azure Durable Functions for more complex workflows
// Migration steps:
// - Extract cleanup logic to standalone function
// - Configure database connection in function
// - Set up timer trigger (e.g., 0 0 2 * * * for 2 AM daily)
// - Add monitoring and alerting
// - Remove BackgroundService from API

public class ScheduleCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ScheduleCleanupService> _logger;
    private readonly IConfiguration _configuration;
    private readonly TimeSpan _cleanupInterval;
    private readonly int _retentionDays;

    public ScheduleCleanupService(
        IServiceProvider serviceProvider,
        ILogger<ScheduleCleanupService> logger,
        IConfiguration configuration)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _configuration = configuration;
        
        // Read configuration or use defaults
        _retentionDays = _configuration.GetValue<int>("ScheduleCleanup:RetentionDays", 7);
        var cleanupIntervalHours = _configuration.GetValue<int>("ScheduleCleanup:CleanupIntervalHours", 24);
        _cleanupInterval = TimeSpan.FromHours(cleanupIntervalHours);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation(
            "Schedule Cleanup Service is starting. Retention: {RetentionDays} days, Interval: {IntervalHours} hours",
            _retentionDays,
            _cleanupInterval.TotalHours);

        // Wait a bit before first cleanup (give app time to fully start)
        await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CleanupOldSchedulesAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred during schedule cleanup.");
            }

            // Wait for the next cleanup interval
            try
            {
                await Task.Delay(_cleanupInterval, stoppingToken);
            }
            catch (TaskCanceledException)
            {
                // Expected when application is shutting down
                break;
            }
        }
    }

    // TODO: Extract this method for Azure Function/Lambda migration
    // This core cleanup logic can be reused in serverless function
    private async Task CleanupOldSchedulesAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Starting schedule cleanup task...");

        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        // Calculate the cutoff date
        var cutoffDate = DateTime.UtcNow.AddDays(-_retentionDays);

        // Find schedules that ended more than X days ago
        var oldSchedules = await context.Schedules
            .Include(s => s.Bookings)
            .Where(s => s.EndTime < cutoffDate)
            .ToListAsync(cancellationToken);

        if (!oldSchedules.Any())
        {
            _logger.LogInformation("No old schedules found to clean up (cutoff: {CutoffDate}).", cutoffDate);
            return;
        }

        var totalBookings = oldSchedules.Sum(s => s.Bookings.Count);

        // Delete the schedules (bookings will be cascade deleted due to foreign key relationship)
        context.Schedules.RemoveRange(oldSchedules);
        await context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "? Cleaned up {ScheduleCount} schedules and {BookingCount} bookings that ended before {CutoffDate}",
            oldSchedules.Count,
            totalBookings,
            cutoffDate);
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Schedule Cleanup Service is stopping.");
        await base.StopAsync(cancellationToken);
    }
}
