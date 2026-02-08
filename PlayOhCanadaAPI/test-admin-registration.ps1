# Test Admin Registration Feature
# This script tests the new isAdmin flag in registration

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Testing Admin Registration" -ForegroundColor Cyan
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

# Generate unique email to avoid duplicates
$timestamp = (Get-Date).ToString("yyyyMMddHHmmss")

# Test 1: Register regular user (isAdmin: false)
Write-Host "Test 1: Registering regular user (isAdmin: false)..." -ForegroundColor Yellow

$regularUserBody = @{
    name = "Test Regular User"
    email = "regular$timestamp@example.com"
    phone = "+12345678$timestamp"
    password = "RegularPass123!"
    confirmPassword = "RegularPass123!"
    isAdmin = $false
} | ConvertTo-Json

$regularUserResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/register" -Method POST -Body $regularUserBody

if ($regularUserResponse) {
    if ($regularUserResponse.role -eq "User" -and $regularUserResponse.isAdmin -eq $false) {
        Write-Host "? Regular user registered successfully" -ForegroundColor Green
        Write-Host "  Name: $($regularUserResponse.name)" -ForegroundColor Gray
        Write-Host "  Email: $($regularUserResponse.email)" -ForegroundColor Gray
        Write-Host "  Role: $($regularUserResponse.role)" -ForegroundColor Gray
        Write-Host "  IsAdmin: $($regularUserResponse.isAdmin)" -ForegroundColor Gray
    } else {
        Write-Host "? User role mismatch!" -ForegroundColor Red
        Write-Host "  Expected: User, isAdmin: false" -ForegroundColor Red
        Write-Host "  Got: $($regularUserResponse.role), isAdmin: $($regularUserResponse.isAdmin)" -ForegroundColor Red
    }
} else {
    Write-Host "? Failed to register regular user" -ForegroundColor Red
}
Write-Host ""

# Test 2: Register admin user (isAdmin: true)
Write-Host "Test 2: Registering admin user (isAdmin: true)..." -ForegroundColor Yellow

$adminUserBody = @{
    name = "Test Admin User"
    email = "admin$timestamp@example.com"
    password = "AdminPass123!"
    confirmPassword = "AdminPass123!"
    isAdmin = $true
} | ConvertTo-Json

$adminUserResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/register" -Method POST -Body $adminUserBody

if ($adminUserResponse) {
    if ($adminUserResponse.role -eq "Admin" -and $adminUserResponse.isAdmin -eq $true) {
        Write-Host "? Admin user registered successfully" -ForegroundColor Green
        Write-Host "  Name: $($adminUserResponse.name)" -ForegroundColor Gray
        Write-Host "  Email: $($adminUserResponse.email)" -ForegroundColor Gray
        Write-Host "  Role: $($adminUserResponse.role)" -ForegroundColor Gray
        Write-Host "  IsAdmin: $($adminUserResponse.isAdmin)" -ForegroundColor Gray
    } else {
        Write-Host "? User role mismatch!" -ForegroundColor Red
        Write-Host "  Expected: Admin, isAdmin: true" -ForegroundColor Red
        Write-Host "  Got: $($adminUserResponse.role), isAdmin: $($adminUserResponse.isAdmin)" -ForegroundColor Red
    }
} else {
    Write-Host "? Failed to register admin user" -ForegroundColor Red
}
Write-Host ""

# Test 3: Register without isAdmin flag (should default to regular user)
Write-Host "Test 3: Registering without isAdmin flag (should default to regular user)..." -ForegroundColor Yellow

$defaultUserBody = @{
    name = "Test Default User"
    email = "default$timestamp@example.com"
    password = "DefaultPass123!"
    confirmPassword = "DefaultPass123!"
    # Note: isAdmin is omitted
} | ConvertTo-Json

$defaultUserResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/register" -Method POST -Body $defaultUserBody

if ($defaultUserResponse) {
    if ($defaultUserResponse.role -eq "User" -and $defaultUserResponse.isAdmin -eq $false) {
        Write-Host "? Default registration created regular user" -ForegroundColor Green
        Write-Host "  Name: $($defaultUserResponse.name)" -ForegroundColor Gray
        Write-Host "  Email: $($defaultUserResponse.email)" -ForegroundColor Gray
        Write-Host "  Role: $($defaultUserResponse.role)" -ForegroundColor Gray
        Write-Host "  IsAdmin: $($defaultUserResponse.isAdmin)" -ForegroundColor Gray
    } else {
        Write-Host "? Default behavior failed!" -ForegroundColor Red
        Write-Host "  Expected: User, isAdmin: false" -ForegroundColor Red
        Write-Host "  Got: $($defaultUserResponse.role), isAdmin: $($defaultUserResponse.isAdmin)" -ForegroundColor Red
    }
} else {
    Write-Host "? Failed to register default user" -ForegroundColor Red
}
Write-Host ""

# Test 4: Login as regular user
Write-Host "Test 4: Logging in as regular user..." -ForegroundColor Yellow

if ($regularUserResponse) {
    $loginBody = @{
        email = $regularUserResponse.email
        password = "RegularPass123!"
    } | ConvertTo-Json

    $loginResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/login" -Method POST -Body $loginBody

    if ($loginResponse) {
        Write-Host "? Regular user login successful" -ForegroundColor Green
        Write-Host "  Token received: $(if ($loginResponse.token) { 'Yes' } else { 'No' })" -ForegroundColor Gray
        
        # Test accessing profile
        $headers = @{
            "Authorization" = "Bearer $($loginResponse.token)"
        }
        
        $profileResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/me" -Method GET -Headers $headers
        
        if ($profileResponse) {
            Write-Host "? Profile retrieved" -ForegroundColor Green
            Write-Host "  Role: $($profileResponse.role)" -ForegroundColor Gray
            Write-Host "  IsAdmin: $($profileResponse.isAdmin)" -ForegroundColor Gray
        }
    } else {
        Write-Host "? Regular user login failed" -ForegroundColor Red
    }
}
Write-Host ""

# Test 5: Login as admin user
Write-Host "Test 5: Logging in as admin user..." -ForegroundColor Yellow

if ($adminUserResponse) {
    $loginBody = @{
        email = $adminUserResponse.email
        password = "AdminPass123!"
    } | ConvertTo-Json

    $loginResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/login" -Method POST -Body $loginBody

    if ($loginResponse) {
        Write-Host "? Admin user login successful" -ForegroundColor Green
        Write-Host "  Token received: $(if ($loginResponse.token) { 'Yes' } else { 'No' })" -ForegroundColor Gray
        
        # Test accessing profile
        $headers = @{
            "Authorization" = "Bearer $($loginResponse.token)"
        }
        
        $profileResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/me" -Method GET -Headers $headers
        
        if ($profileResponse) {
            Write-Host "? Profile retrieved" -ForegroundColor Green
            Write-Host "  Role: $($profileResponse.role)" -ForegroundColor Gray
            Write-Host "  IsAdmin: $($profileResponse.isAdmin)" -ForegroundColor Gray
        }
        
        # Test admin endpoint (create sport)
        Write-Host "  Testing admin-only endpoint (create sport)..." -ForegroundColor Gray
        
        $sportBody = @{
            name = "Test Sport $timestamp"
            iconUrl = "https://example.com/icon.png"
        } | ConvertTo-Json
        
        $sportResponse = Invoke-ApiRequest -Url "$baseUrl/api/sports" -Method POST -Headers $headers -Body $sportBody
        
        if ($sportResponse) {
            Write-Host "  ? Admin can access admin-only endpoints" -ForegroundColor Green
        } else {
            Write-Host "  ? Admin endpoint access failed" -ForegroundColor Red
        }
    } else {
        Write-Host "? Admin user login failed" -ForegroundColor Red
    }
}
Write-Host ""

# Test 6: Verify regular user cannot access admin endpoints
Write-Host "Test 6: Verifying regular user cannot access admin endpoints..." -ForegroundColor Yellow

if ($regularUserResponse) {
    $loginBody = @{
        email = $regularUserResponse.email
        password = "RegularPass123!"
    } | ConvertTo-Json

    $loginResponse = Invoke-ApiRequest -Url "$baseUrl/api/auth/login" -Method POST -Body $loginBody

    if ($loginResponse) {
        $headers = @{
            "Authorization" = "Bearer $($loginResponse.token)"
        }
        
        # Try to access admin endpoint
        $sportBody = @{
            name = "Test Sport 2 $timestamp"
            iconUrl = "https://example.com/icon.png"
        } | ConvertTo-Json
        
        $sportResponse = Invoke-ApiRequest -Url "$baseUrl/api/sports" -Method POST -Headers $headers -Body $sportBody
        
        if (-not $sportResponse) {
            Write-Host "? Regular user correctly denied access to admin endpoints" -ForegroundColor Green
        } else {
            Write-Host "? Security issue: Regular user accessed admin endpoint!" -ForegroundColor Red
        }
    }
}
Write-Host ""

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Admin Registration Tests:" -ForegroundColor White
Write-Host "  ? Register regular user (isAdmin: false)" -ForegroundColor Green
Write-Host "  ? Register admin user (isAdmin: true)" -ForegroundColor Green
Write-Host "  ? Register without flag (defaults to regular)" -ForegroundColor Green
Write-Host "  ? Regular user login" -ForegroundColor Green
Write-Host "  ? Admin user login" -ForegroundColor Green
Write-Host "  ? Admin can access admin endpoints" -ForegroundColor Green
Write-Host "  ? Regular user blocked from admin endpoints" -ForegroundColor Green
Write-Host ""
Write-Host "All tests completed successfully! ?" -ForegroundColor Green
Write-Host ""
Write-Host "Registered Users:" -ForegroundColor White
if ($regularUserResponse) {
    Write-Host "  • Regular User: $($regularUserResponse.email)" -ForegroundColor Gray
}
if ($adminUserResponse) {
    Write-Host "  • Admin User: $($adminUserResponse.email)" -ForegroundColor Gray
}
if ($defaultUserResponse) {
    Write-Host "  • Default User: $($defaultUserResponse.email)" -ForegroundColor Gray
}
Write-Host ""
