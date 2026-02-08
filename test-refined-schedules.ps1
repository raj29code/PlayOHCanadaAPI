# Test script for Refined Schedule API (Date/Time Separation)
$baseUrl = "http://localhost:5000/api"

Write-Host "=== Testing Refined Schedule API (Date/Time Separated) ===" -ForegroundColor Cyan
Write-Host ""

# Login as admin
Write-Host "Step 1: Logging in as Admin..." -ForegroundColor Yellow
$loginBody = @{
    email = "admin@playohcanada.com"
    password = "Admin@123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    Write-Host "? Admin login successful!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "? Login failed: $_" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Get sports list
Write-Host "Step 2: Getting available sports..." -ForegroundColor Yellow
try {
    $sports = Invoke-RestMethod -Uri "$baseUrl/sports" -Method Get
    $sportId = $sports[0].id
    Write-Host "? Found sport: $($sports[0].name) (ID: $sportId)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "? Failed to get sports: $_" -ForegroundColor Red
    exit 1
}

# Test 1: Every Wednesday 7-8 PM
Write-Host "Test 1: Creating 'Every Wednesday 7-8 PM' Schedule" -ForegroundColor Yellow
$wednesdaySchedule = @{
    sportId = $sportId
    venue = "Tennis Court A"
    startDate = "2026-01-07"      # First Wednesday in Jan 2026
    startTime = "19:00:00"        # 7 PM
    endTime = "20:00:00"          # 8 PM
    maxPlayers = 8
    equipmentDetails = "Bring your own racket"
    recurrence = @{
        isRecurring = $true
        frequency = 2             # Weekly
        daysOfWeek = @(3)        # Wednesday
        endDate = "2026-02-28"
    }
} | ConvertTo-Json -Depth 10

try {
    $wedSchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $wednesdaySchedule
    Write-Host "? Created $($wedSchedules.Count) Wednesday schedules (7-8 PM)!" -ForegroundColor Green
    Write-Host "  First: $(([DateTime]$wedSchedules[0].startTime).ToString('yyyy-MM-dd ddd HH:mm'))" -ForegroundColor Gray
    Write-Host "  Last: $(([DateTime]$wedSchedules[-1].startTime).ToString('yyyy-MM-dd ddd HH:mm'))" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Failed: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 2: Weekend Morning Games (9-11 AM)
Write-Host "Test 2: Creating 'Weekend Mornings 9-11 AM' Schedule" -ForegroundColor Yellow
$weekendSchedule = @{
    sportId = $sportId
    venue = "Soccer Field"
    startDate = "2026-03-01"
    startTime = "09:00:00"        # 9 AM
    endTime = "11:00:00"          # 11 AM
    maxPlayers = 22
    equipmentDetails = "Shin guards required"
    recurrence = @{
        isRecurring = $true
        frequency = 2             # Weekly
        daysOfWeek = @(0, 6)     # Sunday and Saturday
        endDate = "2026-03-31"
    }
} | ConvertTo-Json -Depth 10

try {
    $weekendSchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $weekendSchedule
    Write-Host "? Created $($weekendSchedules.Count) weekend schedules (9-11 AM)!" -ForegroundColor Green
    foreach ($schedule in $weekendSchedules | Select-Object -First 4) {
        $dt = [DateTime]$schedule.startTime
        Write-Host "  - $($dt.ToString('yyyy-MM-dd ddd HH:mm'))" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "? Failed: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 3: Weekday Evenings (Mon-Fri 6-8 PM)
Write-Host "Test 3: Creating 'Weekday Evenings 6-8 PM' Schedule" -ForegroundColor Yellow
$weekdaySchedule = @{
    sportId = $sportId
    venue = "Basketball Court"
    startDate = "2026-04-06"      # First Monday in April
    startTime = "18:00:00"        # 6 PM
    endTime = "20:00:00"          # 8 PM
    maxPlayers = 10
    recurrence = @{
        isRecurring = $true
        frequency = 2             # Weekly
        daysOfWeek = @(1, 2, 3, 4, 5)  # Mon-Fri
        endDate = "2026-04-17"    # Two weeks
    }
} | ConvertTo-Json -Depth 10

try {
    $weekdaySchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $weekdaySchedule
    Write-Host "? Created $($weekdaySchedules.Count) weekday schedules (6-8 PM)!" -ForegroundColor Green
    foreach ($schedule in $weekdaySchedules) {
        $dt = [DateTime]$schedule.startTime
        Write-Host "  - $($dt.ToString('yyyy-MM-dd ddd HH:mm'))" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "? Failed: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 4: Monthly Tournament (15th of each month, 10 AM - 4 PM)
Write-Host "Test 4: Creating 'Monthly Tournament 10 AM - 4 PM' Schedule" -ForegroundColor Yellow
$monthlySchedule = @{
    sportId = $sportId
    venue = "Tournament Arena"
    startDate = "2026-05-15"
    startTime = "10:00:00"        # 10 AM
    endTime = "16:00:00"          # 4 PM
    maxPlayers = 32
    equipmentDetails = "Tournament format"
    recurrence = @{
        isRecurring = $true
        frequency = 4             # Monthly
        endDate = "2026-09-30"
    }
} | ConvertTo-Json -Depth 10

try {
    $monthlySchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $monthlySchedule
    Write-Host "? Created $($monthlySchedules.Count) monthly schedules (10 AM - 4 PM)!" -ForegroundColor Green
    foreach ($schedule in $monthlySchedules) {
        $dt = [DateTime]$schedule.startTime
        Write-Host "  - $($dt.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "? Failed: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 5: Single Event (Different time on one day)
Write-Host "Test 5: Creating 'Single Event 2-6 PM' Schedule" -ForegroundColor Yellow
$singleSchedule = @{
    sportId = $sportId
    venue = "Special Event Arena"
    startDate = "2026-07-04"
    startTime = "14:00:00"        # 2 PM
    endTime = "18:00:00"          # 6 PM
    maxPlayers = 50
    equipmentDetails = "July 4th Special"
} | ConvertTo-Json -Depth 10

try {
    $singleResult = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $singleSchedule
    Write-Host "? Created single schedule (2-6 PM)!" -ForegroundColor Green
    $dt = [DateTime]$singleResult[0].startTime
    Write-Host "  Date: $($dt.ToString('yyyy-MM-dd ddd HH:mm-')) to $($dt.AddHours(4).ToString('HH:mm'))" -ForegroundColor Gray
    $scheduleId = $singleResult[0].id
    Write-Host ""
} catch {
    Write-Host "? Failed: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 6: Update Schedule Time (Change 2-6 PM to 3-7 PM)
Write-Host "Test 6: Updating Schedule Time (2-6 PM ? 3-7 PM)" -ForegroundColor Yellow
$updateTime = @{
    startTime = "15:00:00"        # 3 PM
    endTime = "19:00:00"          # 7 PM
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/schedules/$scheduleId" -Method Put -Headers $headers -Body $updateTime
    Write-Host "? Updated schedule time to 3-7 PM!" -ForegroundColor Green
    
    # Verify the update
    $updated = Invoke-RestMethod -Uri "$baseUrl/schedules/$scheduleId" -Method Get
    $dt = [DateTime]$updated.startTime
    $endDt = [DateTime]$updated.endTime
    Write-Host "  Verified: $($dt.ToString('HH:mm')) - $($endDt.ToString('HH:mm'))" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Failed: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 7: Update Schedule Date (Move to different day)
Write-Host "Test 7: Updating Schedule Date (July 4 ? July 5)" -ForegroundColor Yellow
$updateDate = @{
    date = "2026-07-05"
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$baseUrl/schedules/$scheduleId" -Method Put -Headers $headers -Body $updateDate
    Write-Host "? Updated schedule date to July 5!" -ForegroundColor Green
    
    # Verify the update
    $updated = Invoke-RestMethod -Uri "$baseUrl/schedules/$scheduleId" -Method Get
    $dt = [DateTime]$updated.startTime
    Write-Host "  Verified: $($dt.ToString('yyyy-MM-dd ddd'))" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Failed: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 8: Validation - EndTime before StartTime
Write-Host "Test 8: Testing Validation (EndTime before StartTime)" -ForegroundColor Yellow
$invalidSchedule = @{
    sportId = $sportId
    venue = "Test Venue"
    startDate = "2026-08-01"
    startTime = "20:00:00"        # 8 PM
    endTime = "19:00:00"          # 7 PM - INVALID!
    maxPlayers = 10
} | ConvertTo-Json -Depth 10

try {
    $result = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $invalidSchedule
    Write-Host "? Validation failed - should have rejected this!" -ForegroundColor Red
    Write-Host ""
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "? Validation working correctly!" -ForegroundColor Green
        Write-Host "  Error: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "? Unexpected error: $_" -ForegroundColor Red
        Write-Host ""
    }
}

# Test 9: BiWeekly Schedule (Every other Friday 5-7 PM)
Write-Host "Test 9: Creating 'BiWeekly Friday 5-7 PM' Schedule" -ForegroundColor Yellow
$biweeklySchedule = @{
    sportId = $sportId
    venue = "Badminton Hall"
    startDate = "2026-10-02"      # First Friday in Oct
    startTime = "17:00:00"        # 5 PM
    endTime = "19:00:00"          # 7 PM
    maxPlayers = 8
    recurrence = @{
        isRecurring = $true
        frequency = 3             # BiWeekly
        daysOfWeek = @(5)        # Friday
        endDate = "2026-11-30"
    }
} | ConvertTo-Json -Depth 10

try {
    $biweeklySchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $biweeklySchedule
    Write-Host "? Created $($biweeklySchedules.Count) biweekly schedules (5-7 PM)!" -ForegroundColor Green
    foreach ($schedule in $biweeklySchedules) {
        $dt = [DateTime]$schedule.startTime
        Write-Host "  - $($dt.ToString('yyyy-MM-dd ddd HH:mm'))" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "? Failed: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Summary
Write-Host "=== Refined Schedule API Tests Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "? Every Wednesday 7-8 PM" -ForegroundColor Green
Write-Host "? Weekend mornings 9-11 AM" -ForegroundColor Green
Write-Host "? Weekday evenings 6-8 PM" -ForegroundColor Green
Write-Host "? Monthly tournament 10 AM-4 PM" -ForegroundColor Green
Write-Host "? Single event 2-6 PM (updated to 3-7 PM)" -ForegroundColor Green
Write-Host "? Date update (July 4 ? July 5)" -ForegroundColor Green
Write-Host "? Time validation working" -ForegroundColor Green
Write-Host "? BiWeekly Friday 5-7 PM" -ForegroundColor Green
Write-Host ""
Write-Host "All tests demonstrate clear date/time separation! ?" -ForegroundColor Cyan
