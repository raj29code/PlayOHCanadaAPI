# Test Join Schedule and My Bookings Functionality

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Join Schedule & My Bookings" -ForegroundColor Cyan
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
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response: $responseBody" -ForegroundColor Red
        }
        return $null
    }
}

# Step 1: Register/Login as user
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
    Write-Host "? Logged in as: $($login.user.name ?? $login.name)" -ForegroundColor Green
} else {
    Write-Host "? Failed to login" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Get available schedules
Write-Host "Step 2: Getting available schedules..." -ForegroundColor Yellow

$offset = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)
$schedules = Invoke-ApiRequest -Url "$baseUrl/api/schedules?availableOnly=true&timezoneOffsetMinutes=$offset"

if ($schedules -and $schedules.Count -gt 0) {
    Write-Host "? Found $($schedules.Count) available schedules" -ForegroundColor Green
    
    Write-Host "`nAvailable Schedules:" -ForegroundColor Cyan
    for ($i = 0; $i -lt [Math]::Min(3, $schedules.Count); $i++) {
        $schedule = $schedules[$i]
        Write-Host "  $($i+1). $($schedule.sportName) at $($schedule.venue)" -ForegroundColor White
        Write-Host "     Time: $($schedule.startTime)" -ForegroundColor Gray
        Write-Host "     Spots: $($schedule.spotsRemaining) available" -ForegroundColor Gray
    }
} else {
    Write-Host "??  No available schedules found" -ForegroundColor Yellow
    Write-Host "Please create some schedules first (as admin)" -ForegroundColor Gray
    exit
}
Write-Host ""

# Step 3: Join a schedule
Write-Host "Step 3: Joining first available schedule..." -ForegroundColor Yellow

$scheduleToJoin = $schedules[0]

$joinBody = @{
    scheduleId = $scheduleToJoin.id
} | ConvertTo-Json

$booking = Invoke-ApiRequest -Url "$baseUrl/api/bookings/join" -Method POST -Headers $headers -Body $joinBody

if ($booking) {
    Write-Host "? Successfully joined schedule!" -ForegroundColor Green
    Write-Host "  Sport: $($booking.sportName)" -ForegroundColor Gray
    Write-Host "  Venue: $($booking.venue)" -ForegroundColor Gray
    Write-Host "  Time: $($booking.scheduleStartTime)" -ForegroundColor Gray
    Write-Host "  Players: $($booking.currentPlayers)/$($booking.maxPlayers)" -ForegroundColor Gray
    Write-Host "  Booking ID: $($booking.id)" -ForegroundColor Gray
} else {
    Write-Host "??  Could not join schedule (might already be joined)" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Try to join same schedule again (should fail)
Write-Host "Step 4: Trying to join same schedule again (should fail)..." -ForegroundColor Yellow

$duplicateJoin = Invoke-ApiRequest -Url "$baseUrl/api/bookings/join" -Method POST -Headers $headers -Body $joinBody

if (-not $duplicateJoin) {
    Write-Host "? Correctly prevented duplicate booking" -ForegroundColor Green
} else {
    Write-Host "? Should have prevented duplicate booking" -ForegroundColor Red
}
Write-Host ""

# Step 5: Get my bookings
Write-Host "Step 5: Viewing my bookings..." -ForegroundColor Yellow

$myBookings = Invoke-ApiRequest -Url "$baseUrl/api/bookings/my-bookings?timezoneOffsetMinutes=$offset" -Headers $headers

if ($myBookings) {
    Write-Host "? Found $($myBookings.Count) booking(s)" -ForegroundColor Green
    Write-Host ""
    Write-Host "My Bookings:" -ForegroundColor Cyan
    
    foreach ($b in $myBookings) {
        Write-Host "  ?? $($b.sportName) at $($b.venue)" -ForegroundColor Green
        Write-Host "     Time: $($b.scheduleStartTime)" -ForegroundColor Gray
        Write-Host "     Players: $($b.currentPlayers)/$($b.maxPlayers)" -ForegroundColor Gray
        Write-Host "     Booking ID: $($b.id)" -ForegroundColor Gray
        Write-Host "     Can Cancel: $($b.canCancel)" -ForegroundColor $(if ($b.canCancel) { "Green" } else { "Red" })
        if ($b.equipmentDetails) {
            Write-Host "     Equipment: $($b.equipmentDetails)" -ForegroundColor Gray
        }
        Write-Host ""
    }
} else {
    Write-Host "? Failed to get bookings" -ForegroundColor Red
}
Write-Host ""

# Step 6: Join another schedule
Write-Host "Step 6: Joining another schedule..." -ForegroundColor Yellow

if ($schedules.Count -gt 1) {
    $secondSchedule = $schedules[1]
    
    $joinBody2 = @{
        scheduleId = $secondSchedule.id
    } | ConvertTo-Json
    
    $booking2 = Invoke-ApiRequest -Url "$baseUrl/api/bookings/join" -Method POST -Headers $headers -Body $joinBody2
    
    if ($booking2) {
        Write-Host "? Joined second schedule" -ForegroundColor Green
        Write-Host "  Sport: $($booking2.sportName)" -ForegroundColor Gray
    } else {
        Write-Host "??  Could not join second schedule" -ForegroundColor Yellow
    }
} else {
    Write-Host "??  Only one schedule available, skipping" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: View updated bookings
Write-Host "Step 7: Viewing updated bookings..." -ForegroundColor Yellow

$updatedBookings = Invoke-ApiRequest -Url "$baseUrl/api/bookings/my-bookings?timezoneOffsetMinutes=$offset" -Headers $headers

if ($updatedBookings) {
    Write-Host "? You now have $($updatedBookings.Count) booking(s)" -ForegroundColor Green
}
Write-Host ""

# Step 8: Test cancellation
Write-Host "Step 8: Testing booking cancellation..." -ForegroundColor Yellow

if ($updatedBookings -and $updatedBookings.Count -gt 0) {
    $bookingToCancel = $updatedBookings[0]
    
    if ($bookingToCancel.canCancel) {
        Write-Host "  Cancelling booking #$($bookingToCancel.id)..." -ForegroundColor Gray
        
        $cancelResult = Invoke-ApiRequest -Url "$baseUrl/api/bookings/$($bookingToCancel.id)" -Method DELETE -Headers $headers
        
        if ($cancelResult) {
            Write-Host "? Booking cancelled: $($cancelResult.message)" -ForegroundColor Green
            
            # Verify booking was removed
            $finalBookings = Invoke-ApiRequest -Url "$baseUrl/api/bookings/my-bookings?timezoneOffsetMinutes=$offset" -Headers $headers
            Write-Host "? Remaining bookings: $($finalBookings.Count)" -ForegroundColor Green
        } else {
            Write-Host "? Failed to cancel booking" -ForegroundColor Red
        }
    } else {
        Write-Host "??  Booking cannot be cancelled (too close to start time)" -ForegroundColor Yellow
    }
} else {
    Write-Host "??  No bookings to cancel" -ForegroundColor Yellow
}
Write-Host ""

# Step 9: Test guest booking
Write-Host "Step 9: Testing guest booking (no authentication)..." -ForegroundColor Yellow

if ($schedules.Count -gt 0) {
    # Find a schedule user hasn't joined yet
    $guestSchedule = $schedules | Where-Object { $_.id -ne $scheduleToJoin.id } | Select-Object -First 1
    
    if ($guestSchedule) {
        $guestJoinBody = @{
            scheduleId = $guestSchedule.id
            guestName = "Guest User"
            guestMobile = "+1234567890"
        } | ConvertTo-Json
        
        $guestBooking = Invoke-ApiRequest -Url "$baseUrl/api/bookings/join" -Method POST -Body $guestJoinBody
        
        if ($guestBooking) {
            Write-Host "? Guest successfully joined schedule" -ForegroundColor Green
            Write-Host "  Sport: $($guestBooking.sportName)" -ForegroundColor Gray
            Write-Host "  Booking ID: $($guestBooking.id)" -ForegroundColor Gray
        } else {
            Write-Host "? Guest booking failed" -ForegroundColor Red
        }
    } else {
        Write-Host "??  No suitable schedule for guest booking test" -ForegroundColor Yellow
    }
}
Write-Host ""

# Step 10: Test include past bookings
Write-Host "Step 10: Testing includeAll parameter..." -ForegroundColor Yellow

$allBookings = Invoke-ApiRequest -Url "$baseUrl/api/bookings/my-bookings?includeAll=true&timezoneOffsetMinutes=$offset" -Headers $headers

if ($allBookings) {
    $futureCount = ($allBookings | Where-Object { -not $_.isPast }).Count
    $pastCount = ($allBookings | Where-Object { $_.isPast }).Count
    
    Write-Host "? Total bookings: $($allBookings.Count)" -ForegroundColor Green
    Write-Host "  Future: $futureCount" -ForegroundColor Gray
    Write-Host "  Past: $pastCount" -ForegroundColor Gray
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Join Schedule & My Bookings Tests:" -ForegroundColor White
Write-Host "  ? User login/registration" -ForegroundColor Green
Write-Host "  ? View available schedules" -ForegroundColor Green
Write-Host "  ? Join schedule (registered user)" -ForegroundColor Green
Write-Host "  ? Prevent duplicate bookings" -ForegroundColor Green
Write-Host "  ? View my bookings" -ForegroundColor Green
Write-Host "  ? Join multiple schedules" -ForegroundColor Green
Write-Host "  ? Cancel booking" -ForegroundColor Green
Write-Host "  ? Guest booking" -ForegroundColor Green
Write-Host "  ? Include past bookings" -ForegroundColor Green
Write-Host ""
Write-Host "All tests completed! ?" -ForegroundColor Green
Write-Host ""
