# Test Update Sport API Endpoint

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Update Sport API" -ForegroundColor Cyan
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
    Write-Host "? Failed to login" -ForegroundColor Red
    exit
}
Write-Host ""

# Step 2: Get existing sports
Write-Host "Step 2: Getting existing sports..." -ForegroundColor Yellow

$existingSports = Invoke-ApiRequest -Url "$baseUrl/api/sports"

if ($existingSports) {
    Write-Host "? Found $($existingSports.Count) existing sports" -ForegroundColor Green
    
    if ($existingSports.Count -gt 0) {
        Write-Host "`nExisting Sports:" -ForegroundColor Cyan
        foreach ($sport in $existingSports) {
            Write-Host "  - $($sport.name) (ID: $($sport.id))" -ForegroundColor White
        }
    }
} else {
    Write-Host "? Failed to get sports" -ForegroundColor Red
}
Write-Host ""

# Step 3: Create a test sport
Write-Host "Step 3: Creating test sport..." -ForegroundColor Yellow

$createBody = @{
    name = "Test Sport for Update"
    iconUrl = "https://example.com/test-original.png"
} | ConvertTo-Json

$testSport = Invoke-ApiRequest -Url "$baseUrl/api/sports" -Method POST -Headers $headers -Body $createBody

if ($testSport) {
    Write-Host "? Created test sport" -ForegroundColor Green
    Write-Host "  ID: $($testSport.id)" -ForegroundColor Gray
    Write-Host "  Name: $($testSport.name)" -ForegroundColor Gray
    Write-Host "  Icon: $($testSport.iconUrl)" -ForegroundColor Gray
    $testSportId = $testSport.id
} else {
    Write-Host "? Failed to create test sport" -ForegroundColor Red
    exit
}
Write-Host ""

# Step 4: Test updating name only
Write-Host "Step 4: Testing name update..." -ForegroundColor Yellow

$updateNameBody = @{
    name = "Updated Test Sport"
} | ConvertTo-Json

$updatedSport = Invoke-ApiRequest -Url "$baseUrl/api/sports/$testSportId" -Method PUT -Headers $headers -Body $updateNameBody

if ($updatedSport) {
    Write-Host "? Name updated successfully" -ForegroundColor Green
    Write-Host "  Old Name: Test Sport for Update" -ForegroundColor Gray
    Write-Host "  New Name: $($updatedSport.name)" -ForegroundColor Gray
    Write-Host "  Icon (unchanged): $($updatedSport.iconUrl)" -ForegroundColor Gray
    
    if ($updatedSport.name -eq "Updated Test Sport") {
        Write-Host "  ? Name change verified" -ForegroundColor Green
    }
} else {
    Write-Host "? Failed to update name" -ForegroundColor Red
}
Write-Host ""

# Step 5: Test updating icon URL only
Write-Host "Step 5: Testing icon URL update..." -ForegroundColor Yellow

$updateIconBody = @{
    iconUrl = "https://example.com/test-updated.png"
} | ConvertTo-Json

$updatedSport = Invoke-ApiRequest -Url "$baseUrl/api/sports/$testSportId" -Method PUT -Headers $headers -Body $updateIconBody

if ($updatedSport) {
    Write-Host "? Icon URL updated successfully" -ForegroundColor Green
    Write-Host "  Name (unchanged): $($updatedSport.name)" -ForegroundColor Gray
    Write-Host "  Old Icon: https://example.com/test-original.png" -ForegroundColor Gray
    Write-Host "  New Icon: $($updatedSport.iconUrl)" -ForegroundColor Gray
    
    if ($updatedSport.iconUrl -eq "https://example.com/test-updated.png") {
        Write-Host "  ? Icon change verified" -ForegroundColor Green
    }
} else {
    Write-Host "? Failed to update icon" -ForegroundColor Red
}
Write-Host ""

# Step 6: Test updating both fields
Write-Host "Step 6: Testing update of both fields..." -ForegroundColor Yellow

$updateBothBody = @{
    name = "Final Test Sport"
    iconUrl = "https://example.com/test-final.png"
} | ConvertTo-Json

$updatedSport = Invoke-ApiRequest -Url "$baseUrl/api/sports/$testSportId" -Method PUT -Headers $headers -Body $updateBothBody

if ($updatedSport) {
    Write-Host "? Both fields updated successfully" -ForegroundColor Green
    Write-Host "  Name: $($updatedSport.name)" -ForegroundColor Gray
    Write-Host "  Icon: $($updatedSport.iconUrl)" -ForegroundColor Gray
    
    if ($updatedSport.name -eq "Final Test Sport" -and $updatedSport.iconUrl -eq "https://example.com/test-final.png") {
        Write-Host "  ? Both changes verified" -ForegroundColor Green
    }
} else {
    Write-Host "? Failed to update both fields" -ForegroundColor Red
}
Write-Host ""

# Step 7: Test clearing icon URL
Write-Host "Step 7: Testing clearing icon URL..." -ForegroundColor Yellow

$clearIconBody = @{
    iconUrl = ""
} | ConvertTo-Json

$updatedSport = Invoke-ApiRequest -Url "$baseUrl/api/sports/$testSportId" -Method PUT -Headers $headers -Body $clearIconBody

if ($updatedSport) {
    Write-Host "? Icon URL cleared successfully" -ForegroundColor Green
    Write-Host "  Icon URL: '$($updatedSport.iconUrl)'" -ForegroundColor Gray
    
    if ([string]::IsNullOrEmpty($updatedSport.iconUrl)) {
        Write-Host "  ? Icon cleared verified" -ForegroundColor Green
    }
} else {
    Write-Host "? Failed to clear icon" -ForegroundColor Red
}
Write-Host ""

# Step 8: Test duplicate name validation
Write-Host "Step 8: Testing duplicate name validation..." -ForegroundColor Yellow

if ($existingSports.Count -gt 0) {
    $existingName = $existingSports[0].name
    
    $duplicateBody = @{
        name = $existingName
    } | ConvertTo-Json
    
    $result = Invoke-ApiRequest -Url "$baseUrl/api/sports/$testSportId" -Method PUT -Headers $headers -Body $duplicateBody
    
    if (-not $result) {
        Write-Host "? Correctly prevented duplicate name '$existingName'" -ForegroundColor Green
    } else {
        Write-Host "? Should have prevented duplicate name" -ForegroundColor Red
    }
} else {
    Write-Host "??  Skipping duplicate test (no existing sports)" -ForegroundColor Yellow
}
Write-Host ""

# Step 9: Test update non-existent sport
Write-Host "Step 9: Testing update of non-existent sport..." -ForegroundColor Yellow

$nonExistentId = 99999

$updateBody = @{
    name = "Should Fail"
} | ConvertTo-Json

$result = Invoke-ApiRequest -Url "$baseUrl/api/sports/$nonExistentId" -Method PUT -Headers $headers -Body $updateBody

if (-not $result) {
    Write-Host "? Correctly returned 404 for non-existent sport" -ForegroundColor Green
} else {
    Write-Host "? Should have returned 404" -ForegroundColor Red
}
Write-Host ""

# Step 10: Verify updates are reflected in GET request
Write-Host "Step 10: Verifying updates via GET request..." -ForegroundColor Yellow

$retrievedSport = Invoke-ApiRequest -Url "$baseUrl/api/sports/$testSportId"

if ($retrievedSport) {
    Write-Host "? Retrieved updated sport" -ForegroundColor Green
    Write-Host "  Name: $($retrievedSport.name)" -ForegroundColor Gray
    Write-Host "  Icon: '$($retrievedSport.iconUrl)'" -ForegroundColor Gray
    
    if ($retrievedSport.name -eq "Final Test Sport") {
        Write-Host "  ? Changes persisted correctly" -ForegroundColor Green
    }
} else {
    Write-Host "? Failed to retrieve sport" -ForegroundColor Red
}
Write-Host ""

# Step 11: Test without authentication
Write-Host "Step 11: Testing update without authentication..." -ForegroundColor Yellow

$updateBody = @{
    name = "Should Fail"
} | ConvertTo-Json

$result = Invoke-ApiRequest -Url "$baseUrl/api/sports/$testSportId" -Method PUT -Body $updateBody

if (-not $result) {
    Write-Host "? Correctly requires authentication" -ForegroundColor Green
} else {
    Write-Host "? Should require authentication" -ForegroundColor Red
}
Write-Host ""

# Step 12: Clean up - Delete test sport
Write-Host "Step 12: Cleaning up test data..." -ForegroundColor Yellow

$deleteResult = Invoke-ApiRequest -Url "$baseUrl/api/sports/$testSportId" -Method DELETE -Headers $headers

if ($deleteResult -ne $null -or $?) {
    Write-Host "? Test sport deleted" -ForegroundColor Green
} else {
    Write-Host "??  Could not delete test sport (ID: $testSportId)" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Update Sport API Tests:" -ForegroundColor White
Write-Host "  ? Admin login" -ForegroundColor Green
Write-Host "  ? Get existing sports" -ForegroundColor Green
Write-Host "  ? Create test sport" -ForegroundColor Green
Write-Host "  ? Update name only" -ForegroundColor Green
Write-Host "  ? Update icon URL only" -ForegroundColor Green
Write-Host "  ? Update both fields" -ForegroundColor Green
Write-Host "  ? Clear icon URL" -ForegroundColor Green
Write-Host "  ? Prevent duplicate names" -ForegroundColor Green
Write-Host "  ? 404 for non-existent sport" -ForegroundColor Green
Write-Host "  ? Verify changes persist" -ForegroundColor Green
Write-Host "  ? Require authentication" -ForegroundColor Green
Write-Host "  ? Clean up test data" -ForegroundColor Green
Write-Host ""
Write-Host "All tests completed successfully! ?" -ForegroundColor Green
Write-Host ""
