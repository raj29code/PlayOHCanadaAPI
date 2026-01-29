# Test script for logout feature
$baseUrl = "http://localhost:5000/api"

Write-Host "=== Testing Logout Feature ===" -ForegroundColor Cyan
Write-Host ""

# 1. Login first
Write-Host "Step 1: Logging in..." -ForegroundColor Yellow
$loginBody = @{
    email = "admin@playohcanada.com"
    password = "Admin@123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    Write-Host "? Login successful!" -ForegroundColor Green
    Write-Host "User: $($loginResponse.name)" -ForegroundColor Gray
    Write-Host "Token: $($token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Login failed: $_" -ForegroundColor Red
    exit 1
}

# 2. Get current user with token
Write-Host "Step 2: Getting current user profile..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $token"
}

try {
    $userResponse = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method Get -Headers $headers
    Write-Host "? User profile retrieved!" -ForegroundColor Green
    Write-Host "Name: $($userResponse.name)" -ForegroundColor Gray
    Write-Host "Email: $($userResponse.email)" -ForegroundColor Gray
    Write-Host "IsAdmin: $($userResponse.isAdmin)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Failed to get user profile: $_" -ForegroundColor Red
    exit 1
}

# 3. Logout
Write-Host "Step 3: Logging out..." -ForegroundColor Yellow
try {
    $logoutResponse = Invoke-RestMethod -Uri "$baseUrl/auth/logout" -Method Post -Headers $headers
    Write-Host "? Logout successful!" -ForegroundColor Green
    Write-Host "Message: $($logoutResponse.message)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Logout failed: $_" -ForegroundColor Red
    exit 1
}

# 4. Try to use the same token again (should fail)
Write-Host "Step 4: Attempting to use revoked token..." -ForegroundColor Yellow
try {
    $retryResponse = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method Get -Headers $headers
    Write-Host "? ERROR: Revoked token was accepted!" -ForegroundColor Red
    Write-Host "The token should have been rejected." -ForegroundColor Red
    exit 1
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "? Revoked token correctly rejected!" -ForegroundColor Green
        Write-Host "Status: 401 Unauthorized (as expected)" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "? Unexpected error: $_" -ForegroundColor Red
        exit 1
    }
}

# 5. Login again to verify we can still login
Write-Host "Step 5: Logging in again with same credentials..." -ForegroundColor Yellow
try {
    $newLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $newToken = $newLoginResponse.token
    Write-Host "? New login successful!" -ForegroundColor Green
    Write-Host "New Token: $($newToken.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? Re-login failed: $_" -ForegroundColor Red
    exit 1
}

# 6. Verify new token works
Write-Host "Step 6: Verifying new token works..." -ForegroundColor Yellow
$newHeaders = @{
    "Authorization" = "Bearer $newToken"
}

try {
    $finalUserResponse = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method Get -Headers $newHeaders
    Write-Host "? New token works correctly!" -ForegroundColor Green
    Write-Host "User: $($finalUserResponse.name)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "? New token verification failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "=== All Logout Tests Passed! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "? Login successful" -ForegroundColor Green
Write-Host "? User profile retrieved with token" -ForegroundColor Green
Write-Host "? Logout successful" -ForegroundColor Green
Write-Host "? Revoked token correctly rejected" -ForegroundColor Green
Write-Host "? Re-login successful" -ForegroundColor Green
Write-Host "? New token works correctly" -ForegroundColor Green
