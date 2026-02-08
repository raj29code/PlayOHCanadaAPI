# Quick Fix for Railway Deployment Error
# This script commits the corrected Dockerfile and pushes to trigger rebuild

Write-Host "?? Railway Deployment - Quick Fix" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

Write-Host "?? Issue:" -ForegroundColor Yellow
Write-Host "   Railway build failed with 'project file not found' error" -ForegroundColor White
Write-Host ""

Write-Host "? Solution:" -ForegroundColor Green
Write-Host "   Updated Dockerfile to use correct path: PlayOhCanadaAPI/*.csproj" -ForegroundColor White
Write-Host ""

# Verify structure first
Write-Host "?? Verifying project structure..." -ForegroundColor Yellow
if (Test-Path "PlayOhCanadaAPI/PlayOhCanadaAPI.csproj") {
    Write-Host "? Project file found at correct location" -ForegroundColor Green
} else {
    Write-Host "? Project file not found! Cannot proceed." -ForegroundColor Red
    Write-Host "   Expected: PlayOhCanadaAPI/PlayOhCanadaAPI.csproj" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Check Dockerfile
if (-not (Test-Path "Dockerfile")) {
    Write-Host "? Dockerfile not found!" -ForegroundColor Red
    exit 1
}

Write-Host "? Dockerfile found" -ForegroundColor Green
Write-Host ""

# Show git status
Write-Host "?? Current Git status:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Confirm with user
$confirm = Read-Host "Do you want to commit and push the fixed Dockerfile? (y/n)"

if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "? Deployment fix cancelled." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "?? Committing changes..." -ForegroundColor Yellow

# Stage Dockerfile
git add Dockerfile

# Also add diagnostic script
git add diagnose-railway-paths.ps1 -ErrorAction SilentlyContinue

# Commit
$commitMessage = @"
Fix Dockerfile paths for Railway deployment

Issue: Build failed with 'PlayOhCanadaAPI/PlayOhCanadaAPI.csproj not found'
Root Cause: Dockerfile was looking for nested path that doesn't exist
Fix: Updated COPY command to use PlayOhCanadaAPI/*.csproj

Changes:
- Fixed COPY path in Dockerfile
- Project structure: PlayOhCanadaAPI/PlayOhCanadaAPI.csproj ?
- Added diagnostic script for path verification

This should resolve the Railway build error.
Related: Phase 2 - Railway Deployment (PROGRESS.md)
"@

git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "? Commit successful" -ForegroundColor Green
} else {
    Write-Host "? Commit failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Get current branch
$currentBranch = git branch --show-current
Write-Host "?? Current branch: $currentBranch" -ForegroundColor Cyan
Write-Host ""

# Push
Write-Host "?? Pushing to remote..." -ForegroundColor Yellow
git push origin $currentBranch

if ($LASTEXITCODE -eq 0) {
    Write-Host "? Push successful!" -ForegroundColor Green
} else {
    Write-Host "? Push failed" -ForegroundColor Red
    Write-Host "   Try: git push origin $currentBranch --force" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "?? Railway Deployment Fix Pushed!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

Write-Host "?? Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. ??  Railway will automatically detect the push" -ForegroundColor White
Write-Host "2. ?? New build will start in ~30 seconds" -ForegroundColor White
Write-Host "3. ?? Monitor build progress:" -ForegroundColor White
Write-Host "   ? https://railway.app/dashboard" -ForegroundColor Gray
Write-Host "   ? Your Project ? Deployments" -ForegroundColor Gray
Write-Host ""
Write-Host "4. ? Expected build output:" -ForegroundColor White
Write-Host "   ? Building with Dockerfile" -ForegroundColor Gray
Write-Host "   ? COPY PlayOhCanadaAPI/*.csproj ?" -ForegroundColor Gray
Write-Host "   ? RUN dotnet restore ?" -ForegroundColor Gray
Write-Host "   ? RUN dotnet publish ?" -ForegroundColor Gray
Write-Host "   ? Deployment successful ?" -ForegroundColor Gray
Write-Host ""

Write-Host "??  Expected build time: 5-10 minutes" -ForegroundColor Yellow
Write-Host ""

Write-Host "?? If build still fails:" -ForegroundColor Cyan
Write-Host "   1. Check Railway build logs for specific error" -ForegroundColor White
Write-Host "   2. Run: .\diagnose-railway-paths.ps1" -ForegroundColor White
Write-Host "   3. Verify paths in Railway dashboard" -ForegroundColor White
Write-Host ""

Write-Host "?? Documentation:" -ForegroundColor Cyan
Write-Host "   • RAILWAY_BUILD_FIX.md - Detailed troubleshooting" -ForegroundColor White
Write-Host "   • RAILWAY_DEPLOYMENT_CHECKLIST.md - Complete checklist" -ForegroundColor White
Write-Host ""
