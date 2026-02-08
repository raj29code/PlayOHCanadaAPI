# Quick Venue Visibility Diagnostic Script

$baseUrl = "https://localhost:7063"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Venue Visibility Diagnostic" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get timezone offset
$offset = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)

try {
    # Step 1: Check debug endpoint
    Write-Host "Step 1: Analyzing database..." -ForegroundColor Yellow
    Write-Host ""
    
    $debug = Invoke-RestMethod -Uri "$baseUrl/api/schedules/venues/debug?timezoneOffsetMinutes=$offset" -SkipCertificateCheck
    
    Write-Host "Current Time:" -ForegroundColor Cyan
    Write-Host "  UTC:   $($debug.currentTimeUtc)" -ForegroundColor Gray
    Write-Host "  Local: $($debug.currentTimeLocal)" -ForegroundColor Gray
    Write-Host "  Offset: $($offset) minutes" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Database Statistics:" -ForegroundColor Cyan
    Write-Host "  Total Schedules: $($debug.totalSchedules)" -ForegroundColor $(if ($debug.totalSchedules -gt 0) { "Green" } else { "Red" })
    Write-Host "  Future Schedules: $($debug.futureSchedulesCount)" -ForegroundColor $(if ($debug.futureSchedulesCount -gt 0) { "Green" } else { "Red" })
    Write-Host "  Past Schedules: $($debug.pastSchedulesCount)" -ForegroundColor Gray
    Write-Host ""
    
    # Diagnose the issue
    if ($debug.totalSchedules -eq 0) {
        Write-Host "? PROBLEM FOUND: No schedules in database" -ForegroundColor Red
        Write-Host ""
        Write-Host "Solution:" -ForegroundColor Yellow
        Write-Host "  1. Login as admin" -ForegroundColor White
        Write-Host "  2. Create at least one schedule with a future date" -ForegroundColor White
        Write-Host "  3. Use tomorrow's date to ensure it's in the future" -ForegroundColor White
        Write-Host ""
        Write-Host "Example PowerShell:" -ForegroundColor Cyan
        Write-Host '  $tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")' -ForegroundColor Gray
        Write-Host '  # Create schedule with startDate = $tomorrow' -ForegroundColor Gray
        exit
    }
    
    if ($debug.futureSchedulesCount -eq 0) {
        Write-Host "? PROBLEM FOUND: All schedules are in the past" -ForegroundColor Red
        Write-Host ""
        Write-Host "Existing Venues (with past schedules):" -ForegroundColor Yellow
        foreach ($venue in $debug.venues) {
            Write-Host "  ?? $($venue.name)" -ForegroundColor White
            Write-Host "     Total: $($venue.totalSchedules) | Future: $($venue.futureSchedules) | Past: $($venue.pastSchedules)" -ForegroundColor Gray
            Write-Host "     Oldest: $($venue.oldestSchedule)" -ForegroundColor Gray
            Write-Host "     Newest: $($venue.newestSchedule)" -ForegroundColor Gray
            Write-Host ""
        }
        Write-Host "Solution:" -ForegroundColor Yellow
        Write-Host "  1. Create new schedules with FUTURE dates" -ForegroundColor White
        Write-Host "  2. Use tomorrow or later dates" -ForegroundColor White
        Write-Host "  3. Ensure startTime is also in the future" -ForegroundColor White
        exit
    }
    
    Write-Host "? Database looks good!" -ForegroundColor Green
    Write-Host ""
    
    # Step 2: Check venues endpoint
    Write-Host "Step 2: Checking venues endpoint..." -ForegroundColor Yellow
    Write-Host ""
    
    $venues = Invoke-RestMethod -Uri "$baseUrl/api/schedules/venues?timezoneOffsetMinutes=$offset" -SkipCertificateCheck
    
    if ($venues.Count -gt 0) {
        Write-Host "? SUCCESS: Venues endpoint is working!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Available Venues ($($venues.Count)):" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($venue in $venues) {
            Write-Host "  ?? $($venue.name)" -ForegroundColor Green
            Write-Host "     Total Schedules: $($venue.scheduleCount)" -ForegroundColor Gray
            Write-Host "     Available: $($venue.availableSchedules)" -ForegroundColor Gray
            Write-Host "     Sports: $($venue.sports -join ', ')" -ForegroundColor Gray
            Write-Host "     Next Event: $($venue.nextScheduleTime)" -ForegroundColor Gray
            Write-Host ""
        }
        
        Write-Host "? Your UI should now be able to see these venues!" -ForegroundColor Green
        Write-Host ""
        Write-Host "If UI still shows 'No venues', check:" -ForegroundColor Yellow
        Write-Host "  1. Is UI calling the correct endpoint?" -ForegroundColor White
        Write-Host "  2. Is UI passing timezoneOffsetMinutes parameter?" -ForegroundColor White
        Write-Host "  3. Check browser console for errors" -ForegroundColor White
        
    } else {
        Write-Host "??  WARNING: Venues endpoint returns empty" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This is unexpected since we have future schedules." -ForegroundColor Red
        Write-Host "Please check the API logs for errors." -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Diagnostic Complete" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
} catch {
    Write-Host "? ERROR: Failed to connect to API" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. API is running (https://localhost:7063)" -ForegroundColor White
    Write-Host "  2. No firewall blocking the connection" -ForegroundColor White
    Write-Host "  3. Correct URL in script" -ForegroundColor White
}
