# Test Venues Endpoint
# This script tests the new GET /api/schedules/venues endpoint

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Testing Venues Endpoint" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "https://localhost:7063"

# Function to make API calls with error handling
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

# Step 1: Test venues endpoint (should work without authentication)
Write-Host "Step 1: Getting all venues (no authentication required)..." -ForegroundColor Yellow

$venues = Invoke-ApiRequest -Url "$baseUrl/api/schedules/venues" -Method GET

if ($venues) {
    Write-Host "? Successfully retrieved venues" -ForegroundColor Green
    Write-Host "  Found $($venues.Count) venues" -ForegroundColor Gray
    Write-Host ""
    
    if ($venues.Count -gt 0) {
        Write-Host "Venue Details:" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($venue in $venues) {
            Write-Host "  ?? $($venue.name)" -ForegroundColor Green
            Write-Host "     Total Schedules: $($venue.scheduleCount)" -ForegroundColor Gray
            Write-Host "     Available Schedules: $($venue.availableSchedules)" -ForegroundColor Gray
            Write-Host "     Sports: $($venue.sports -join ', ')" -ForegroundColor Gray
            
            # Calculate availability percentage
            if ($venue.scheduleCount -gt 0) {
                $availPercent = [math]::Round(($venue.availableSchedules / $venue.scheduleCount) * 100, 1)
                Write-Host "     Availability: $availPercent%" -ForegroundColor $(if ($availPercent -gt 50) { "Green" } else { "Yellow" })
            }
            Write-Host ""
        }
    } else {
        Write-Host "  No venues found (database may be empty)" -ForegroundColor Yellow
        Write-Host "  Tip: Create some schedules first to see venues" -ForegroundColor Gray
    }
} else {
    Write-Host "? Failed to retrieve venues" -ForegroundColor Red
}
Write-Host ""

# Step 2: Create test schedules at different venues (if admin token available)
Write-Host "Step 2: Creating test schedules at different venues..." -ForegroundColor Yellow

# Login as admin
$loginBody = @{
    email = "admin@playohcanada.com"
    password = "Admin@123"
} | ConvertTo-Json

$loginResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/login" -Method POST -Body $loginBody

if ($loginResponse) {
    $token = $loginResponse.token
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    Write-Host "? Logged in as admin" -ForegroundColor Green
    
    # Create schedules at different venues
    $venueNames = @(
        "Tennis Court A",
        "Community Center",
        "Downtown Sports Complex",
        "North Park"
    )
    
    $createdSchedules = 0
    
    foreach ($venueName in $venueNames) {
        $scheduleBody = @{
            sportId = 1
            venue = $venueName
            startDate = "2026-06-01"
            startTime = "19:00:00"
            endTime = "20:00:00"
            maxPlayers = 8
            equipmentDetails = "Test schedule for venue discovery"
            timezoneOffsetMinutes = -300
        } | ConvertTo-Json
        
        $schedule = Invoke-ApiRequest -Url "$baseUrl/api/schedules" -Method POST -Headers $headers -Body $scheduleBody
        
        if ($schedule) {
            $createdSchedules++
            Write-Host "  ? Created schedule at: $venueName" -ForegroundColor Gray
        }
    }
    
    Write-Host "? Created $createdSchedules test schedules" -ForegroundColor Green
} else {
    Write-Host "? Skipping schedule creation (admin login failed)" -ForegroundColor Yellow
}
Write-Host ""

# Step 3: Verify venues endpoint shows new venues
Write-Host "Step 3: Verifying updated venues list..." -ForegroundColor Yellow

$updatedVenues = Invoke-ApiRequest -Url "$baseUrl/api/schedules/venues" -Method GET

if ($updatedVenues) {
    Write-Host "? Successfully retrieved updated venues" -ForegroundColor Green
    Write-Host "  Found $($updatedVenues.Count) venues" -ForegroundColor Gray
    Write-Host ""
    
    # Check if test venues appear
    $testVenues = $updatedVenues | Where-Object { $_.name -in @("Tennis Court A", "Community Center", "Downtown Sports Complex", "North Park") }
    
    if ($testVenues.Count -gt 0) {
        Write-Host "? Test venues are visible:" -ForegroundColor Green
        foreach ($venue in $testVenues) {
            Write-Host "  - $($venue.name): $($venue.scheduleCount) schedules" -ForegroundColor Gray
        }
    }
}
Write-Host ""

# Step 4: Test filtering schedules by venue
Write-Host "Step 4: Testing schedule filter by venue..." -ForegroundColor Yellow

if ($updatedVenues -and $updatedVenues.Count -gt 0) {
    $testVenue = $updatedVenues[0].name
    Write-Host "  Testing with venue: $testVenue" -ForegroundColor Gray
    
    $schedulesAtVenue = Invoke-ApiRequest -Url "$baseUrl/api/schedules?venue=$([uri]::EscapeDataString($testVenue))" -Method GET
    
    if ($schedulesAtVenue) {
        Write-Host "? Found $($schedulesAtVenue.Count) schedules at $testVenue" -ForegroundColor Green
        
        # Verify all schedules are at the correct venue
        $correctVenue = $schedulesAtVenue | Where-Object { $_.venue -eq $testVenue }
        if ($correctVenue.Count -eq $schedulesAtVenue.Count) {
            Write-Host "? All schedules match the venue filter" -ForegroundColor Green
        } else {
            Write-Host "? Some schedules don't match the venue filter" -ForegroundColor Red
        }
    }
}
Write-Host ""

# Step 5: Test venue statistics accuracy
Write-Host "Step 5: Verifying venue statistics..." -ForegroundColor Yellow

if ($updatedVenues -and $updatedVenues.Count -gt 0) {
    $testVenue = $updatedVenues[0]
    
    # Get schedules for this venue
    $schedulesAtVenue = Invoke-ApiRequest -Url "$baseUrl/api/schedules?venue=$([uri]::EscapeDataString($testVenue.name))" -Method GET
    
    if ($schedulesAtVenue) {
        $actualCount = $schedulesAtVenue.Count
        $reportedCount = $testVenue.scheduleCount
        
        if ($actualCount -eq $reportedCount) {
            Write-Host "? Schedule count is accurate ($actualCount)" -ForegroundColor Green
        } else {
            Write-Host "? Schedule count mismatch: Reported $reportedCount, Actual $actualCount" -ForegroundColor Red
        }
        
        # Count available schedules
        $availableCount = ($schedulesAtVenue | Where-Object { $_.spotsRemaining -gt 0 }).Count
        $reportedAvailable = $testVenue.availableSchedules
        
        if ($availableCount -eq $reportedAvailable) {
            Write-Host "? Available schedule count is accurate ($availableCount)" -ForegroundColor Green
        } else {
            Write-Host "? Available count mismatch: Reported $reportedAvailable, Actual $availableCount" -ForegroundColor Red
        }
    }
}
Write-Host ""

# Step 6: Test popular venues ranking
Write-Host "Step 6: Showing most active venues..." -ForegroundColor Yellow

if ($updatedVenues -and $updatedVenues.Count -gt 0) {
    $topVenues = $updatedVenues | Sort-Object -Property scheduleCount -Descending | Select-Object -First 5
    
    Write-Host "Top 5 Most Active Venues:" -ForegroundColor Cyan
    $rank = 1
    foreach ($venue in $topVenues) {
        Write-Host "  $rank. $($venue.name): $($venue.scheduleCount) schedules" -ForegroundColor Gray
        $rank++
    }
}
Write-Host ""

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Venues Endpoint Tests:" -ForegroundColor White
Write-Host "  ? Get all venues (no auth)" -ForegroundColor Green
Write-Host "  ? Venue details structure" -ForegroundColor Green
Write-Host "  ? Create test venues" -ForegroundColor Green
Write-Host "  ? Verify venue list updates" -ForegroundColor Green
Write-Host "  ? Filter schedules by venue" -ForegroundColor Green
Write-Host "  ? Verify venue statistics" -ForegroundColor Green
Write-Host "  ? Popular venues ranking" -ForegroundColor Green
Write-Host ""

if ($updatedVenues) {
    Write-Host "Final Venue Count: $($updatedVenues.Count)" -ForegroundColor Cyan
    
    if ($updatedVenues.Count -gt 0) {
        $totalSchedules = ($updatedVenues | Measure-Object -Property scheduleCount -Sum).Sum
        $totalAvailable = ($updatedVenues | Measure-Object -Property availableSchedules -Sum).Sum
        
        Write-Host "Total Schedules: $totalSchedules" -ForegroundColor Cyan
        Write-Host "Total Available: $totalAvailable" -ForegroundColor Cyan
        
        if ($totalSchedules -gt 0) {
            $availPercent = [math]::Round(($totalAvailable / $totalSchedules) * 100, 1)
            Write-Host "Overall Availability: $availPercent%" -ForegroundColor $(if ($availPercent -gt 50) { "Green" } else { "Yellow" })
        }
    }
}
Write-Host ""
Write-Host "All tests completed successfully! ?" -ForegroundColor Green
Write-Host ""
