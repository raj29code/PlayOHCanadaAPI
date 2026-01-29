# Play Oh Canada API - Complete Setup Guide

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

- **User Registration** with email and password
- **User Login** with JWT token generation
- **User Logout** with token revocation (blacklist)
- **User Profile** retrieval with `isAdmin` flag
- **Role-Based Authorization** (Admin/User)
- **Secure Password Hashing** using BCrypt
- **CORS Configuration** for frontend integration
- **PostgreSQL Database** with EF Core
- **Automatic Migrations** in development
- **Interactive API Documentation** with Scalar UI
- **JWT Authentication** with configurable expiry

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
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "YourConnectionString"
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

These scripts will:
- Register a new user
- Login with credentials
- Get user profile
- Test logout functionality
- Verify token revocation

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

## ?? API Endpoints

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/register` | Register new user | No |
| POST | `/api/auth/login` | Login with credentials | No |
| POST | `/api/auth/logout` | Logout and revoke token | Yes |
| GET | `/api/auth/me` | Get current user profile | Yes |

### Response Examples

**Login/Register Response:**
```json
{
  "userId": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "role": "User",
  "isAdmin": false,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": "2024-01-02T10:00:00Z"
}
```

**User Profile Response:**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "role": "User",
  "isAdmin": false,
  "createdAt": "2024-01-01T10:00:00Z",
  "lastLoginAt": "2024-01-01T11:00:00Z"
}
```

**Logout Response:**
```json
{
  "message": "Logged out successfully"
}
```

For detailed logout documentation, see [LOGOUT_FEATURE.md](LOGOUT_FEATURE.md)

## ?? Database Schema

### Users Table

| Column | Type | Constraints |
|--------|------|-------------|
| Id | int | PRIMARY KEY, AUTO_INCREMENT |
| Name | varchar(100) | NOT NULL |
| Email | varchar(100) | NOT NULL, UNIQUE |
| Phone | varchar(20) | UNIQUE (if not null) |
| PasswordHash | text | NOT NULL |
| Role | varchar(20) | NOT NULL, DEFAULT 'User' |
| CreatedAt | timestamp | NOT NULL, DEFAULT now() |
| LastLoginAt | timestamp | NULL |
| ExternalProvider | varchar(50) | NULL (for Phase 2) |
| ExternalProviderId | varchar(200) | NULL (for Phase 2) |
| IsPhoneVerified | boolean | DEFAULT false |
| IsEmailVerified | boolean | DEFAULT false |

### RevokedTokens Table

| Column | Type | Constraints |
|--------|------|-------------|
| Id | int | PRIMARY KEY, AUTO_INCREMENT |
| Token | varchar(500) | NOT NULL, INDEXED |
| UserId | int | NOT NULL |
| RevokedAt | timestamp | NOT NULL, DEFAULT now() |
| ExpiresAt | timestamp | NOT NULL, INDEXED |

### Indexes
- Unique index on `Email`
- Unique partial index on `Phone` (where not null)
- Index on `RevokedTokens.Token`
- Index on `RevokedTokens.ExpiresAt`

## ??? Project Architecture

```
PlayOhCanadaAPI/
?
??? Controllers/
?   ??? AuthController.cs          # Authentication endpoints
?   ??? WeatherForecastController.cs # Example protected endpoint
?
??? Models/
?   ??? User.cs                     # User entity
?   ??? RevokedToken.cs             # Revoked token entity
?   ??? DTOs/
?       ??? AuthDtos.cs             # Request/Response DTOs
?
??? Data/
?   ??? ApplicationDbContext.cs     # EF Core DbContext
?
??? Services/
?   ??? IAuthService.cs             # Auth service interface
?   ??? AuthService.cs              # Auth business logic
?   ??? IJwtService.cs              # JWT service interface
?   ??? JwtService.cs               # JWT token handling
?   ??? ITokenBlacklistService.cs   # Token blacklist interface
?   ??? TokenBlacklistService.cs    # Token revocation logic
?
??? Middleware/
?   ??? TokenBlacklistMiddleware.cs # Token validation middleware
?
??? Migrations/                      # EF Core migrations
?   ??? XXXXXX_InitialCreate.cs
?   ??? XXXXXX_AddRevokedTokenTable.cs
?
??? Properties/
?   ??? launchSettings.json         # Launch profiles
?
??? appsettings.json                # Production config
??? appsettings.Development.json    # Development config
??? Program.cs                      # Application entry point
??? README_AUTH.md                  # Authentication docs
```

## ?? Common Tasks

### Add a New Migration

```bash
dotnet ef migrations add MigrationName --project PlayOhCanadaAPI
```

### Apply Logout Migration

```powershell
.\add-logout-migration.ps1
```

Or manually:
```bash
cd PlayOhCanadaAPI
dotnet ef migrations add AddRevokedTokenTable
dotnet ef database update
```

### Rollback a Migration

```bash
dotnet ef database update PreviousMigrationName --project PlayOhCanadaAPI
```

### Remove Last Migration (if not applied)

```bash
dotnet ef migrations remove --project PlayOhCanadaAPI
```

### View Migration SQL

```bash
dotnet ef migrations script --project PlayOhCanadaAPI
```

### Seed Additional Data

Edit `ApplicationDbContext.cs` in `OnModelCreating` method:
```csharp
modelBuilder.Entity<User>().HasData(
    new User
    {
        Id = 2,
        Name = "Test User",
        Email = "test@example.com",
        PasswordHash = BCrypt.Net.BCrypt.HashPassword("Test@123"),
        Role = UserRoles.User
    }
);
```

## ??? Authorization Examples

### Require Authentication

```csharp
[Authorize]
[HttpGet]
public IActionResult ProtectedEndpoint()
{
    return Ok("You are authenticated!");
}
```

### Require Specific Role

```csharp
[Authorize(Roles = "Admin")]
[HttpGet("admin-only")]
public IActionResult AdminOnlyEndpoint()
{
    return Ok("You are an admin!");
}
```

### Allow Anonymous

```csharp
[AllowAnonymous]
[HttpGet("public")]
public IActionResult PublicEndpoint()
{
    return Ok("Anyone can access this!");
}
```

### Get Current User Info

```csharp
[Authorize]
[HttpGet("my-data")]
public async Task<IActionResult> GetMyData()
{
    var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    var userEmail = User.FindFirst(ClaimTypes.Email)?.Value;
    var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
    
    return Ok(new { userId, userEmail, userRole });
}
```

## ?? Troubleshooting

### Database Connection Fails

1. Check PostgreSQL is running:
   ```bash
   psql -U postgres -c "SELECT version();"
   ```

2. Verify connection string in `appsettings.Development.json`

3. Check firewall settings (PostgreSQL default port: 5432)

### JWT Token Invalid

1. **SecretKey too short or missing:**
   - Error: `JWT SecretKey must be at least 32 characters long`
   - Solution: Generate a new secure key (see [JWT_SECRETKEY_VALIDATION.md](JWT_SECRETKEY_VALIDATION.md))
   - Update configuration with the new key (64+ characters recommended)

2. **Token expired:**
   - Check token expiry time in JWT settings
   - Users must re-login to get a new token

3. **Clock synchronization issues:**
   - Verify clock synchronization between systems
   - Ensure server time is accurate

4. **Malformed token:**
   - Ensure Bearer token is properly formatted: `Bearer YOUR_TOKEN`
   - No extra spaces or characters

5. **Configuration mismatch:**
   - Ensure same SecretKey in all environments
   - Verify Issuer and Audience match

### Token Still Works After Logout

1. Ensure migration is applied: `dotnet ef database update`
2. Check middleware order in `Program.cs` (TokenBlacklist after Authentication)
3. Verify token is being sent in Authorization header

### Migration Fails

1. Check database connection
2. Ensure no pending migrations: `dotnet ef migrations list`
3. Try dropping the database and recreating:
   ```bash
   dotnet ef database drop --project PlayOhCanadaAPI
   dotnet ef database update --project PlayOhCanadaAPI
   ```

### Port Already in Use

Edit `PlayOhCanadaAPI/Properties/launchSettings.json`:
```json
{
  "applicationUrl": "https://localhost:7063;http://localhost:5005"
}
```
Change ports 7063 and 5005 to available ports.

### CORS Errors

1. Verify frontend URL is in `CorsSettings:AllowedOrigins`
2. Check middleware order (CORS before Authentication)
3. Ensure credentials are enabled if using cookies/auth

## ?? API Documentation

Full API documentation is available at:
- **Scalar UI**: `https://localhost:7063/scalar/v1` (Development)
- **OpenAPI JSON**: `https://localhost:7063/openapi/v1.json`

Additional documentation:
- **JWT SecretKey Validation**: [JWT_SECRETKEY_VALIDATION.md](JWT_SECRETKEY_VALIDATION.md)
- **Logout Feature**: [LOGOUT_FEATURE.md](LOGOUT_FEATURE.md)
- **Authentication**: [README_AUTH.md](PlayOhCanadaAPI/README_AUTH.md)

## ?? Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `dotnet test`
4. Build: `dotnet build`
5. Submit pull request

## ?? Support

For issues or questions:
- GitHub Issues: https://github.com/raj29code/PlayOHCanadaAPI/issues
- Email: support@playohcanada.com

## ?? License

[Your License Here]

---

**Default Admin Credentials (Development Only)**
- Email: admin@playohcanada.com
- Password: Admin@123
- Role: Admin

?? **Delete or change these credentials before deploying to production!**
