# Railway Deployment Test Script
# Quick verification of database migration and API functionality

param(
    [Parameter(Mandatory=$true)]
    [string]$RailwayUrl
)

Write-Host "?? Testing Railway Deployment for Play Oh Canada API" -ForegroundColor Cyan
Write-Host "URL: $RailwayUrl" -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check (Scalar UI)
Write-Host "Test 1: Health Check (Scalar UI)" -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri "$RailwayUrl/scalar/v1" -Method Get -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "? Scalar UI is accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "? Scalar UI not accessible: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Check Seeded Sports
Write-Host "Test 2: Verify Sports Seeding" -ForegroundColor Green
try {
    $sports = Invoke-RestMethod -Uri "$RailwayUrl/api/sports" -Method Get
    Write-Host "? Sports API returned $($sports.Count) sports" -ForegroundColor Green
    
    if ($sports.Count -eq 6) {
        Write-Host "? Expected 6 sports found!" -ForegroundColor Green
        $sports | ForEach-Object { Write-Host "   - $($_.name)" -ForegroundColor Gray }
    } else {
        Write-Host "??  Warning: Expected 6 sports, found $($sports.Count)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "? Sports API failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Admin Login
Write-Host "Test 3: Admin User Login" -ForegroundColor Green
try {
    $loginBody = @{
        email = "admin@playohcanada.com"
        password = "Admin@123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$RailwayUrl/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    
    if ($loginResponse.token) {
        Write-Host "? Admin login successful" -ForegroundColor Green
        Write-Host "   Token (first 20 chars): $($loginResponse.token.Substring(0, 20))..." -ForegroundColor Gray
        $global:adminToken = $loginResponse.token
    }
} catch {
    Write-Host "? Admin login failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: User Registration
Write-Host "Test 4: User Registration" -ForegroundColor Green
$testEmail = "test.user.$(Get-Random -Minimum 1000 -Maximum 9999)@example.com"
try {
    $registerBody = @{
        name = "Test User"
        email = $testEmail
        phone = "1234567890"
        password = "Test@123"
    } | ConvertTo-Json

    $registerResponse = Invoke-RestMethod -Uri "$RailwayUrl/api/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
    
    if ($registerResponse.token) {
        Write-Host "? User registration successful" -ForegroundColor Green
        Write-Host "   Email: $testEmail" -ForegroundColor Gray
        $global:userToken = $registerResponse.token
    }
} catch {
    Write-Host "? User registration failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 5: Create Schedule (Admin Only)
if ($global:adminToken) {
    Write-Host "Test 5: Create Schedule (Admin)" -ForegroundColor Green
    try {
        $scheduleBody = @{
            sportId = 1
            venue = "Test Court"
            startDate = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
            startTime = "18:00:00"
            endTime = "19:00:00"
            maxPlayers = 4
            equipmentDetails = "Bring your own racket"
            timezoneOffsetMinutes = -300
        } | ConvertTo-Json

        $headers = @{
            Authorization = "Bearer $global:adminToken"
        }

        $scheduleResponse = Invoke-RestMethod -Uri "$RailwayUrl/api/schedules" -Method Post -Body $scheduleBody -ContentType "application/json" -Headers $headers
        
        if ($scheduleResponse.id) {
            Write-Host "? Schedule created successfully" -ForegroundColor Green
            Write-Host "   Schedule ID: $($scheduleResponse.id)" -ForegroundColor Gray
            Write-Host "   Venue: $($scheduleResponse.venue)" -ForegroundColor Gray
            $global:scheduleId = $scheduleResponse.id
        }
    } catch {
        Write-Host "? Schedule creation failed: $_" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 6: Join Schedule (User)
if ($global:userToken -and $global:scheduleId) {
    Write-Host "Test 6: Join Schedule (User)" -ForegroundColor Green
    try {
        $bookingBody = @{
            scheduleId = $global:scheduleId
        } | ConvertTo-Json

        $headers = @{
            Authorization = "Bearer $global:userToken"
        }

        $bookingResponse = Invoke-RestMethod -Uri "$RailwayUrl/api/bookings/join" -Method Post -Body $bookingBody -ContentType "application/json" -Headers $headers
        
        if ($bookingResponse.id) {
            Write-Host "? Booking created successfully" -ForegroundColor Green
            Write-Host "   Booking ID: $($bookingResponse.id)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "? Booking failed: $_" -ForegroundColor Red
    }
    Write-Host ""
}

# Summary
Write-Host "?????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?? Test Summary" -ForegroundColor Cyan
Write-Host "?????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "? Migration Status: " -NoNewline -ForegroundColor Green
if ($sports.Count -eq 6) {
    Write-Host "SUCCESS - All 6 sports seeded" -ForegroundColor Green
} else {
    Write-Host "CHECK LOGS - Seeding may be incomplete" -ForegroundColor Yellow
}

Write-Host "? Authentication: " -NoNewline -ForegroundColor Green
if ($global:adminToken -and $global:userToken) {
    Write-Host "SUCCESS - Both admin and user auth working" -ForegroundColor Green
} else {
    Write-Host "PARTIAL - Check logs for issues" -ForegroundColor Yellow
}

Write-Host "? Database Tables: " -NoNewline -ForegroundColor Green
Write-Host "Created (verify via Railway PostgreSQL)" -ForegroundColor Gray

Write-Host ""
Write-Host "?? Next Steps:" -ForegroundColor Cyan
Write-Host "1. Check Railway logs for migration details" -ForegroundColor White
Write-Host "2. Visit $RailwayUrl/scalar/v1 for API documentation" -ForegroundColor White
Write-Host "3. Connect to Railway PostgreSQL to verify tables" -ForegroundColor White
Write-Host "4. Update your frontend CORS settings" -ForegroundColor White
Write-Host ""

# Output credentials for reference
Write-Host "?? Test Credentials:" -ForegroundColor Cyan
Write-Host "Admin Email: admin@playohcanada.com" -ForegroundColor Gray
Write-Host "Admin Password: Admin@123" -ForegroundColor Gray
Write-Host "Test User Email: $testEmail" -ForegroundColor Gray
Write-Host "Test User Password: Test@123" -ForegroundColor Gray
Write-Host ""
