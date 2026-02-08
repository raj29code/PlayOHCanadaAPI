# Diagnose Railway Deployment Path Issues
# This script verifies the correct project structure for Railway deployment

Write-Host "?? Railway Deployment Path Diagnosis" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

# Check current directory
$currentDir = Get-Location
Write-Host "?? Current Directory: $currentDir" -ForegroundColor Yellow
Write-Host ""

# Check for project file
Write-Host "?? Looking for PlayOhCanadaAPI.csproj..." -ForegroundColor Yellow
$projectFiles = Get-ChildItem -Recurse -Filter "PlayOhCanadaAPI.csproj" -ErrorAction SilentlyContinue

if ($projectFiles) {
    Write-Host "? Found project file(s):" -ForegroundColor Green
    foreach ($file in $projectFiles) {
        $relativePath = Resolve-Path -Relative $file.FullName
        Write-Host "   $relativePath" -ForegroundColor Cyan
    }
} else {
    Write-Host "? No project file found!" -ForegroundColor Red
}

Write-Host ""

# Check expected path from repository root
Write-Host "?? Checking expected path structure..." -ForegroundColor Yellow

$expectedPath = "PlayOhCanadaAPI/PlayOhCanadaAPI.csproj"
if (Test-Path $expectedPath) {
    Write-Host "? Expected path exists: $expectedPath" -ForegroundColor Green
} else {
    Write-Host "? Expected path NOT found: $expectedPath" -ForegroundColor Red
    Write-Host "   This is what Railway will look for!" -ForegroundColor Yellow
}

Write-Host ""

# Check for nested structure (common mistake)
$nestedPath = "PlayOhCanadaAPI/PlayOhCanadaAPI/PlayOhCanadaAPI.csproj"
if (Test-Path $nestedPath) {
    Write-Host "??  Nested structure detected: $nestedPath" -ForegroundColor Yellow
    Write-Host "   Dockerfile needs to be updated!" -ForegroundColor Yellow
} else {
    Write-Host "??  No nested structure (this is good)" -ForegroundColor Cyan
}

Write-Host ""

# List top-level structure
Write-Host "?? Repository Structure:" -ForegroundColor Yellow
Write-Host ""
Get-ChildItem -Directory | ForEach-Object {
    Write-Host "?? $($_.Name)/" -ForegroundColor Cyan
    if ($_.Name -eq "PlayOhCanadaAPI") {
        Get-ChildItem $_.FullName -File -Filter "*.csproj" | ForEach-Object {
            Write-Host "   ?? $($_.Name)" -ForegroundColor Green
        }
    }
}

Write-Host ""

# Check Dockerfile
Write-Host "?? Checking Dockerfile..." -ForegroundColor Yellow
if (Test-Path "Dockerfile") {
    $dockerfileContent = Get-Content "Dockerfile" -Raw
    
    Write-Host "? Dockerfile exists" -ForegroundColor Green
    Write-Host ""
    Write-Host "COPY commands in Dockerfile:" -ForegroundColor Cyan
    
    $copyCommands = $dockerfileContent -split "`n" | Where-Object { $_ -match "^COPY" }
    foreach ($cmd in $copyCommands) {
        Write-Host "   $cmd" -ForegroundColor White
    }
    
    Write-Host ""
    
    # Check if paths match
    if ($dockerfileContent -match "COPY PlayOhCanadaAPI/\*\.csproj" -or 
        $dockerfileContent -match "COPY PlayOhCanadaAPI/PlayOhCanadaAPI\.csproj") {
        Write-Host "? Dockerfile paths look correct" -ForegroundColor Green
    } else {
        Write-Host "??  Dockerfile paths may need adjustment" -ForegroundColor Yellow
    }
} else {
    Write-Host "? Dockerfile not found!" -ForegroundColor Red
}

Write-Host ""

# Railway Build Context
Write-Host "?? Railway Build Context:" -ForegroundColor Yellow
Write-Host "   When Railway builds, it uses the repository root as context" -ForegroundColor White
Write-Host "   All COPY commands in Dockerfile are relative to repo root" -ForegroundColor White
Write-Host ""

# Expected structure for Railway
Write-Host "? Expected Structure for Railway:" -ForegroundColor Green
Write-Host ""
Write-Host "Repository Root/" -ForegroundColor Cyan
Write-Host "??? Dockerfile                           ? Must be here" -ForegroundColor White
Write-Host "??? nixpacks.toml                        ? Must be here" -ForegroundColor White
Write-Host "??? railway.json                         ? Must be here" -ForegroundColor White
Write-Host "??? PlayOhCanadaAPI/                     ? Project folder" -ForegroundColor White
Write-Host "    ??? PlayOhCanadaAPI.csproj           ? Project file" -ForegroundColor White
Write-Host "    ??? Program.cs" -ForegroundColor White
Write-Host "    ??? Controllers/" -ForegroundColor White
Write-Host "    ??? Models/" -ForegroundColor White
Write-Host ""

# Recommendation
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

$hasCorrectStructure = Test-Path "PlayOhCanadaAPI/PlayOhCanadaAPI.csproj"
$hasDockerfile = Test-Path "Dockerfile"

if ($hasCorrectStructure -and $hasDockerfile) {
    Write-Host "?? Structure looks good!" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Commit the fixed Dockerfile:" -ForegroundColor White
    Write-Host "   git add Dockerfile" -ForegroundColor Gray
    Write-Host "   git commit -m 'Fix Dockerfile paths for Railway deployment'" -ForegroundColor Gray
    Write-Host "   git push origin feature/sports-api" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Railway will automatically rebuild" -ForegroundColor White
    Write-Host "3. Monitor build logs in Railway dashboard" -ForegroundColor White
} else {
    Write-Host "??  Issues detected!" -ForegroundColor Yellow
    Write-Host ""
    if (-not $hasCorrectStructure) {
        Write-Host "? Project structure doesn't match expected layout" -ForegroundColor Red
        Write-Host "   Expected: PlayOhCanadaAPI/PlayOhCanadaAPI.csproj" -ForegroundColor Gray
    }
    if (-not $hasDockerfile) {
        Write-Host "? Dockerfile not found in repository root" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Please fix these issues before deploying to Railway" -ForegroundColor Yellow
}

Write-Host ""
