# Add migration for RevokedToken table
Write-Host "Creating migration for RevokedToken..." -ForegroundColor Cyan

# Navigate to project directory
Set-Location -Path "PlayOhCanadaAPI"

# Create migration
dotnet ef migrations add AddRevokedTokenTable

# Apply migration
Write-Host "`nApplying migration to database..." -ForegroundColor Cyan
dotnet ef database update

Write-Host "`nMigration completed successfully!" -ForegroundColor Green
Write-Host "The RevokedToken table has been added to the database." -ForegroundColor Green

# Navigate back
Set-Location -Path ".."
