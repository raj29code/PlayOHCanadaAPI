# Play Oh Canada API - Database Setup Script

Write-Host "Play Oh Canada API - Database Setup" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Check if PostgreSQL is running
Write-Host "Checking PostgreSQL installation..." -ForegroundColor Yellow
$pgVersion = & pg_config --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "? PostgreSQL found: $pgVersion" -ForegroundColor Green
} else {
    Write-Host "? PostgreSQL not found. Please install PostgreSQL first." -ForegroundColor Red
    Write-Host "  Download from: https://www.postgresql.org/download/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Check if dotnet-ef is installed
Write-Host "Checking EF Core tools..." -ForegroundColor Yellow
$efVersion = & dotnet ef --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "? dotnet-ef found: $efVersion" -ForegroundColor Green
} else {
    Write-Host "Installing dotnet-ef tools..." -ForegroundColor Yellow
    dotnet tool install --global dotnet-ef
}

Write-Host ""

# Apply migrations
Write-Host "Applying database migrations..." -ForegroundColor Yellow
$project = "PlayOhCanadaAPI/PlayOhCanadaAPI.csproj"

try {
    dotnet ef database update --project $project
    Write-Host "? Database migrations applied successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Default admin account created:" -ForegroundColor Cyan
    Write-Host "  Email: admin@playohcanada.com" -ForegroundColor White
    Write-Host "  Password: Admin@123" -ForegroundColor White
} catch {
    Write-Host "? Failed to apply migrations. Please check your connection string in appsettings.Development.json" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Setup complete! You can now run the application:" -ForegroundColor Green
Write-Host "  dotnet run --project PlayOhCanadaAPI" -ForegroundColor Yellow
Write-Host ""
Write-Host "Then open: https://localhost:7063/scalar/v1" -ForegroundColor Cyan
