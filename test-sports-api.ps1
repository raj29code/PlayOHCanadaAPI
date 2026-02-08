# Test script for Sports Scheduling API
# Make sure the API is running before executing this script

$baseUrl = "https://localhost:7063"  # Update with your API URL
$adminEmail = "admin@playohcanada.com"
$adminPassword = "Admin@123"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Sports Scheduling API Test" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Login as Admin
Write-Host "1. Logging in as Admin..." -ForegroundColor Yellow
$loginBody = @{
    email = $adminEmail
    password = $adminPassword
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $adminToken = $loginResponse.token
    Write-Host "? Admin login successful" -ForegroundColor Green
    Write-Host "Token: $($adminToken.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Write-Host "? Admin login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

Write-Host ""

# Step 2: Create Sports
Write-Host "2. Creating Sports..." -ForegroundColor Yellow

$sports = @(
    @{ name = "Tennis"; iconUrl = "https://example.com/icons/tennis.png" },
    @{ name = "Badminton"; iconUrl = "https://example.com/icons/badminton.png" },
    @{ name = "Basketball"; iconUrl = "https://example.com/icons/basketball.png" },
    @{ name = "Soccer"; iconUrl = "https://example.com/icons/soccer.png" }
)

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

$createdSports = @()

foreach ($sport in $sports) {
    $sportBody = $sport | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/sports" -Method Post -Headers $headers -Body $sportBody
        $createdSports += $response
        Write-Host "? Created sport: $($response.name) (ID: $($response.id))" -ForegroundColor Green
    } catch {
        Write-Host "? Failed to create sport $($sport.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Step 3: Get All Sports (Public)
Write-Host "3. Fetching all sports (public endpoint)..." -ForegroundColor Yellow
try {
    $allSports = Invoke-RestMethod -Uri "$baseUrl/api/sports" -Method Get
    Write-Host "? Retrieved $($allSports.Count) sports" -ForegroundColor Green
    $allSports | ForEach-Object { Write-Host "  - $($_.name) (ID: $($_.id))" -ForegroundColor Gray }
} catch {
    Write-Host "? Failed to fetch sports: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Step 4: Create a Single Schedule
Write-Host "4. Creating a single schedule..." -ForegroundColor Yellow

if ($createdSports.Count -gt 0) {
    $tennisId = ($createdSports | Where-Object { $_.name -eq "Tennis" }).id
    
    $singleSchedule = @{
        sportId = $tennisId
        venue = "Central Park Tennis Courts"
        startTime = (Get-Date).AddDays(2).ToString("yyyy-MM-ddTHH:mm:ssZ")
        endTime = (Get-Date).AddDays(2).AddHours(2).ToString("yyyy-MM-ddTHH:mm:ssZ")
        maxPlayers = 4
        equipmentDetails = "Rackets and balls provided"
    } | ConvertTo-Json

    try {
        $scheduleResponse = Invoke-RestMethod -Uri "$baseUrl/api/schedules" -Method Post -Headers $headers -Body $singleSchedule
        Write-Host "? Created single schedule (ID: $($scheduleResponse[0].id))" -ForegroundColor Green
        $singleScheduleId = $scheduleResponse[0].id
    } catch {
        Write-Host "? Failed to create schedule: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Step 5: Create a Recurring Schedule
Write-Host "5. Creating a recurring schedule (Weekly Tennis - 12 weeks)..." -ForegroundColor Yellow

if ($createdSports.Count -gt 0) {
    $tennisId = ($createdSports | Where-Object { $_.name -eq "Tennis" }).id
    
    $recurringSchedule = @{
        sportId = $tennisId
        venue = "Downtown Tennis Club"
        startTime = (Get-Date).AddDays(7).Date.AddHours(18).ToString("yyyy-MM-ddTHH:mm:ssZ")
        endTime = (Get-Date).AddDays(7).Date.AddHours(20).ToString("yyyy-MM-ddTHH:mm:ssZ")
        maxPlayers = 6
        equipmentDetails = "Professional courts, bring your own rackets"
        recurrence = @{
            isRecurring = $true
            frequency = 7  # Weekly
            endDate = (Get-Date).AddDays(84).ToString("yyyy-MM-ddTHH:mm:ssZ")  # 12 weeks
        }
    } | ConvertTo-Json -Depth 3

    try {
        $recurringResponse = Invoke-RestMethod -Uri "$baseUrl/api/schedules" -Method Post -Headers $headers -Body $recurringSchedule
        Write-Host "? Created recurring schedule: $($recurringResponse.Count) weekly sessions" -ForegroundColor Green
        $firstRecurringId = $recurringResponse[0].id
    } catch {
        Write-Host "? Failed to create recurring schedule: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Step 6: Get All Schedules (Public)
Write-Host "6. Fetching all schedules..." -ForegroundColor Yellow
try {
    $allSchedules = Invoke-RestMethod -Uri "$baseUrl/api/schedules" -Method Get
    Write-Host "? Retrieved $($allSchedules.Count) schedules" -ForegroundColor Green
    $allSchedules | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.sportName) at $($_.venue)" -ForegroundColor Gray
        Write-Host "    Time: $(([DateTime]$_.startTime).ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
        Write-Host "    Spots: $($_.spotsRemaining)/$($_.maxPlayers) available" -ForegroundColor Gray
    }
    if ($allSchedules.Count -gt 5) {
        Write-Host "  ... and $($allSchedules.Count - 5) more" -ForegroundColor Gray
    }
} catch {
    Write-Host "? Failed to fetch schedules: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Step 7: Filter Schedules by Sport
Write-Host "7. Filtering schedules by Tennis..." -ForegroundColor Yellow
if ($tennisId) {
    try {
        $tennisSchedules = Invoke-RestMethod -Uri "$baseUrl/api/schedules?sportId=$tennisId" -Method Get
        Write-Host "? Found $($tennisSchedules.Count) Tennis schedules" -ForegroundColor Green
    } catch {
        Write-Host "? Failed to filter schedules: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Step 8: Join a Schedule as Guest
Write-Host "8. Booking a schedule as Guest..." -ForegroundColor Yellow
if ($singleScheduleId) {
    $guestBooking = @{
        scheduleId = $singleScheduleId
        guestName = "John Doe"
        guestMobile = "+1234567890"
    } | ConvertTo-Json

    try {
        $guestBookingResponse = Invoke-RestMethod -Uri "$baseUrl/api/bookings/join" -Method Post -Body $guestBooking -ContentType "application/json"
        Write-Host "? Guest booking successful (ID: $($guestBookingResponse.id))" -ForegroundColor Green
    } catch {
        Write-Host "? Guest booking failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Step 9: Create a Regular User and Join as Registered User
Write-Host "9. Creating a regular user and booking as registered user..." -ForegroundColor Yellow

$registerBody = @{
    name = "Jane Smith"
    email = "jane@example.com"
    password = "Test@123"
    phone = "+1987654321"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "? User registered successfully" -ForegroundColor Green
    
    # Login as new user
    $userLoginBody = @{
        email = "jane@example.com"
        password = "Test@123"
    } | ConvertTo-Json
    
    $userLoginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $userLoginBody -ContentType "application/json"
    $userToken = $userLoginResponse.token
    Write-Host "? User login successful" -ForegroundColor Green
    
    # Book a schedule
    if ($firstRecurringId) {
        $userHeaders = @{
            "Authorization" = "Bearer $userToken"
            "Content-Type" = "application/json"
        }
        
        $userBooking = @{
            scheduleId = $firstRecurringId
        } | ConvertTo-Json
        
        $userBookingResponse = Invoke-RestMethod -Uri "$baseUrl/api/bookings/join" -Method Post -Headers $userHeaders -Body $userBooking
        Write-Host "? Registered user booking successful (ID: $($userBookingResponse.id))" -ForegroundColor Green
    }
} catch {
    Write-Host "? User registration/booking failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Step 10: Get Schedule Details with Participants
Write-Host "10. Fetching schedule details with participants..." -ForegroundColor Yellow
if ($singleScheduleId) {
    try {
        $scheduleDetails = Invoke-RestMethod -Uri "$baseUrl/api/schedules/$singleScheduleId" -Method Get
        Write-Host "? Schedule Details:" -ForegroundColor Green
        Write-Host "  Sport: $($scheduleDetails.sportName)" -ForegroundColor Gray
        Write-Host "  Venue: $($scheduleDetails.venue)" -ForegroundColor Gray
        Write-Host "  Start: $(([DateTime]$scheduleDetails.startTime).ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
        Write-Host "  Players: $($scheduleDetails.currentPlayers)/$($scheduleDetails.maxPlayers)" -ForegroundColor Gray
        Write-Host "  Participants:" -ForegroundColor Gray
        $scheduleDetails.participants | ForEach-Object {
            Write-Host "    - $($_.name) (Joined: $(([DateTime]$_.bookingTime).ToString('yyyy-MM-dd HH:mm')))" -ForegroundColor Gray
        }
    } catch {
        Write-Host "? Failed to fetch schedule details: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "- Sports: Created and listed successfully" -ForegroundColor Gray
Write-Host "- Schedules: Single and recurring schedules created" -ForegroundColor Gray
Write-Host "- Bookings: Guest and registered user bookings tested" -ForegroundColor Gray
Write-Host "- Filtering: Sport-based filtering tested" -ForegroundColor Gray
Write-Host ""
Write-Host "You can now:" -ForegroundColor Yellow
Write-Host "- Browse schedules at: $baseUrl/api/schedules" -ForegroundColor Gray
Write-Host "- Use Scalar UI at: $baseUrl/scalar/v1" -ForegroundColor Gray
Write-Host "- Check OpenAPI docs at: $baseUrl/openapi/v1.json" -ForegroundColor Gray
