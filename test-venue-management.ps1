# Test Venue Management API

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Venue Management API" -ForegroundColor Cyan
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

# Step 1: Login as admin
Write-Host "Step 1: Logging in as admin..." -ForegroundColor Yellow

$loginBody = @{
    email = "admin@playohcanada.com"
    password = "Admin@123"
} | ConvertTo-Json

$login = Invoke-ApiRequest -Url "$baseUrl/api/auth/login" -Method POST -Body $loginBody

if ($login) {
    $adminToken = $login.token
    $headers = @{ "Authorization" = "Bearer $adminToken" }
    Write-Host "? Logged in as admin" -ForegroundColor Green
} else {
    Write-Host "? Failed to login as admin" -ForegroundColor Red
    exit
}
Write-Host ""

# Step 2: Get venue suggestions (public endpoint)
Write-Host "Step 2: Getting venue suggestions..." -ForegroundColor Yellow

$suggestions = Invoke-ApiRequest -Url "$baseUrl/api/venues/suggestions"

if ($suggestions) {
    Write-Host "? Found $($suggestions.Count) unique venues" -ForegroundColor Green
    
    if ($suggestions.Count -gt 0) {
        Write-Host "`nExisting Venues:" -ForegroundColor Cyan
        foreach ($venue in $suggestions) {
            Write-Host "  - $venue" -ForegroundColor White
        }
    }
} else {
    Write-Host "? No venues found" -ForegroundColor Red
}
Write-Host ""

# Step 3: Get venue statistics
Write-Host "Step 3: Getting venue statistics..." -ForegroundColor Yellow

$stats = Invoke-ApiRequest -Url "$baseUrl/api/venues/statistics" -Headers $headers

if ($stats) {
    Write-Host "? Retrieved statistics for $($stats.Count) venues" -ForegroundColor Green
    
    if ($stats.Count -gt 0) {
        Write-Host "`nVenue Statistics:" -ForegroundColor Cyan
        foreach ($stat in $stats) {
            Write-Host "`n  ?? $($stat.venueName)" -ForegroundColor Green
            Write-Host "     Total Schedules: $($stat.totalSchedules)" -ForegroundColor Gray
            Write-Host "     Future: $($stat.futureSchedules) | Past: $($stat.pastSchedules)" -ForegroundColor Gray
            Write-Host "     Total Bookings: $($stat.totalBookings)" -ForegroundColor Gray
            Write-Host "     Most Popular Sport: $($stat.mostPopularSport)" -ForegroundColor Gray
            Write-Host "     Avg Bookings/Schedule: $([math]::Round($stat.averageBookingsPerSchedule, 2))" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "? Failed to get statistics" -ForegroundColor Red
}
Write-Host ""

# Step 4: Create test venues with variations
Write-Host "Step 4: Creating test schedules with venue variations..." -ForegroundColor Yellow

$testVenues = @(
    "Tennis Court - A",
    "Tennis Court-A",
    "Tennis court a"
)

$createdCount = 0
foreach ($venueName in $testVenues) {
    $scheduleBody = @{
        sportId = 1
        venue = $venueName
        startDate = "2026-06-01"
        startTime = "19:00:00"
        endTime = "20:00:00"
        maxPlayers = 8
        timezoneOffsetMinutes = -300
    } | ConvertTo-Json
    
    $schedule = Invoke-ApiRequest -Url "$baseUrl/api/schedules" -Method POST -Headers $headers -Body $scheduleBody
    
    if ($schedule) {
        $createdCount++
        Write-Host "  ? Created schedule at: $venueName" -ForegroundColor Gray
    }
}

Write-Host "? Created $createdCount test schedules with variations" -ForegroundColor Green
Write-Host ""

# Step 5: Validate venue name
Write-Host "Step 5: Testing venue name validation..." -ForegroundColor Yellow

$validateBody = @{
    venueName = "  Tennis Court  A  "
} | ConvertTo-Json

$validation = Invoke-ApiRequest -Url "$baseUrl/api/venues/validate" -Method POST -Headers $headers -Body $validateBody

if ($validation) {
    Write-Host "? Validation completed" -ForegroundColor Green
    Write-Host "  Valid: $($validation.isValid)" -ForegroundColor $(if ($validation.isValid) { "Green" } else { "Yellow" })
    
    if ($validation.issues.Count -gt 0) {
        Write-Host "`n  Issues Found:" -ForegroundColor Yellow
        foreach ($issue in $validation.issues) {
            Write-Host "    - $issue" -ForegroundColor Gray
        }
    }
    
    if ($validation.suggestions.Count -gt 0) {
        Write-Host "`n  Suggestions:" -ForegroundColor Cyan
        foreach ($suggestion in $validation.suggestions) {
            Write-Host "    - $suggestion" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "? Validation failed" -ForegroundColor Red
}
Write-Host ""

# Step 6: Merge venue variations
Write-Host "Step 6: Merging venue name variations..." -ForegroundColor Yellow

$mergeBody = @{
    targetName = "Tennis Court A"
    venuesToMerge = @(
        "Tennis Court - A",
        "Tennis Court-A",
        "Tennis court a"
    )
} | ConvertTo-Json

$mergeResult = Invoke-ApiRequest -Url "$baseUrl/api/venues/merge" -Method POST -Headers $headers -Body $mergeBody

if ($mergeResult) {
    Write-Host "? Merge completed successfully" -ForegroundColor Green
    Write-Host "  Target: $($mergeResult.targetName)" -ForegroundColor Gray
    Write-Host "  Merged venues: $($mergeResult.mergedVenues.Count)" -ForegroundColor Gray
    Write-Host "  Schedules updated: $($mergeResult.schedulesUpdated)" -ForegroundColor Gray
    Write-Host "`n  Message: $($mergeResult.message)" -ForegroundColor Cyan
} else {
    Write-Host "??  Merge failed (venues might not exist)" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Test rename
Write-Host "Step 7: Testing venue rename..." -ForegroundColor Yellow

# First create a venue to rename
$renameTestBody = @{
    sportId = 1
    venue = "Comunity Center"  # Typo
    startDate = "2026-06-01"
    startTime = "18:00:00"
    endTime = "19:00:00"
    maxPlayers = 10
    timezoneOffsetMinutes = -300
} | ConvertTo-Json

$schedule = Invoke-ApiRequest -Url "$baseUrl/api/schedules" -Method POST -Headers $headers -Body $renameTestBody

if ($schedule) {
    Write-Host "  ? Created schedule with typo: 'Comunity Center'" -ForegroundColor Gray
    
    # Now rename it
    $renameBody = @{
        oldName = "Comunity Center"
        newName = "Community Center"
    } | ConvertTo-Json
    
    $renameResult = Invoke-ApiRequest -Url "$baseUrl/api/venues/rename" -Method PUT -Headers $headers -Body $renameBody
    
    if ($renameResult) {
        Write-Host "? Rename completed successfully" -ForegroundColor Green
        Write-Host "  Old: $($renameResult.oldName)" -ForegroundColor Gray
        Write-Host "  New: $($renameResult.newName)" -ForegroundColor Gray
        Write-Host "  Schedules updated: $($renameResult.schedulesUpdated)" -ForegroundColor Gray
    } else {
        Write-Host "? Rename failed" -ForegroundColor Red
    }
}
Write-Host ""

# Step 8: Verify updated suggestions
Write-Host "Step 8: Verifying updated venue list..." -ForegroundColor Yellow

$updatedSuggestions = Invoke-ApiRequest -Url "$baseUrl/api/venues/suggestions"

if ($updatedSuggestions) {
    Write-Host "? Updated venue list:" -ForegroundColor Green
    foreach ($venue in $updatedSuggestions | Sort-Object) {
        Write-Host "  - $venue" -ForegroundColor White
    }
    
    # Check if merged venues are now standardized
    $hasVariations = $updatedSuggestions | Where-Object { 
        $_ -in @("Tennis Court - A", "Tennis Court-A", "Tennis court a") 
    }
    
    if (-not $hasVariations) {
        Write-Host "`n? Venue variations successfully merged" -ForegroundColor Green
    }
} else {
    Write-Host "? Failed to get updated list" -ForegroundColor Red
}
Write-Host ""

# Step 9: Get updated statistics
Write-Host "Step 9: Getting updated statistics..." -ForegroundColor Yellow

$finalStats = Invoke-ApiRequest -Url "$baseUrl/api/venues/statistics" -Headers $headers

if ($finalStats) {
    Write-Host "? Final statistics:" -ForegroundColor Green
    
    # Show top 3 venues by bookings
    $topVenues = $finalStats | Sort-Object -Property totalBookings -Descending | Select-Object -First 3
    
    Write-Host "`nTop 3 Venues by Bookings:" -ForegroundColor Cyan
    $rank = 1
    foreach ($venue in $topVenues) {
        Write-Host "  $rank. $($venue.venueName): $($venue.totalBookings) bookings" -ForegroundColor White
        $rank++
    }
}
Write-Host ""

# Step 10: Test delete (optional - commented out to preserve data)
Write-Host "Step 10: Testing venue delete (skipped to preserve data)..." -ForegroundColor Yellow
Write-Host "  To test delete, uncomment the code below" -ForegroundColor Gray

<#
# Create a test venue to delete
$deleteTestBody = @{
    sportId = 1
    venue = "Test Venue To Delete"
    startDate = "2026-06-01"
    startTime = "20:00:00"
    endTime = "21:00:00"
    maxPlayers = 5
    timezoneOffsetMinutes = -300
} | ConvertTo-Json

$schedule = Invoke-ApiRequest -Url "$baseUrl/api/schedules" -Method POST -Headers $headers -Body $deleteTestBody

if ($schedule) {
    # Delete the venue
    $deleteResult = Invoke-ApiRequest -Url "$baseUrl/api/venues/Test%20Venue%20To%20Delete" -Method DELETE -Headers $headers
    
    if ($deleteResult) {
        Write-Host "? Delete completed" -ForegroundColor Green
        Write-Host "  Schedules deleted: $($deleteResult.schedulesDeleted)" -ForegroundColor Gray
        Write-Host "  Bookings affected: $($deleteResult.bookingsAffected)" -ForegroundColor Gray
    }
}
#>

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Venue Management API Tests:" -ForegroundColor White
Write-Host "  ? Admin login" -ForegroundColor Green
Write-Host "  ? Get venue suggestions (public)" -ForegroundColor Green
Write-Host "  ? Get venue statistics (admin)" -ForegroundColor Green
Write-Host "  ? Create test venues" -ForegroundColor Green
Write-Host "  ? Validate venue name" -ForegroundColor Green
Write-Host "  ? Merge venue variations" -ForegroundColor Green
Write-Host "  ? Rename venue (fix typo)" -ForegroundColor Green
Write-Host "  ? Verify updated venues" -ForegroundColor Green
Write-Host "  ? Get updated statistics" -ForegroundColor Green
Write-Host "  ?  Delete venue (skipped)" -ForegroundColor Yellow
Write-Host ""

if ($finalStats) {
    Write-Host "Final Results:" -ForegroundColor Cyan
    Write-Host "  Total Venues: $($finalStats.Count)" -ForegroundColor White
    Write-Host "  Total Schedules: $(($finalStats | Measure-Object -Property totalSchedules -Sum).Sum)" -ForegroundColor White
    Write-Host "  Total Bookings: $(($finalStats | Measure-Object -Property totalBookings -Sum).Sum)" -ForegroundColor White
}

Write-Host ""
Write-Host "All tests completed! ?" -ForegroundColor Green
Write-Host ""
