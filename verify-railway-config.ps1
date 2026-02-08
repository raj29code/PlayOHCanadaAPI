# Verify Railway Docker Configuration
# This script checks if all Railway Docker deployment files are correctly configured

Write-Host "?? Railway Docker Configuration Verification" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

$allChecksPass = $true

# Check 1: Dockerfile exists and is valid
Write-Host "?? Checking Dockerfile..." -ForegroundColor Yellow
if (Test-Path "Dockerfile") {
    $dockerfileContent = Get-Content "Dockerfile" -Raw
    
    # Check for .NET 10
    if ($dockerfileContent -match "dotnet/sdk:10.0" -and $dockerfileContent -match "dotnet/aspnet:10.0") {
        Write-Host "  ? Dockerfile exists with .NET 10 configuration" -ForegroundColor Green
    } else {
        Write-Host "  ??  Dockerfile exists but may not have .NET 10 configured" -ForegroundColor Yellow
        $allChecksPass = $false
    }
    
    # Check for correct project path
    if ($dockerfileContent -match "PlayOhCanadaAPI/\*\.csproj" -or $dockerfileContent -match "PlayOhCanadaAPI/PlayOhCanadaAPI\.csproj") {
        Write-Host "  ? Correct project path found" -ForegroundColor Green
    } else {
        Write-Host "  ? Project path may be incorrect" -ForegroundColor Red
        $allChecksPass = $false
    }
    
    # Check for port configuration
    if ($dockerfileContent -match "ASPNETCORE_URLS") {
        Write-Host "  ? Port configuration present" -ForegroundColor Green
    } else {
        Write-Host "  ??  Port configuration missing" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ? Dockerfile not found" -ForegroundColor Red
    $allChecksPass = $false
}

Write-Host ""

# Check 2: railway.json
Write-Host "?? Checking railway.json..." -ForegroundColor Yellow
if (Test-Path "railway.json") {
    $railwayContent = Get-Content "railway.json" -Raw
    if ($railwayContent -match "DOCKERFILE") {
        Write-Host "  ? railway.json exists with Docker builder configured" -ForegroundColor Green
    } else {
        Write-Host "  ??  railway.json exists but builder may not be set to DOCKERFILE" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ??  railway.json not found (Railway will auto-detect Dockerfile)" -ForegroundColor Cyan
}

Write-Host ""

# Check 3: .dockerignore
Write-Host "?? Checking .dockerignore..." -ForegroundColor Yellow
if (Test-Path ".dockerignore") {
    Write-Host "  ? .dockerignore exists (optimizes build)" -ForegroundColor Green
} else {
    Write-Host "  ??  .dockerignore not found (builds will be slower)" -ForegroundColor Yellow
}

Write-Host ""

# Check 4: Project structure
Write-Host "?? Checking project structure..." -ForegroundColor Yellow
if (Test-Path "PlayOhCanadaAPI/PlayOhCanadaAPI.csproj") {
    Write-Host "  ? PlayOhCanadaAPI.csproj found at correct location" -ForegroundColor Green
} else {
    Write-Host "  ? PlayOhCanadaAPI.csproj not found at expected location" -ForegroundColor Red
    Write-Host "     Expected: PlayOhCanadaAPI/PlayOhCanadaAPI.csproj" -ForegroundColor Gray
    $allChecksPass = $false
}

Write-Host ""

# Check 5: Git status
Write-Host "?? Checking Git status..." -ForegroundColor Yellow
$gitStatus = git status --short 2>$null

if ($LASTEXITCODE -eq 0) {
    if ($gitStatus) {
        $filesChanged = ($gitStatus | Measure-Object).Count
        Write-Host "  ??  $filesChanged uncommitted file(s)" -ForegroundColor Cyan
        
        # Check if Railway files are staged
        $railwayFiles = @("Dockerfile", "railway.json")
        $stagedFiles = git diff --cached --name-only
        
        $needsStaging = $false
        foreach ($file in $railwayFiles) {
            if ((Test-Path $file) -and ($gitStatus -match $file) -and ($stagedFiles -notmatch $file)) {
                $needsStaging = $true
            }
        }
        
        if ($needsStaging) {
            Write-Host "  ??  Railway config files need to be staged" -ForegroundColor Yellow
            Write-Host "     Run: .\railway-fix-deploy.ps1" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ? No uncommitted changes" -ForegroundColor Green
    }
} else {
    Write-Host "  ??  Not a Git repository" -ForegroundColor Yellow
}

Write-Host ""

# Check 6: .NET SDK version
Write-Host "?? Checking .NET SDK..." -ForegroundColor Yellow
$dotnetVersion = dotnet --version 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ? .NET SDK installed: $dotnetVersion" -ForegroundColor Green
    
    if ($dotnetVersion -match "^10\.") {
        Write-Host "  ? .NET 10 SDK detected" -ForegroundColor Green
    } elseif ($dotnetVersion -match "^8\.") {
        Write-Host "  ??  .NET 8 SDK detected (Dockerfile uses .NET 10 images)" -ForegroundColor Cyan
    } else {
        Write-Host "  ??  Unexpected .NET version (Dockerfile uses .NET 10)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ??  .NET SDK not found (not required for Railway deploy)" -ForegroundColor Yellow
}

Write-Host ""

# Check 7: Railway CLI (optional)
Write-Host "?? Checking Railway CLI..." -ForegroundColor Yellow
$railwayCli = Get-Command railway -ErrorAction SilentlyContinue

if ($railwayCli) {
    Write-Host "  ? Railway CLI installed" -ForegroundColor Green
} else {
    Write-Host "  ??  Railway CLI not installed (optional, but recommended)" -ForegroundColor Cyan
    Write-Host "     Install: npm i -g @railway/cli" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Gray

# Final summary
Write-Host ""
if ($allChecksPass) {
    Write-Host "?? All critical checks passed!" -ForegroundColor Green
    Write-Host "? Your project is ready for Railway Docker deployment" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: .\railway-fix-deploy.ps1" -ForegroundColor White
    Write-Host "  2. Monitor build in Railway Dashboard" -ForegroundColor White
    Write-Host "  3. Continue with Phase 2 Step 5 (Database Migration)" -ForegroundColor White
} else {
    Write-Host "??  Some checks failed" -ForegroundColor Yellow
    Write-Host "Please review the errors above before deploying" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "?? Common fixes:" -ForegroundColor Cyan
    Write-Host "  • Ensure you're in the repository root directory" -ForegroundColor White
    Write-Host "  • Verify project structure matches expected layout" -ForegroundColor White
    Write-Host "  • Check RAILWAY_BUILD_FIX.md for detailed troubleshooting" -ForegroundColor White
}

Write-Host ""
Write-Host "?? Documentation:" -ForegroundColor Cyan
Write-Host "  • RAILWAY_QUICKSTART.md - Quick deployment guide" -ForegroundColor White
Write-Host "  • RAILWAY_BUILD_FIX.md - Detailed troubleshooting" -ForegroundColor White
Write-Host "  • PROGRESS.md - Full Phase 2 steps" -ForegroundColor White
Write-Host ""
Write-Host "?? Build Method: Docker (industry standard)" -ForegroundColor Cyan
Write-Host ""
