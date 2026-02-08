# Remove Nixpacks Deprecation Script
# This script commits the removal of deprecated nixpacks configuration

Write-Host "???  Nixpacks Deprecation Cleanup" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

Write-Host "?? Summary of Changes:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Files Removed:" -ForegroundColor Red
Write-Host "  ? nixpacks.toml (deprecated)" -ForegroundColor White
Write-Host ""

Write-Host "Files Updated:" -ForegroundColor Green
Write-Host "  ? railway.json (changed to DOCKERFILE builder)" -ForegroundColor White
Write-Host "  ? RAILWAY_BUILD_FIX.md (removed nixpacks references)" -ForegroundColor White
Write-Host "  ? RAILWAY_FIX_SUMMARY.md (removed nixpacks references)" -ForegroundColor White
Write-Host "  ? RAILWAY_QUICKSTART.md (removed nixpacks references)" -ForegroundColor White
Write-Host "  ? railway-fix-deploy.ps1 (removed nixpacks checks)" -ForegroundColor White
Write-Host "  ? verify-railway-config.ps1 (removed nixpacks checks)" -ForegroundColor White
Write-Host ""

Write-Host "Files Created:" -ForegroundColor Cyan
Write-Host "  ?? NIXPACKS_DEPRECATION_SUMMARY.md (documentation)" -ForegroundColor White
Write-Host ""

# Verify nixpacks.toml is removed
if (Test-Path "nixpacks.toml") {
    Write-Host "??  Warning: nixpacks.toml still exists!" -ForegroundColor Yellow
    Write-Host "   This file should have been removed." -ForegroundColor Gray
    Write-Host ""
    $removeConfirm = Read-Host "Do you want to remove it now? (y/n)"
    if ($removeConfirm -eq 'y' -or $removeConfirm -eq 'Y') {
        Remove-Item "nixpacks.toml" -Force
        Write-Host "? nixpacks.toml removed" -ForegroundColor Green
    }
} else {
    Write-Host "? nixpacks.toml already removed" -ForegroundColor Green
}

Write-Host ""

# Check Git status
Write-Host "?? Git Status:" -ForegroundColor Yellow
git status --short

Write-Host ""

# Confirm with user
$confirm = Read-Host "Do you want to commit these changes? (y/n)"

if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "? Commit cancelled." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "?? Staging changes..." -ForegroundColor Yellow

# Stage all modified files
git add railway.json
git add RAILWAY_BUILD_FIX.md
git add RAILWAY_FIX_SUMMARY.md
git add RAILWAY_QUICKSTART.md
git add railway-fix-deploy.ps1
git add verify-railway-config.ps1
git add NIXPACKS_DEPRECATION_SUMMARY.md
git add remove-nixpacks.ps1

# Stage deletion of nixpacks.toml if it was just removed
git add nixpacks.toml 2>$null

Write-Host "? Changes staged" -ForegroundColor Green
Write-Host ""

# Commit
Write-Host "?? Committing changes..." -ForegroundColor Yellow

$commitMessage = @"
Remove deprecated nixpacks configuration

Changes:
- Delete nixpacks.toml (deprecated build method)
- Update railway.json to use DOCKERFILE builder explicitly
- Update all Railway documentation to remove nixpacks references
- Simplify deployment to Docker-only workflow
- Update deployment scripts (railway-fix-deploy.ps1, verify-railway-config.ps1)
- Add NIXPACKS_DEPRECATION_SUMMARY.md documentation

Reason: 
- Docker is the industry standard for containerized deployments
- Railway prioritizes Dockerfile over nixpacks
- Simplifies configuration and maintenance
- .NET 10 fully supported by official Microsoft Docker images

Impact:
- No functional changes to deployment
- Cleaner configuration (3 files instead of 4)
- Simplified documentation
- Better maintainability

Build Method: Docker (industry standard)
Configuration: Dockerfile + railway.json + .dockerignore

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
Write-Host "?? Nixpacks Deprecation Cleanup Complete!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

Write-Host "? Summary:" -ForegroundColor Cyan
Write-Host "  • nixpacks.toml removed" -ForegroundColor White
Write-Host "  • Railway configuration updated to Docker-only" -ForegroundColor White
Write-Host "  • All documentation updated" -ForegroundColor White
Write-Host "  • Deployment scripts updated" -ForegroundColor White
Write-Host ""

Write-Host "?? Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Railway will use Docker for all builds" -ForegroundColor White
Write-Host "  2. No action needed - automatic rebuild on next push" -ForegroundColor White
Write-Host "  3. Review NIXPACKS_DEPRECATION_SUMMARY.md for details" -ForegroundColor White
Write-Host ""

Write-Host "?? Build Method: Docker (industry standard)" -ForegroundColor Green
Write-Host "?? Documentation: All references to nixpacks removed" -ForegroundColor Green
Write-Host ""
