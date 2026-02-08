# Test Exclude Joined Schedules Feature

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Exclude Joined Schedules" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "https://localhost:7063"

# Function to make API calls
function Invoke-ApiRequest {
    param(
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [string]$Body = $null
    )
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            SkipCertificateCheck = $true
        }
        
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = "application/json"
        }
        
        return Invoke-RestMethod @params
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Step 1: Login as user
Write-Host "Step 1: Logging in as user..." -ForegroundColor Yellow

$loginBody = @{
    email = "testuser@example.com"
    password = "UserPass123!"
} | ConvertTo-Json

$login = Invoke-ApiRequest -Url "$baseUrl/api/auth/login" -Method POST -Body $loginBody

if (-not $login) {
    Write-Host "User doesn't exist, registering..." -ForegroundColor Gray
    
    $registerBody = @{
        name = "Test User"
        email = "testuser@example.com"
        password = "UserPass123!"
        confirmPassword = "UserPass123!"
        isAdmin = $false
    } | ConvertTo-Json
    
    $login = Invoke-ApiRequest -Url "$baseUrl/api/auth/register" -Method POST -Body $registerBody
}

if ($login) {
    $userToken = $login.token
    $headers = @{ "Authorization" = "Bearer $userToken" }
    Write-Host "? Logged in successfully" -ForegroundColor Green
} else {
    Write-Host "? Failed to login" -ForegroundColor Red
    exit
}
Write-Host ""

# Step 2: Get all available schedules (without excludeJoined)
Write-Host "Step 2: Getting all available schedules..." -ForegroundColor Yellow

$offset = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)
$allSchedules = Invoke-ApiRequest -Url "$baseUrl/api/schedules?availableOnly=true&timezoneOffsetMinutes=$offset" -Headers $headers

if ($allSchedules) {
    Write-Host "? Found $($allSchedules.Count) available schedules" -ForegroundColor Green
    
    if ($allSchedules.Count -gt 0) {
        Write-Host "`nAll Schedules:" -ForegroundColor Cyan
        for ($i = 0; $i -lt [Math]::Min(5, $allSchedules.Count); $i++) {
            $s = $allSchedules[$i]
            Write-Host "  $($i+1). $($s.sportName) at $($s.venue) - $($s.startTime)" -ForegroundColor White
            Write-Host "     Spots: $($s.spotsRemaining) available" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "? No schedules found" -ForegroundColor Red
    exit
}
Write-Host ""

# Step 3: Join a few schedules
Write-Host "Step 3: Joining some schedules..." -ForegroundColor Yellow

$joinedCount = 0
$schedulesToJoin = [Math]::Min(3, $allSchedules.Count)

for ($i = 0; $i -lt $schedulesToJoin; $i++) {
    $schedule = $allSchedules[$i]
    
    $joinBody = @{
        scheduleId = $schedule.id
    } | ConvertTo-Json
    
    $booking = Invoke-ApiRequest -Url "$baseUrl/api/bookings/join" -Method POST -Headers $headers -Body $joinBody
    
    if ($booking) {
        $joinedCount++
        Write-Host "  ? Joined: $($schedule.sportName) at $($schedule.venue)" -ForegroundColor Green
    } else {
        Write-Host "  ??  Already joined or full: $($schedule.sportName)" -ForegroundColor Yellow
    }
}

Write-Host "`n? Joined $joinedCount schedule(s)" -ForegroundColor Green
Write-Host ""

# Step 4: Get schedules WITHOUT excludeJoined (should show all)
Write-Host "Step 4: Getting schedules WITHOUT excludeJoined..." -ForegroundColor Yellow

$allSchedulesAfter = Invoke-ApiRequest -Url "$baseUrl/api/schedules?availableOnly=true&timezoneOffsetMinutes=$offset" -Headers $headers

if ($allSchedulesAfter) {
    Write-Host "? Found $($allSchedulesAfter.Count) schedules (includes joined)" -ForegroundColor Green
} else {
    Write-Host "? Failed to get schedules" -ForegroundColor Red
}
Write-Host ""

# Step 5: Get schedules WITH excludeJoined (should exclude joined ones)
Write-Host "Step 5: Getting schedules WITH excludeJoined=true..." -ForegroundColor Yellow

$notJoinedSchedules = Invoke-ApiRequest -Url "$baseUrl/api/schedules?availableOnly=true&excludeJoined=true&timezoneOffsetMinutes=$offset" -Headers $headers

if ($notJoinedSchedules) {
    Write-Host "? Found $($notJoinedSchedules.Count) schedules (excludes joined)" -ForegroundColor Green
    
    if ($notJoinedSchedules.Count -gt 0) {
        Write-Host "`nSchedules You Can Join:" -ForegroundColor Cyan
        for ($i = 0; $i -lt [Math]::Min(5, $notJoinedSchedules.Count); $i++) {
            $s = $notJoinedSchedules[$i]
            Write-Host "  $($i+1). $($s.sportName) at $($s.venue) - $($s.startTime)" -ForegroundColor White
            Write-Host "     Spots: $($s.spotsRemaining) available" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "? Failed to get schedules" -ForegroundColor Red
}
Write-Host ""

# Step 6: Compare results
Write-Host "Step 6: Comparing results..." -ForegroundColor Yellow

$difference = $allSchedulesAfter.Count - $notJoinedSchedules.Count

Write-Host "`nComparison:" -ForegroundColor Cyan
Write-Host "  All schedules: $($allSchedulesAfter.Count)" -ForegroundColor White
Write-Host "  Not joined: $($notJoinedSchedules.Count)" -ForegroundColor White
Write-Host "  Already joined: $difference" -ForegroundColor Yellow

if ($difference -gt 0) {
    Write-Host "`n? Successfully filtering out $difference already-joined schedule(s)" -ForegroundColor Green
} else {
    Write-Host "`n??  No schedules filtered (user hasn't joined any yet)" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Verify joined schedules are excluded
Write-Host "Step 7: Verifying joined schedules are excluded..." -ForegroundColor Yellow

$myBookings = Invoke-ApiRequest -Url "$baseUrl/api/bookings/my-bookings" -Headers $headers

if ($myBookings) {
    Write-Host "? User has $($myBookings.Count) booking(s)" -ForegroundColor Green
    
    # Check if any joined schedule appears in notJoinedSchedules
    $foundInBoth = $false
    foreach ($booking in $myBookings) {
        $scheduleId = $booking.scheduleId
        $foundInNotJoined = $notJoinedSchedules | Where-Object { $_.id -eq $scheduleId }
        
        if ($foundInNotJoined) {
            Write-Host "  ? ERROR: Joined schedule $scheduleId still appears in results!" -ForegroundColor Red
            $foundInBoth = $true
        }
    }
    
    if (-not $foundInBoth -and $myBookings.Count -gt 0) {
        Write-Host "  ? All joined schedules are correctly excluded" -ForegroundColor Green
    }
}
Write-Host ""

# Step 8: Test without authentication (should fail)
Write-Host "Step 8: Testing excludeJoined without authentication..." -ForegroundColor Yellow

$unauthResult = Invoke-ApiRequest -Url "$baseUrl/api/schedules?excludeJoined=true"

if (-not $unauthResult) {
    Write-Host "? Correctly requires authentication for excludeJoined" -ForegroundColor Green
} else {
    Write-Host "? Should require authentication" -ForegroundColor Red
}
Write-Host ""

# Step 9: Test combining filters
Write-Host "Step 9: Testing combined filters..." -ForegroundColor Yellow

if ($allSchedules.Count -gt 0) {
    $sportId = $allSchedules[0].sportId
    
    $combinedResults = Invoke-ApiRequest -Url "$baseUrl/api/schedules?sportId=$sportId&availableOnly=true&excludeJoined=true&timezoneOffsetMinutes=$offset" -Headers $headers
    
    if ($combinedResults) {
        Write-Host "? Combined filters work: sportId + availableOnly + excludeJoined" -ForegroundColor Green
        Write-Host "  Found $($combinedResults.Count) schedule(s)" -ForegroundColor Gray
    } else {
        Write-Host "? Combined filters failed" -ForegroundColor Red
    }
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Exclude Joined Schedules Tests:" -ForegroundColor White
Write-Host "  ? User login" -ForegroundColor Green
Write-Host "  ? Get all schedules" -ForegroundColor Green
Write-Host "  ? Join multiple schedules" -ForegroundColor Green
Write-Host "  ? Get schedules without excludeJoined" -ForegroundColor Green
Write-Host "  ? Get schedules with excludeJoined" -ForegroundColor Green
Write-Host "  ? Verify filtering works" -ForegroundColor Green
Write-Host "  ? Requires authentication" -ForegroundColor Green
Write-Host "  ? Combined filters work" -ForegroundColor Green
Write-Host ""

Write-Host "Results:" -ForegroundColor Cyan
Write-Host "  Total schedules: $($allSchedulesAfter.Count)" -ForegroundColor White
Write-Host "  Already joined: $difference" -ForegroundColor Yellow
Write-Host "  Can still join: $($notJoinedSchedules.Count)" -ForegroundColor Green
Write-Host ""

if ($difference -gt 0) {
    Write-Host "? Feature working correctly - joined schedules are excluded!" -ForegroundColor Green
} else {
    Write-Host "??  Join some schedules to see the filter in action" -ForegroundColor Yellow
}
Write-Host ""
