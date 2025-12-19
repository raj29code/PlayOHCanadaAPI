# Setup Checklist

## ? Prerequisites
- [ ] .NET 10 SDK installed
- [ ] PostgreSQL 14+ installed and running
- [ ] Visual Studio 2022 or VS Code installed
- [ ] Git installed (optional)

## ? Installation Steps

### 1. Database Setup
- [ ] PostgreSQL service is running
- [ ] Created database or ready to let app create it
- [ ] Updated connection string in `appsettings.Development.json`
  ```json
  "DefaultConnection": "Host=localhost;Port=5432;Database=PlayOhCanadaDb_Dev;Username=postgres;Password=YOUR_PASSWORD"
  ```

### 2. Application Configuration
- [ ] Reviewed JWT settings in `appsettings.Development.json`
- [ ] (Production) Generated secure JWT secret key (32+ characters)
- [ ] (Production) Updated `appsettings.json` with production settings

### 3. Database Migration
- [ ] Installed EF Core tools: `dotnet tool install --global dotnet-ef`
- [ ] Ran migrations using either:
  - [ ] PowerShell script: `.\setup-database.ps1`
  - [ ] Or manually: `dotnet ef database update --project PlayOhCanadaAPI`
- [ ] Verified database created successfully

### 4. Build and Run
- [ ] Restored packages: `dotnet restore`
- [ ] Built solution: `dotnet build`
- [ ] All tests pass: `dotnet test` (if tests exist)
- [ ] Run application: `dotnet run --project PlayOhCanadaAPI`
- [ ] Application starts without errors

### 5. Testing
- [ ] Opened Scalar UI: `https://localhost:7063/scalar/v1`
- [ ] Tested registration endpoint (`POST /api/auth/register`)
- [ ] Tested login endpoint (`POST /api/auth/login`)
- [ ] Got JWT token from login response
- [ ] Clicked "Authorize" and added token
- [ ] Tested protected endpoint (`GET /api/auth/me`)
- [ ] Tested public endpoint (`GET /api/weatherforecast/public`)

### 6. Quick Test (Optional)
- [ ] Ran test script: `.\test-api.ps1`
- [ ] All tests passed successfully

## ? Verification

### API Endpoints Working
- [ ] `POST /api/auth/register` - Register new user
- [ ] `POST /api/auth/login` - Login returns JWT token
- [ ] `GET /api/auth/me` - Returns user profile (with token)
- [ ] `GET /api/weatherforecast` - Protected endpoint (requires token)
- [ ] `GET /api/weatherforecast/public` - Public endpoint (no token)

### Default Admin Login
- [ ] Can login with:
  - Email: `admin@playohcanada.com`
  - Password: `Admin@123`
- [ ] Receives admin role token
- [ ] Token works on protected endpoints

### Database Verification
- [ ] Database `PlayOhCanadaDb_Dev` exists
- [ ] Table `Users` exists
- [ ] Admin user exists in database
- [ ] Can register new users
- [ ] Users appear in database

## ? Security Checks

- [ ] JWT secret key is at least 32 characters
- [ ] (Production) JWT secret NOT in source control
- [ ] (Production) Using User Secrets or Azure Key Vault
- [ ] Passwords are hashed (not plain text in database)
- [ ] HTTPS is enforced
- [ ] Input validation working on all endpoints
- [ ] Authorization working (401 without token)

## ? Documentation

- [ ] Read `README.md` - Complete setup guide
- [ ] Read `README_AUTH.md` - Authentication details
- [ ] Read `IMPLEMENTATION_SUMMARY.md` - What was built
- [ ] Understand Phase 2 roadmap (SSO, Phone auth)

## ?? Ready for Development

Once all items are checked:
- ? Authentication system is fully functional
- ? Database is set up and working
- ? API endpoints are tested and working
- ? JWT authentication is configured
- ? Ready to build additional features

## ?? Next Steps

### Immediate (Optional)
- [ ] Customize User model for your needs
- [ ] Add more protected endpoints
- [ ] Implement role-based authorization on endpoints
- [ ] Add custom validation rules
- [ ] Set up CI/CD pipeline

### Phase 2 Planning
- [ ] Choose SSO providers (Google, Microsoft, Apple)
- [ ] Select SMS provider (Twilio, AWS SNS)
- [ ] Plan email verification flow
- [ ] Design password reset flow
- [ ] Consider refresh token strategy

## ?? Troubleshooting

If something doesn't work:

1. **Database Connection Issues**
   - [ ] PostgreSQL service running?
   - [ ] Connection string correct?
   - [ ] Firewall blocking port 5432?
   - [ ] Database created?

2. **Migration Issues**
   - [ ] EF Core tools installed globally?
   - [ ] Run: `dotnet ef --version`
   - [ ] Try: `dotnet ef database drop` then `dotnet ef database update`

3. **JWT Issues**
   - [ ] Secret key at least 32 characters?
   - [ ] Token format: `Bearer YOUR_TOKEN`?
   - [ ] Token not expired?

4. **Build Issues**
   - [ ] Clean: `dotnet clean`
   - [ ] Restore: `dotnet restore`
   - [ ] Build: `dotnet build`

5. **Runtime Issues**
   - [ ] Check logs in console
   - [ ] Check `appsettings.Development.json` exists
   - [ ] Port 7063 not already in use?

## ?? Support

- Documentation: See README.md files
- Issues: Check IMPLEMENTATION_SUMMARY.md
- Logs: Enable detailed logging in appsettings
- Database: Use `psql` or pgAdmin to inspect

---

**Current Status**: [ ] Setup Complete  [ ] Testing Complete  [ ] Ready for Development

**Date Completed**: __________________

**Notes**:
_________________________________
_________________________________
_________________________________
