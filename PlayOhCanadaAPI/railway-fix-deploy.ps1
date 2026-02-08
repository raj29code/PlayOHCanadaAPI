# Railway Deployment - Quick Fix Script
# This script commits and pushes Railway configuration files

Write-Host "?? Railway Deployment Configuration Setup" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

# Check if files exist
$requiredFiles = @(
    "nixpacks.toml",
    "railway.json",
    "Dockerfile"
)

Write-Host "?? Checking required files..." -ForegroundColor Yellow
$allFilesExist = $true

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ? $file exists" -ForegroundColor Green
    } else {
        Write-Host "  ? $file missing" -ForegroundColor Red
        $allFilesExist = $false
    }
}

Write-Host ""

if (-not $allFilesExist) {
    Write-Host "? Some required files are missing!" -ForegroundColor Red
    Write-Host "   Please run the file creation commands first." -ForegroundColor Yellow
    exit 1
}

# Check Git status
Write-Host "?? Checking Git status..." -ForegroundColor Yellow
git status --short

Write-Host ""
Write-Host "?? Files to be committed:" -ForegroundColor Cyan
Write-Host "  • nixpacks.toml       - Nixpacks build configuration" -ForegroundColor White
Write-Host "  • railway.json        - Railway project configuration" -ForegroundColor White
Write-Host "  • Dockerfile          - Docker build instructions" -ForegroundColor White
Write-Host "  • .dockerignore       - Docker build optimization" -ForegroundColor White
Write-Host "  • RAILWAY_BUILD_FIX.md - Documentation" -ForegroundColor White
Write-Host ""

# Confirm with user
$confirm = Read-Host "Do you want to commit and push these files? (y/n)"

if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "? Deployment setup cancelled." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "?? Staging files..." -ForegroundColor Yellow

# Add files to Git
git add nixpacks.toml
git add railway.json
git add Dockerfile
git add RAILWAY_BUILD_FIX.md

# Try to add .dockerignore (may already exist)
git add .dockerignore 2>$null

Write-Host "? Files staged" -ForegroundColor Green
Write-Host ""

# Commit
Write-Host "?? Committing changes..." -ForegroundColor Yellow
$commitMessage = "Add Railway deployment configuration for .NET 10

- Add nixpacks.toml for Nixpacks build configuration
- Add railway.json for Railway project settings
- Add Dockerfile for reliable .NET 10 deployment
- Add .dockerignore for optimized Docker builds
- Add RAILWAY_BUILD_FIX.md documentation

Fixes: 'Railpack could not determine how to build the app' error
Related: Phase 2 - Railway Deployment (PROGRESS.md)
"

git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "? Commit successful" -ForegroundColor Green
} else {
    Write-Host "? Commit failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check current branch
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
Write-Host "?? Railway Deployment Configuration Complete!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

Write-Host "?? Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Go to Railway Dashboard: https://railway.app/dashboard" -ForegroundColor White
Write-Host "2. Your project should now rebuild automatically" -ForegroundColor White
Write-Host "3. Monitor the build logs for success" -ForegroundColor White
Write-Host "4. If needed, force rebuild:" -ForegroundColor White
Write-Host "   ? Deployments tab ? Click 'Redeploy'" -ForegroundColor Gray
Write-Host ""
Write-Host "5. After successful build:" -ForegroundColor White
Write-Host "   ? Continue with Step 5 (Database Migration)" -ForegroundColor Gray
Write-Host "   ? See PROGRESS.md Phase 2 for details" -ForegroundColor Gray
Write-Host ""

Write-Host "?? Documentation:" -ForegroundColor Cyan
Write-Host "  • RAILWAY_BUILD_FIX.md - Detailed fix documentation" -ForegroundColor White
Write-Host "  • PROGRESS.md - Phase 2 deployment steps" -ForegroundColor White
Write-Host ""

Write-Host "??  Expected build time: 5-10 minutes (first build)" -ForegroundColor Yellow
Write-Host ""
