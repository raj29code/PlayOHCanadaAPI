# Schedule Cleanup Service - Documentation

## Overview

The **Schedule Cleanup Service** is a background service that automatically deletes old schedules from the database to save storage space and improve query performance.

## How It Works

### Automatic Cleanup

- **Runs daily** (configurable)
- **Deletes schedules** that ended more than 7 days ago (configurable)
- **Cascade deletes bookings** associated with those schedules
- **Logs all operations** for monitoring and auditing

### Cleanup Logic

```
Current Time: Feb 7, 2026
Retention: 7 days
Cutoff Date: Jan 31, 2026

Schedules to delete: All schedules where EndTime < Jan 31, 2026
```

## Configuration

### Default Settings

If not configured, the service uses these defaults:
- **Retention Period:** 7 days
- **Cleanup Interval:** 24 hours (runs once per day)

### Custom Configuration

Add to `appsettings.json`:

```json
{
  "ScheduleCleanup": {
    "RetentionDays": 7,
    "CleanupIntervalHours": 24
  }
}
```

### Configuration Options

| Setting | Description | Default | Range |
|---------|-------------|---------|-------|
| `RetentionDays` | Days to keep schedules after they end | 7 | 1-365 |
| `CleanupIntervalHours` | Hours between cleanup runs | 24 | 1-168 |

### Environment-Specific Configuration

**Development** (`appsettings.Development.json`):
```json
{
  "ScheduleCleanup": {
    "RetentionDays": 3,
    "CleanupIntervalHours": 6
  }
}
```

**Production** (`appsettings.json`):
```json
{
  "ScheduleCleanup": {
    "RetentionDays": 30,
    "CleanupIntervalHours": 24
  }
}
```

## What Gets Deleted

### Schedules

All schedules where:
```sql
EndTime < (CurrentUtcTime - RetentionDays)
```

### Associated Bookings

All bookings for deleted schedules are **automatically deleted** due to cascade delete on the foreign key relationship.

### Example

**Scenario:**
- Current Date: February 7, 2026
- Retention: 7 days
- Cutoff: January 31, 2026

**Schedules to Delete:**
- Tennis on Jan 25, 2026 (8:00-9:00 PM) ? Deleted
- Basketball on Jan 30, 2026 (7:00-8:00 PM) ? Deleted
- Soccer on Feb 1, 2026 (6:00-7:00 PM) ? Kept (within 7 days)
- Volleyball on Feb 5, 2026 (5:00-6:00 PM) ? Kept (within 7 days)

## Logging

### Log Levels

The service logs at different levels:

**Information:**
```
Schedule Cleanup Service is starting. Retention: 7 days, Interval: 24 hours
Starting schedule cleanup task...
? Cleaned up 15 schedules and 42 bookings that ended before 2026-01-31 00:00:00
```

**Error:**
```
Error occurred during schedule cleanup: [Exception details]
```

### Configure Logging

In `appsettings.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "PlayOhCanadaAPI.Services.ScheduleCleanupService": "Information"
    }
  }
}
```

### Log Examples

**Startup:**
```
info: PlayOhCanadaAPI.Services.ScheduleCleanupService[0]
      Schedule Cleanup Service is starting. Retention: 7 days, Interval: 24 hours
```

**Successful Cleanup:**
```
info: PlayOhCanadaAPI.Services.ScheduleCleanupService[0]
      Starting schedule cleanup task...
info: PlayOhCanadaAPI.Services.ScheduleCleanupService[0]
      ? Cleaned up 15 schedules and 42 bookings that ended before 2026-01-31 00:00:00
```

**No Schedules to Clean:**
```
info: PlayOhCanadaAPI.Services.ScheduleCleanupService[0]
      No old schedules found to clean up (cutoff: 2026-01-31 00:00:00).
```

**Error:**
```
fail: PlayOhCanadaAPI.Services.ScheduleCleanupService[0]
      Error occurred during schedule cleanup.
      System.Exception: Database connection failed...
```

## Monitoring

### Check Service Status

The service starts automatically with the application. Check logs for:

```
Schedule Cleanup Service is starting. Retention: 7 days, Interval: 24 hours
```

### Monitor Cleanup Operations

Look for these log entries every 24 hours (or configured interval):

```
Starting schedule cleanup task...
? Cleaned up X schedules and Y bookings that ended before [date]
```

### Health Check (Optional)

You can add a health check endpoint to monitor the service:

```csharp
builder.Services.AddHealthChecks()
    .AddCheck<ScheduleCleanupHealthCheck>("schedule_cleanup");
```

## Performance Impact

### Resource Usage

- **CPU:** Minimal (runs once per day)
- **Memory:** Low (processes in batches)
- **Database:** DELETE operations on old records
- **I/O:** Negligible

### Query Performance

**Before Cleanup:**
```sql
SELECT * FROM Schedules WHERE StartTime > NOW()
-- Scans 10,000+ records including old ones
```

**After Cleanup:**
```sql
SELECT * FROM Schedules WHERE StartTime > NOW()
-- Scans only relevant records (e.g., 500)
```

### Database Size

**Example Impact:**
- Average schedule size: ~500 bytes
- Average booking size: ~200 bytes
- 1000 old schedules with 3 bookings each:
  - Schedules: 1000 × 500 bytes = 500 KB
  - Bookings: 3000 × 200 bytes = 600 KB
  - **Total saved: ~1.1 MB per cleanup**

For a busy system:
- 100 schedules/day × 7 days retention = 700 active schedules
- Without cleanup: 36,500 schedules/year (~18 MB)
- With cleanup: 700 schedules (~350 KB)

## Safety Features

### 1. Graceful Shutdown

The service responds to application shutdown signals:

```csharp
protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
    while (!stoppingToken.IsCancellationRequested)
    {
        // Cleanup logic
        await Task.Delay(_cleanupInterval, stoppingToken);
    }
}
```

### 2. Error Handling

Exceptions don't crash the service:

```csharp
try
{
    await CleanupOldSchedulesAsync(stoppingToken);
}
catch (Exception ex)
{
    _logger.LogError(ex, "Error occurred during schedule cleanup.");
}
```

The service continues running and tries again on the next interval.

### 3. Database Transaction

All deletes happen in a single transaction:

```csharp
context.Schedules.RemoveRange(oldSchedules);
await context.SaveChangesAsync(cancellationToken);
```

If the operation fails, no data is deleted.

### 4. Only Ended Schedules

The service only deletes schedules that have already ended:

```csharp
Where(s => s.EndTime < cutoffDate)
```

Active or future schedules are never touched.

## Manual Cleanup

If you need to manually trigger cleanup:

### Option 1: Restart Application

The service runs cleanup 1 minute after startup:

```bash
dotnet run
```

### Option 2: Direct Database Query

For emergency cleanup:

```sql
-- Preview what will be deleted
SELECT COUNT(*) 
FROM "Schedules" 
WHERE "EndTime" < NOW() - INTERVAL '7 days';

-- Delete old schedules (be careful!)
DELETE FROM "Schedules" 
WHERE "EndTime" < NOW() - INTERVAL '7 days';
```

?? **Warning:** Manual database operations bypass logging and error handling.

### Option 3: Create Admin Endpoint (Future)

Add an admin-only endpoint to trigger cleanup:

```csharp
[HttpPost("admin/cleanup-schedules")]
[Authorize(Roles = UserRoles.Admin)]
public async Task<IActionResult> TriggerCleanup()
{
    // Trigger cleanup manually
    return Ok("Cleanup triggered");
}
```

## Troubleshooting

### Issue: Service Not Running

**Check logs for:**
```
Schedule Cleanup Service is starting...
```

**Solution:** Ensure service is registered in `Program.cs`:
```csharp
builder.Services.AddHostedService<ScheduleCleanupService>();
```

### Issue: Schedules Not Being Deleted

**Check:**
1. Retention period configuration
2. Are schedules actually older than retention period?
3. Check logs for errors

**Verify:**
```sql
SELECT COUNT(*), MAX("EndTime") 
FROM "Schedules" 
WHERE "EndTime" < NOW() - INTERVAL '7 days';
```

### Issue: Database Errors

**Common causes:**
- Connection timeout
- Transaction deadlock
- Insufficient permissions

**Solution:** Check error logs and database connectivity.

### Issue: High CPU Usage

**Cause:** Too frequent cleanup or too many records

**Solution:**
1. Increase `CleanupIntervalHours`
2. Adjust retention period
3. Add batch processing

## Best Practices

### ? DO:

1. **Monitor logs** regularly
2. **Adjust retention** based on business needs
3. **Run cleanup during low-traffic hours**
4. **Keep backups** before first deployment
5. **Test in development** first

### ? DON'T:

1. **Don't set retention < 1 day** (too aggressive)
2. **Don't set interval < 1 hour** (unnecessary load)
3. **Don't disable cascade delete** on bookings
4. **Don't manually delete schedules** without considering bookings

## Configuration Examples

### Minimal Cleanup (Development)

```json
{
  "ScheduleCleanup": {
    "RetentionDays": 1,
    "CleanupIntervalHours": 1
  }
}
```

**Use case:** Testing, rapid iteration

### Standard Cleanup (Production)

```json
{
  "ScheduleCleanup": {
    "RetentionDays": 7,
    "CleanupIntervalHours": 24
  }
}
```

**Use case:** Most applications

### Extended Retention (Reporting)

```json
{
  "ScheduleCleanup": {
    "RetentionDays": 90,
    "CleanupIntervalHours": 24
  }
}
```

**Use case:** Need historical data for analytics

### Aggressive Cleanup (High Volume)

```json
{
  "ScheduleCleanup": {
    "RetentionDays": 3,
    "CleanupIntervalHours": 12
  }
}
```

**Use case:** Very high schedule volume, limited storage

## Future Enhancements

### 1. Archiving

Instead of deleting, move to archive table:

```csharp
// Archive before delete
await context.ArchivedSchedules.AddRangeAsync(oldSchedules);
await context.SaveChangesAsync();
```

### 2. Selective Cleanup

Only delete schedules with no bookings:

```csharp
.Where(s => s.EndTime < cutoffDate && s.Bookings.Count == 0)
```

### 3. Batch Processing

Process large deletions in batches:

```csharp
const int batchSize = 1000;
var hasMore = true;

while (hasMore)
{
    var batch = await context.Schedules
        .Where(s => s.EndTime < cutoffDate)
        .Take(batchSize)
        .ToListAsync();
        
    if (!batch.Any())
    {
        hasMore = false;
        break;
    }
    
    context.Schedules.RemoveRange(batch);
    await context.SaveChangesAsync();
}
```

### 4. Metrics

Track cleanup statistics:

```csharp
// Track total deleted over time
_metrics.RecordSchedulesDeleted(oldSchedules.Count);
_metrics.RecordBookingsDeleted(totalBookings);
```

## Summary

? **Automatic cleanup** runs daily
? **Configurable retention** (default 7 days)
? **Safe deletion** with error handling
? **Comprehensive logging** for monitoring
? **Zero maintenance** required
? **Database space savings** for long-running systems

The Schedule Cleanup Service ensures your database stays lean and performant by automatically removing old, irrelevant data! ???
