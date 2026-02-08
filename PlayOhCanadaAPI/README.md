# Play Oh Canada API - Complete Setup Guide

## ?? Quick Links

- **?? [Development Progress](PROGRESS.md)** - Complete project status and timeline
- **?? Quick Start** - See below
- **?? Documentation Index** - See bottom of this file

## ?? Quick Start

### Prerequisites
- .NET 10 SDK
- PostgreSQL 14+ 
- Visual Studio 2022 or VS Code
- Postman or similar API testing tool (optional - we have Scalar UI built-in)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/raj29code/PlayOHCanadaAPI
   cd PlayOHCanadaAPI
   ```

2. **Install PostgreSQL**
   - Download from: https://www.postgresql.org/download/
   - Install with default settings
   - Remember your postgres user password

3. **Update Database Connection**
   
   Edit `PlayOhCanadaAPI/appsettings.Development.json`:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Host=localhost;Port=5432;Database=PlayOhCanadaDb_Dev;Username=postgres;Password=YOUR_PASSWORD"
     }
   }
   ```

4. **Setup Database**
   
   Run the PowerShell script:
   ```powershell
   .\setup-database.ps1
   ```
   
   Or manually:
   ```bash
   dotnet restore
   dotnet ef database update --project PlayOhCanadaAPI
   ```

5. **Run the Application**
   ```bash
   dotnet run --project PlayOhCanadaAPI
   ```

6. **Open API Documentation**
   
   Navigate to: `https://localhost:7063/scalar/v1`

## ?? Features

### ? Implemented (Phase 1)

**Authentication & Authorization:**
- **User Registration** with email and password
- **User Login** with JWT token generation
- **User Logout** with token revocation (blacklist)
- **User Profile** retrieval with `isAdmin` flag
- **Role-Based Authorization** (Admin/User)
- **Secure Password Hashing** using BCrypt
- **JWT Authentication** with configurable expiry and validation

**Sports & Scheduling:**
- **Sports Management** - CRUD operations for sports
- **Schedule Creation** - Single and recurring schedules with date/time separation
- **Recurring Schedules** - Daily, Weekly, BiWeekly, Monthly patterns
- **Flexible Recurrence** - Specific days of week (e.g., every Thursday)
- **Date/Time Separation** - Clear distinction between dates and times (e.g., 7-8 PM every Wednesday)
- **Booking System** - Users can join/leave schedules
- **Participant Management** - Track who's joined each schedule

**Infrastructure:**
- **CORS Configuration** for frontend integration
- **PostgreSQL Database** with EF Core
- **Automatic Migrations** in development
- **Interactive API Documentation** with Scalar UI
- **Comprehensive Error Handling** and validation

### ?? Coming Soon (Phase 2)

- **SSO Integration**
  - Google OAuth 2.0
  - Microsoft Azure AD
  - Apple Sign In
  
- **Phone Number Authentication**
  - SMS verification codes
  - Phone number login
  - OTP generation
  
- **Enhanced Security**
  - Email verification
  - Password reset
  - Refresh tokens
  - Account lockout
  - Two-factor authentication (2FA)

- **Notifications**
  - Email notifications for bookings
  - Schedule change alerts
  - Cancellation notifications

## ?? Security Configuration

### JWT Settings

The application validates JWT configuration at startup to ensure security best practices.

**Validation Rules:**
- ? SecretKey must be at least **32 characters** long
- ? SecretKey cannot be null or empty
- ? Application fails at startup with descriptive error if invalid

**Development** (`appsettings.Development.json`):
```json
{
  "JwtSettings": {
    "SecretKey": "DevelopmentSecretKeyForJWTTokenGenerationMinimum32Characters!",
    "Issuer": "PlayOhCanadaAPI",
    "Audience": "PlayOhCanadaAPI",
    "ExpiryMinutes": "1440"  // 24 hours for development
  }
}
```

**Production** (`appsettings.json`):
```json
{
  "JwtSettings": {
    "SecretKey": "GENERATE_A_SECURE_RANDOM_KEY_HERE",
    "Issuer": "PlayOhCanadaAPI",
    "Audience": "PlayOhCanadaAPI",
    "ExpiryMinutes": "60"  // 1 hour for production
  }
}
```

**Generate a Secure Key:**

```powershell
# PowerShell (Windows)
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})

# Bash (Linux/Mac)
openssl rand -base64 48
```

For detailed JWT configuration guidance, see [JWT_SECRETKEY_VALIDATION.md](JWT_SECRETKEY_VALIDATION.md)

### CORS Settings

Configure allowed origins in `appsettings.json`:
```json
{
  "CorsSettings": {
    "AllowedOrigins": [
      "http://localhost:5173",
      "https://localhost:5173",
      "https://your-production-domain.com"
    ]
  }
}
```

?? **IMPORTANT**: 
- Never commit production secrets to Git
- Use User Secrets or Azure Key Vault for production
- Generate a strong random key (64+ characters recommended)
- Application will not start if SecretKey is invalid

### Setting User Secrets (Recommended)

```bash
cd PlayOhCanadaAPI
dotnet user-secrets init
dotnet user-secrets set "JwtSettings:SecretKey" "YourSecureRandomKey64CharactersOrMoreForBetterSecurity!"
dotlogin mdot user-secrets set "ConnectionStrings:DefaultConnection" "YourConnectionString"
```

## ?? Testing the API

### Method 1: Using Scalar UI (Recommended)

1. Run the application
2. Open `https://localhost:7063/scalar/v1`
3. Test endpoints interactively:
   - Click on `/api/auth/register`
   - Fill in the request body
   - Click "Send"
   - Copy the JWT token from response
   - Click "Authorize" button
   - Paste token and save
   - Now test protected endpoints

### Method 2: Using PowerShell Scripts

**Test Authentication Flow:**
```powershell
# Make sure the application is running first
.\test-api.ps1
```

**Test Logout Feature:**
```powershell
# Test complete logout workflow
.\test-logout.ps1
```

**Test Sports & Scheduling:**
```powershell
# Test sports and schedule management
.\test-sports-api.ps1
```

**Test Recurring Schedules:**
```powershell
# Test all recurring schedule patterns
.\test-recurring-schedules.ps1
```

**Test Refined Schedules (Date/Time Separation):**
```powershell
# Test new date/time separated schedule API
.\test-refined-schedules.ps1
```

These scripts will:
- Register a new user
- Login with credentials
- Get user profile
- Test logout functionality
- Verify token revocation
- Create and manage sports
- Create single and recurring schedules
- Test all recurrence patterns (Daily, Weekly, BiWeekly, Monthly)
- Test date and time separation features

### Method 3: Using cURL

**Register:**
```bash
curl -X POST https://localhost:7063/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "password": "SecurePass123!",
    "confirmPassword": "SecurePass123!"
  }' \
  -k
```

**Login:**
```bash
curl -X POST https://localhost:7063/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123!"
  }' \
  -k
```

**Get Profile (with token):**
```bash
curl -X GET https://localhost:7063/api/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -k
```

**Logout:**
```bash
curl -X POST https://localhost:7063/api/auth/logout \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -k
```

**Create Recurring Schedule (Every Wednesday 7-8 PM):**
```bash
curl -X POST https://localhost:7063/api/schedules \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sportId": 1,
    "venue": "Tennis Court A",
    "startDate": "2026-01-07",
    "startTime": "19:00:00",
    "endTime": "20:00:00",
    "maxPlayers": 8,
    "equipmentDetails": "Bring your own racket",
    "recurrence": {
      "isRecurring": true,
      "frequency": 2,
      "daysOfWeek": [3],
      "endDate": "2026-02-28"
    }
  }' \
  -k
```

**Get Schedules:**
```bash
curl -X GET "https://localhost:7063/api/schedules?sportId=1&startDate=2026-01-01" \
  -k
```

**Join a Schedule:**
```bash
curl -X POST https://localhost:7063/api/bookings/join \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "scheduleId": 1
  }' \
  -k
```

## ?? API Endpoints

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/register` | Register new user | No |
| POST | `/api/auth/login` | Login with credentials | No |
| POST | `/api/auth/logout` | Logout and revoke token | Yes |
| GET | `/api/auth/me` | Get current user profile | Yes |

### Sports Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/sports` | Get all sports | No |
| POST | `/api/sports` | Create new sport | Yes (Admin) |
| PUT | `/api/sports/{id}` | Update sport | Yes (Admin) |
| DELETE | `/api/sports/{id}` | Delete sport | Yes (Admin) |

### Schedule Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/schedules` | Get schedules (with filters) | No |
| GET | `/api/schedules/{id}` | Get specific schedule | No |
| POST | `/api/schedules` | Create schedule (single/recurring) | Yes (Admin) |
| PUT | `/api/schedules/{id}` | Update schedule | Yes (Admin) |
| DELETE | `/api/schedules/{id}` | Delete/Cancel schedule | Yes (Admin) |

### Booking Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/bookings/join` | Join a schedule | Yes |
| POST | `/api/bookings/leave/{id}` | Leave a schedule | Yes |
| GET | `/api/bookings/my-bookings` | Get user's bookings | Yes |

## ?? Additional Documentation

- **Refined Schedule API**: [REFINED_SCHEDULE_API_GUIDE.md](REFINED_SCHEDULE_API_GUIDE.md) - Date/Time separation guide
- **Quick Reference**: [REFINED_SCHEDULE_QUICKREF.md](REFINED_SCHEDULE_QUICKREF.md) - Quick reference for common patterns
- **Recurring Schedules**: [RECURRING_SCHEDULE_GUIDE.md](RECURRING_SCHEDULE_GUIDE.md)
- **JWT SecretKey Validation**: [JWT_SECRETKEY_VALIDATION.md](JWT_SECRETKEY_VALIDATION.md)
- **Logout Feature**: [LOGOUT_FEATURE.md](LOGOUT_FEATURE.md)
- **Authentication**: [README_AUTH.md](PlayOhCanadaAPI/README_AUTH.md)
