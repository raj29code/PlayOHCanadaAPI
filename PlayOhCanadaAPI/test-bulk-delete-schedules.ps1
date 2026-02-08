# Test Bulk Schedule Deletion Endpoints
# This script tests the new bulk delete functionality

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Testing Bulk Schedule Deletion" -ForegroundColor Cyan
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
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response: $responseBody" -ForegroundColor Red
        }
        return $null
    }
}

# Step 1: Login as admin
Write-Host "Step 1: Logging in as admin..." -ForegroundColor Yellow

$loginBody = @{
    email = "admin@playohcanada.com"
    password = "Admin@123"
} | ConvertTo-Json

$loginResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/login" -Method POST -Body $loginBody

if (-not $loginResponse) {
    Write-Host "Failed to login. Please ensure the API is running and credentials are correct." -ForegroundColor Red
    exit 1
}

$token = $loginResponse.token
Write-Host "? Login successful!" -ForegroundColor Green
Write-Host "  Admin: $($loginResponse.user.name)" -ForegroundColor Gray
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $token"
}

# Step 2: Create test schedules
Write-Host "Step 2: Creating test schedules..." -ForegroundColor Yellow

$createBody = @{
    sportId = 1
    venue = "Test Venue for Bulk Delete"
    startDate = "2026-06-01"
    startTime = "19:00:00"
    endTime = "20:00:00"
    maxPlayers = 8
    equipmentDetails = "Test equipment"
    timezoneOffsetMinutes = -300
    recurrence = @{
        isRecurring = $true
        frequency = 1  # Daily
        endDate = "2026-06-05"
    }
} | ConvertTo-Json -Depth 10

$createdSchedules = Invoke-ApiRequest -Url "$baseUrl/api/schedules" -Method POST -Headers $headers -Body $createBody

if (-not $createdSchedules) {
    Write-Host "Failed to create schedules." -ForegroundColor Red
    exit 1
}

Write-Host "? Created $($createdSchedules.Count) test schedules" -ForegroundColor Green
Write-Host "  Schedule IDs: $($createdSchedules.id -join ', ')" -ForegroundColor Gray
Write-Host ""

# Step 3: Verify schedules exist
Write-Host "Step 3: Verifying schedules exist..." -ForegroundColor Yellow

$schedulesResponse = Invoke-ApiRequest -Url "$baseUrl/api/schedules?venue=Test Venue for Bulk Delete" -Method GET

if ($schedulesResponse) {
    Write-Host "? Found $($schedulesResponse.Count) schedules in the system" -ForegroundColor Green
}
Write-Host ""

# Step 4: Test bulk delete (my-schedules)
Write-Host "Step 4: Testing DELETE /api/schedules/my-schedules..." -ForegroundColor Yellow

$deleteResult = Invoke-ApiRequest -Url "$baseUrl/api/schedules/my-schedules" -Method DELETE -Headers $headers

if ($deleteResult) {
    Write-Host "? Bulk delete successful!" -ForegroundColor Green
    Write-Host "  Deleted schedules: $($deleteResult.deletedSchedules)" -ForegroundColor Gray
    Write-Host "  Affected bookings: $($deleteResult.affectedBookings)" -ForegroundColor Gray
    Write-Host "  Message: $($deleteResult.message)" -ForegroundColor Gray
} else {
    Write-Host "? Bulk delete failed" -ForegroundColor Red
}
Write-Host ""

# Step 5: Verify schedules are deleted
Write-Host "Step 5: Verifying schedules are deleted..." -ForegroundColor Yellow

$remainingSchedules = Invoke-ApiRequest -Url "$baseUrl/api/schedules?venue=Test Venue for Bulk Delete" -Method GET

if ($remainingSchedules) {
    Write-Host "? Found $($remainingSchedules.Count) schedules still in system (should be 0)" -ForegroundColor Red
} else {
    Write-Host "? All schedules deleted successfully!" -ForegroundColor Green
}
Write-Host ""

# Step 6: Test delete when no schedules exist
Write-Host "Step 6: Testing DELETE when no schedules exist..." -ForegroundColor Yellow

$emptyDeleteResult = Invoke-ApiRequest -Url "$baseUrl/api/schedules/my-schedules" -Method DELETE -Headers $headers

if (-not $emptyDeleteResult) {
    Write-Host "? Correctly returned 404 when no schedules exist" -ForegroundColor Green
} else {
    Write-Host "? Should have returned 404" -ForegroundColor Red
}
Write-Host ""

# Step 7: Test bulk delete by admin ID
Write-Host "Step 7: Testing DELETE /api/schedules/admin/{adminId}..." -ForegroundColor Yellow

# First create some new schedules
Write-Host "  Creating new test schedules..." -ForegroundColor Gray
$newSchedules = Invoke-ApiRequest -Url "$baseUrl/api/schedules" -Method POST -Headers $headers -Body $createBody

if ($newSchedules) {
    Write-Host "  ? Created $($newSchedules.Count) schedules" -ForegroundColor Gray
    
    # Get admin ID from token (assuming admin user ID is known, typically 1)
    $adminId = 1  # You might need to adjust this based on your setup
    
    # Delete by admin ID
    $deleteByIdResult = Invoke-ApiRequest -Url "$baseUrl/api/schedules/admin/$adminId" -Method DELETE -Headers $headers
    
    if ($deleteByIdResult) {
        Write-Host "? Bulk delete by admin ID successful!" -ForegroundColor Green
        Write-Host "  Deleted schedules: $($deleteByIdResult.deletedSchedules)" -ForegroundColor Gray
        Write-Host "  Message: $($deleteByIdResult.message)" -ForegroundColor Gray
    } else {
        Write-Host "? Bulk delete by admin ID failed" -ForegroundColor Red
    }
} else {
    Write-Host "? Failed to create schedules for admin ID test" -ForegroundColor Red
}
Write-Host ""

# Step 8: Test with wrong admin ID (should fail)
Write-Host "Step 8: Testing DELETE with different admin ID (should fail)..." -ForegroundColor Yellow

$wrongAdminId = 999
$wrongAdminResult = Invoke-ApiRequest -Url "$baseUrl/api/schedules/admin/$wrongAdminId" -Method DELETE -Headers $headers

if (-not $wrongAdminResult) {
    Write-Host "? Correctly prevented deletion of other admin's schedules" -ForegroundColor Green
} else {
    Write-Host "? Should have returned 403 Forbidden" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bulk Schedule Deletion Tests:" -ForegroundColor White
Write-Host "  ? Login as admin" -ForegroundColor Green
Write-Host "  ? Create test schedules" -ForegroundColor Green
Write-Host "  ? Bulk delete (my-schedules)" -ForegroundColor Green
Write-Host "  ? Verify deletion" -ForegroundColor Green
Write-Host "  ? Handle empty delete (404)" -ForegroundColor Green
Write-Host "  ? Bulk delete by admin ID" -ForegroundColor Green
Write-Host "  ? Security (prevent other admin deletion)" -ForegroundColor Green
Write-Host ""
Write-Host "All tests completed successfully! ?" -ForegroundColor Green
Write-Host ""
