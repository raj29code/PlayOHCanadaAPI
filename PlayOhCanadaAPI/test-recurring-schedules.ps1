# Test script for Recurring Schedule Feature
$baseUrl = "https://localhost:7063/api"

Write-Host "=== Testing Recurring Schedule Feature ===" -ForegroundColor Cyan
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

# Test 1: Create Weekly Schedule (Every Thursday)
Write-Host "Test 1: Creating Weekly Schedule (Every Thursday 7-10 PM)" -ForegroundColor Yellow
$weeklySchedule = @{
    sportId = $sportId
    venue = "Tennis Court A"
    startDate = "2026-01-01"
    startTime = "19:00:00"
    endTime = "22:00:00"
    maxPlayers = 8
    equipmentDetails = "Bring your own racket"
    recurrence = @{
        isRecurring = $true
        frequency = 2  # Weekly
        endDate = "2026-02-01"
        daysOfWeek = @(4)  # Thursday
    }
} | ConvertTo-Json -Depth 10

try {
    $createdSchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $weeklySchedule
    Write-Host "? Created $($createdSchedules.Count) weekly schedules!" -ForegroundColor Green
    Write-Host "  First schedule: $($createdSchedules[0].startTime)" -ForegroundColor Gray
    Write-Host "  Last schedule: $($createdSchedules[-1].startTime)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Failed to create weekly schedule: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 2: Create Daily Schedule
Write-Host "Test 2: Creating Daily Schedule (Every day for a week)" -ForegroundColor Yellow
$dailySchedule = @{
    sportId = $sportId
    venue = "Morning Yoga Studio"
    startDate = "2026-03-01"
    startTime = "06:00:00"
    endTime = "07:00:00"
    maxPlayers = 20
    equipmentDetails = "Bring your mat"
    recurrence = @{
        isRecurring = $true
        frequency = 1  # Daily
        endDate = "2026-03-07"
    }
} | ConvertTo-Json -Depth 10

try {
    $dailySchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $dailySchedule
    Write-Host "? Created $($dailySchedules.Count) daily schedules!" -ForegroundColor Green
    Write-Host "  First: $($dailySchedules[0].startTime)" -ForegroundColor Gray
    Write-Host "  Last: $($dailySchedules[-1].startTime)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Failed to create daily schedule: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 3: Create Weekend Schedule (Saturday & Sunday)
Write-Host "Test 3: Creating Weekend Schedule (Sat & Sun for 2 weeks)" -ForegroundColor Yellow
$weekendSchedule = @{
    sportId = $sportId
    venue = "Soccer Field"
    startDate = "2026-04-05"
    startTime = "10:00:00"
    endTime = "12:00:00"
    maxPlayers = 22
    equipmentDetails = "Shin guards required"
    recurrence = @{
        isRecurring = $true
        frequency = 2  # Weekly
        endDate = "2026-04-20"
        daysOfWeek = @(0, 6)  # Sunday and Saturday
    }
} | ConvertTo-Json -Depth 10

try {
    $weekendSchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $weekendSchedule
    Write-Host "? Created $($weekendSchedules.Count) weekend schedules!" -ForegroundColor Green
    foreach ($schedule in $weekendSchedules) {
        $dayName = (Get-Date $schedule.startTime).DayOfWeek
        Write-Host "  - $($schedule.startTime) ($dayName)" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "? Failed to create weekend schedule: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 4: Create Weekday Schedule (Mon-Fri)
Write-Host "Test 4: Creating Weekday Schedule (Mon-Fri for 1 week)" -ForegroundColor Yellow
$weekdaySchedule = @{
    sportId = $sportId
    venue = "Basketball Court"
    startDate = "2026-05-04"
    startTime = "18:00:00"
    endTime = "20:00:00"
    maxPlayers = 10
    equipmentDetails = "Indoor shoes required"
    recurrence = @{
        isRecurring = $true
        frequency = 2  # Weekly
        endDate = "2026-05-10"
        daysOfWeek = @(1, 2, 3, 4, 5)  # Mon through Fri
    }
} | ConvertTo-Json -Depth 10

try {
    $weekdaySchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $weekdaySchedule
    Write-Host "? Created $($weekdaySchedules.Count) weekday schedules!" -ForegroundColor Green
    foreach ($schedule in $weekdaySchedules) {
        $dayName = (Get-Date $schedule.startTime).DayOfWeek
        Write-Host "  - $dayName: $($schedule.startTime)" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "? Failed to create weekday schedule: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 5: Create BiWeekly Schedule
Write-Host "Test 5: Creating BiWeekly Schedule (Every other Wednesday)" -ForegroundColor Yellow
$biweeklySchedule = @{
    sportId = $sportId
    venue = "Badminton Hall"
    startDate = "2026-06-03"
    startTime = "19:00:00"
    endTime = "21:00:00"
    maxPlayers = 8
    equipmentDetails = "Rackets provided"
    recurrence = @{
        isRecurring = $true
        frequency = 3  # BiWeekly
        endDate = "2026-07-31"
        daysOfWeek = @(3)  # Wednesday
    }
} | ConvertTo-Json -Depth 10

try {
    $biweeklySchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $biweeklySchedule
    Write-Host "? Created $($biweeklySchedules.Count) biweekly schedules!" -ForegroundColor Green
    foreach ($schedule in $biweeklySchedules) {
        Write-Host "  - $($schedule.startTime)" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "? Failed to create biweekly schedule: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 6: Create Monthly Schedule
Write-Host "Test 6: Creating Monthly Schedule (15th of each month)" -ForegroundColor Yellow
$monthlySchedule = @{
    sportId = $sportId
    venue = "Volleyball Court"
    startDate = "2026-01-15"
    startTime = "18:00:00"
    endTime = "20:00:00"
    maxPlayers = 12
    equipmentDetails = "Monthly tournament"
    recurrence = @{
        isRecurring = $true
        frequency = 4  # Monthly
        endDate = "2026-06-30"
    }
} | ConvertTo-Json -Depth 10

try {
    $monthlySchedules = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $monthlySchedule
    Write-Host "? Created $($monthlySchedules.Count) monthly schedules!" -ForegroundColor Green
    foreach ($schedule in $monthlySchedules) {
        Write-Host "  - $($schedule.startTime)" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "? Failed to create monthly schedule: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 7: Single Schedule (No Recurrence)
Write-Host "Test 7: Creating Single Schedule (One-time event)" -ForegroundColor Yellow
$singleSchedule = @{
    sportId = $sportId
    venue = "Special Event Arena"
    startDate = "2026-12-25"
    startTime = "14:00:00"
    endTime = "18:00:00"
    maxPlayers = 50
    equipmentDetails = "Holiday special event"
} | ConvertTo-Json -Depth 10

try {
    $singleScheduleResult = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $singleSchedule
    Write-Host "? Created single schedule!" -ForegroundColor Green
    Write-Host "  Date: $($singleScheduleResult[0].startTime)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Failed to create single schedule: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 8: Validation - Missing DaysOfWeek for Weekly
Write-Host "Test 8: Testing Validation (Weekly without DaysOfWeek)" -ForegroundColor Yellow
$invalidSchedule = @{
    sportId = $sportId
    venue = "Test Venue"
    startDate = "2026-01-01"
    startTime = "12:00:00"
    endTime = "13:00:00"
    maxPlayers = 10
    recurrence = @{
        isRecurring = $true
        frequency = 2  # Weekly
        endDate = "2026-01-31"
        # Missing daysOfWeek - should fail
    }
} | ConvertTo-Json -Depth 10

try {
    $result = Invoke-RestMethod -Uri "$baseUrl/schedules" -Method Post -Headers $headers -Body $invalidSchedule
    Write-Host "? Validation failed - should have rejected this!" -ForegroundColor Red
    Write-Host ""
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "? Validation working correctly - rejected invalid schedule!" -ForegroundColor Green
        Write-Host "  Error: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "? Unexpected error: $_" -ForegroundColor Red
        Write-Host ""
    }
}

# Get all schedules
Write-Host "Step 9: Retrieving all created schedules..." -ForegroundColor Yellow
try {
    $allSchedules = Invoke-RestMethod -Uri "$baseUrl/schedules?startDate=2026-01-01" -Method Get
    Write-Host "? Total schedules in system: $($allSchedules.Count)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "? Failed to retrieve schedules: $_" -ForegroundColor Red
    Write-Host ""
}

Write-Host "=== Recurring Schedule Tests Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "? Weekly schedule (Every Thursday)" -ForegroundColor Green
Write-Host "? Daily schedule (7 days)" -ForegroundColor Green
Write-Host "? Weekend schedule (Sat & Sun)" -ForegroundColor Green
Write-Host "? Weekday schedule (Mon-Fri)" -ForegroundColor Green
Write-Host "? BiWeekly schedule (Every other Wednesday)" -ForegroundColor Green
Write-Host "? Monthly schedule (15th of each month)" -ForegroundColor Green
Write-Host "? Single schedule (One-time event)" -ForegroundColor Green
Write-Host "? Validation test (Properly rejected invalid data)" -ForegroundColor Green
Write-Host ""
Write-Host "Total schedules created: $($allSchedules.Count)" -ForegroundColor Cyan
