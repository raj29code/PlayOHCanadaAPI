# Troubleshooting: No Venues Showing in UI

## Issue

The UI shows "No venues available at this time" even though schedules with venues have been created.

## Root Cause

The venues endpoint filters to only show venues with **future** schedules:
```csharp
.Where(s => s.StartTime > DateTime.UtcNow)
```

If all schedules are in the past, no venues will be returned.

## Diagnosis Steps

### Step 1: Call the Debug Endpoint

**Browser/Postman:**
```
GET https://localhost:7063/api/schedules/venues/debug?timezoneOffsetMinutes=-300
```

**PowerShell:**
```powershell
$offset = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)
$debug = Invoke-RestMethod -Uri "https://localhost:7063/api/schedules/venues/debug?timezoneOffsetMinutes=$offset"

Write-Host "Current UTC Time: $($debug.currentTimeUtc)" -ForegroundColor Cyan
Write-Host "Your Local Time: $($debug.currentTimeLocal)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Schedules: $($debug.totalSchedules)" -ForegroundColor Yellow
Write-Host "Future Schedules: $($debug.futureSchedulesCount)" -ForegroundColor Green
Write-Host "Past Schedules: $($debug.pastSchedulesCount)" -ForegroundColor Red
Write-Host ""
Write-Host "Venues Found:" -ForegroundColor Cyan
foreach ($venue in $debug.venues) {
    Write-Host "  $($venue.name)"
    Write-Host "    Total: $($venue.totalSchedules)"
    Write-Host "    Future: $($venue.futureSchedules)"
    Write-Host "    Past: $($venue.pastSchedules)"
    Write-Host "    Oldest: $($venue.oldestSchedule)"
    Write-Host "    Newest: $($venue.newestSchedule)"
}
```

### Step 2: Interpret the Results

**Scenario 1: Total Schedules = 0**
```json
{
  "totalSchedules": 0,
  "futureSchedulesCount": 0,
  "pastSchedulesCount": 0,
  "venues": []
}
```
**Problem:** No schedules in database  
**Solution:** Create schedules (see below)

**Scenario 2: Future Schedules = 0 (All Past)**
```json
{
  "totalSchedules": 10,
  "futureSchedulesCount": 0,
  "pastSchedulesCount": 10,
  "venues": [
    {
      "name": "Tennis Court A",
      "totalSchedules": 10,
      "futureSchedules": 0,
      "pastSchedules": 10,
      "newestSchedule": "2024-01-15T19:00:00Z"
    }
  ]
}
```
**Problem:** All schedules are in the past  
**Solution:** Create future schedules

**Scenario 3: Timezone Issue**
```json
{
  "currentTimeUtc": "2026-01-29T15:00:00Z",
  "currentTimeLocal": "2026-01-29T10:00:00",
  "venues": [
    {
      "newestSchedule": "2026-01-29T14:00:00Z"
    }
  ]
}
```
**Problem:** Schedule is at 14:00 UTC, but current time is 15:00 UTC (schedule is in the past)  
**Solution:** Create schedules with future dates

## Solutions

### Solution 1: Create Future Schedules

```powershell
# Login as admin
$loginBody = @{
    email = "admin@playohcanada.com"
    password = "Admin@123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "https://localhost:7063/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"

$token = $loginResponse.token
$headers = @{
    "Authorization" = "Bearer $token"
}

# Create a schedule TOMORROW
$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")

$scheduleBody = @{
    sportId = 1
    venue = "Tennis Court A"
    startDate = $tomorrow  # TOMORROW!
    startTime = "19:00:00"
    endTime = "20:00:00"
    maxPlayers = 8
    equipmentDetails = "Bring your racket"
    timezoneOffsetMinutes = -300  # Your timezone
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://localhost:7063/api/schedules" `
    -Method Post -Headers $headers -Body $scheduleBody -ContentType "application/json"

Write-Host "? Created schedule for tomorrow" -ForegroundColor Green
```

### Solution 2: Create Recurring Future Schedules

```powershell
# Create recurring schedules for the next month
$today = (Get-Date).ToString("yyyy-MM-dd")
$nextMonth = (Get-Date).AddMonths(1).ToString("yyyy-MM-dd")

$recurringBody = @{
    sportId = 1
    venue = "Community Center"
    startDate = $today
    startTime = "18:00:00"
    endTime = "19:00:00"
    maxPlayers = 10
    equipmentDetails = "Basketball provided"
    timezoneOffsetMinutes = -300
    recurrence = @{
        isRecurring = $true
        frequency = 2  # Weekly
        daysOfWeek = @(1, 3, 5)  # Mon, Wed, Fri
        endDate = $nextMonth
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "https://localhost:7063/api/schedules" `
    -Method Post -Headers $headers -Body $recurringBody -ContentType "application/json"

Write-Host "? Created recurring schedules" -ForegroundColor Green
```

### Solution 3: Verify Venues Appear

```powershell
# Check if venues now appear
$offset = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)
$venues = Invoke-RestMethod -Uri "https://localhost:7063/api/schedules/venues?timezoneOffsetMinutes=$offset"

if ($venues.Count -gt 0) {
    Write-Host "? Found $($venues.Count) venues!" -ForegroundColor Green
    foreach ($venue in $venues) {
        Write-Host "  - $($venue.name): $($venue.scheduleCount) schedules" -ForegroundColor Gray
    }
} else {
    Write-Host "? Still no venues found" -ForegroundColor Red
}
```

## Common Issues

### Issue 1: Created Schedule is Already in the Past

**Symptom:** You create a schedule, but it doesn't appear in venues

**Cause:** Schedule's startDate/startTime combination is in the past

**Example:**
```json
{
  "startDate": "2026-01-29",
  "startTime": "08:00:00",
  "timezoneOffsetMinutes": -300
}
```

If current time is 2PM EST (19:00 UTC), and you create a schedule for 8AM EST (13:00 UTC), it's already in the past!

**Fix:** Use future dates/times:
```json
{
  "startDate": "2026-01-30",  // Tomorrow
  "startTime": "19:00:00",     // 7 PM
  "timezoneOffsetMinutes": -300
}
```

### Issue 2: Timezone Confusion

**Symptom:** Schedule shows up when you create it, but disappears from venues

**Cause:** Timezone offset is converting the schedule to the past

**Example:**
```
Created at: 2026-01-29 14:00:00 EST (19:00 UTC)
Current time: 2026-01-29 15:00:00 EST (20:00 UTC)
Schedule is in the past by 1 hour!
```

**Fix:** Always create schedules for future times:
```powershell
# Get tomorrow's date
$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")

$scheduleBody = @{
    startDate = $tomorrow  # Tomorrow ensures it's in the future
    startTime = "19:00:00"
    # ...
}
```

### Issue 3: Empty Database

**Symptom:** Debug endpoint shows totalSchedules = 0

**Cause:** No schedules have been created yet

**Fix:** Create at least one schedule (see Solution 1 above)

## Quick Test Script

Save this as `test-venue-visibility.ps1`:

```powershell
# Quick test to diagnose venue visibility issue

$baseUrl = "https://localhost:7063"

Write-Host "=== Venue Visibility Diagnostic ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check debug endpoint
Write-Host "Step 1: Checking database..." -ForegroundColor Yellow
$offset = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)
$debug = Invoke-RestMethod -Uri "$baseUrl/api/schedules/venues/debug?timezoneOffsetMinutes=$offset"

Write-Host "Current Time (UTC): $($debug.currentTimeUtc)" -ForegroundColor Gray
Write-Host "Current Time (Local): $($debug.currentTimeLocal)" -ForegroundColor Gray
Write-Host ""

# Analyze results
if ($debug.totalSchedules -eq 0) {
    Write-Host "? Problem: No schedules in database" -ForegroundColor Red
    Write-Host "Solution: Create schedules using POST /api/schedules" -ForegroundColor Yellow
    exit
}

Write-Host "? Found $($debug.totalSchedules) total schedules" -ForegroundColor Green
Write-Host "  Future: $($debug.futureSchedulesCount)" -ForegroundColor $(if ($debug.futureSchedulesCount -gt 0) { "Green" } else { "Red" })
Write-Host "  Past: $($debug.pastSchedulesCount)" -ForegroundColor Gray
Write-Host ""

if ($debug.futureSchedulesCount -eq 0) {
    Write-Host "? Problem: All schedules are in the past" -ForegroundColor Red
    Write-Host "Solution: Create schedules with future dates" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Existing venues (with past schedules):" -ForegroundColor Yellow
    foreach ($venue in $debug.venues) {
        Write-Host "  - $($venue.name): Newest schedule at $($venue.newestSchedule)" -ForegroundColor Gray
    }
    exit
}

# Step 2: Check venues endpoint
Write-Host "Step 2: Checking venues endpoint..." -ForegroundColor Yellow
$venues = Invoke-RestMethod -Uri "$baseUrl/api/schedules/venues?timezoneOffsetMinutes=$offset"

if ($venues.Count -gt 0) {
    Write-Host "? Venues endpoint working correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Available Venues:" -ForegroundColor Cyan
    foreach ($venue in $venues) {
        Write-Host "  ?? $($venue.name)" -ForegroundColor Green
        Write-Host "     Schedules: $($venue.scheduleCount)" -ForegroundColor Gray
        Write-Host "     Available: $($venue.availableSchedules)" -ForegroundColor Gray
        Write-Host "     Next Event: $($venue.nextScheduleTime)" -ForegroundColor Gray
    }
} else {
    Write-Host "? Venues endpoint returns empty (unexpected!)" -ForegroundColor Red
}
```

## Expected UI Behavior

Once you have future schedules, the UI should show:

```
Select Venue ?
  [All Venues]
  Tennis Court A (5 schedules)
  Community Center (8 schedules)
  Downtown Complex (3 schedules)
```

## Summary

### Quick Checklist

? **Check if schedules exist:** Call debug endpoint  
? **Check if schedules are future:** Look at futureSchedulesCount  
? **Create future schedules:** Use tomorrow's date  
? **Verify venues appear:** Call venues endpoint  
? **Refresh UI:** Should now show venues  

### Most Common Solution

**Create a schedule for TOMORROW:**

```javascript
// In your UI or API client
const tomorrow = new Date();
tomorrow.setDate(tomorrow.getDate() + 1);
const tomorrowStr = tomorrow.toISOString().split('T')[0];

// Create schedule
await fetch('/api/schedules', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${adminToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    sportId: 1,
    venue: "Tennis Court A",
    startDate: tomorrowStr,  // Tomorrow!
    startTime: "19:00:00",
    endTime: "20:00:00",
    maxPlayers: 8,
    timezoneOffsetMinutes: -new Date().getTimezoneOffset()
  })
});
```

---

**After creating future schedules, venues will appear in the UI!** ?
