# Play Oh Canada API - Quick Test Script
# This script tests the authentication endpoints

$baseUrl = "https://localhost:7063/api"
$testEmail = "test@example.com"
$testPassword = "Test@123456"

Write-Host "Play Oh Canada API - Testing Authentication" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""

# Ignore SSL certificate errors for local testing
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

Write-Host "1. Testing User Registration..." -ForegroundColor Yellow
$registerBody = @{
    name = "Test User"
    email = $testEmail
    phone = "+1234567890"
    password = $testPassword
    confirmPassword = $testPassword
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -Body $registerBody -ContentType "application/json" -SkipCertificateCheck
    Write-Host "? Registration successful!" -ForegroundColor Green
    Write-Host "  User ID: $($registerResponse.userId)" -ForegroundColor Cyan
    Write-Host "  Token: $($registerResponse.token.Substring(0, 50))..." -ForegroundColor Cyan
    $token = $registerResponse.token
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "  User already exists, proceeding to login..." -ForegroundColor Yellow
    } else {
        Write-Host "? Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "2. Testing User Login..." -ForegroundColor Yellow
$loginBody = @{
    email = $testEmail
    password = $testPassword
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json" -SkipCertificateCheck
    Write-Host "? Login successful!" -ForegroundColor Green
    Write-Host "  User: $($loginResponse.name)" -ForegroundColor Cyan
    Write-Host "  Role: $($loginResponse.role)" -ForegroundColor Cyan
    Write-Host "  Token expires: $($loginResponse.expiresAt)" -ForegroundColor Cyan
    $token = $loginResponse.token
} catch {
    Write-Host "? Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Testing Get Current User (with JWT token)..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    $meResponse = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method Get -Headers $headers -SkipCertificateCheck
    Write-Host "? Successfully retrieved user profile!" -ForegroundColor Green
    Write-Host "  ID: $($meResponse.id)" -ForegroundColor Cyan
    Write-Host "  Name: $($meResponse.name)" -ForegroundColor Cyan
    Write-Host "  Email: $($meResponse.email)" -ForegroundColor Cyan
    Write-Host "  Role: $($meResponse.role)" -ForegroundColor Cyan
} catch {
    Write-Host "? Failed to get user profile: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "4. Testing Protected Weather Endpoint..." -ForegroundColor Yellow
try {
    $weatherResponse = Invoke-RestMethod -Uri "$baseUrl/weatherforecast" -Method Get -Headers $headers -SkipCertificateCheck
    Write-Host "? Successfully accessed protected endpoint!" -ForegroundColor Green
    Write-Host "  Received $($weatherResponse.Count) weather forecasts" -ForegroundColor Cyan
} catch {
    Write-Host "? Failed to access protected endpoint: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "5. Testing Public Endpoint (no auth)..." -ForegroundColor Yellow
try {
    $publicResponse = Invoke-RestMethod -Uri "$baseUrl/weatherforecast/public" -Method Get -SkipCertificateCheck
    Write-Host "? Successfully accessed public endpoint!" -ForegroundColor Green
    Write-Host "  Temperature: $($publicResponse.temperatureC)°C" -ForegroundColor Cyan
} catch {
    Write-Host "? Failed to access public endpoint: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "All tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Your JWT Token (valid for 24 hours in dev):" -ForegroundColor Yellow
Write-Host $token -ForegroundColor White
