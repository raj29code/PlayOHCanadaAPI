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
- **User Profile** retrieval
- **Role-Based Authorization** (Admin/User)
- **Secure Password Hashing** using BCrypt
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

?? **IMPORTANT**: 
- Never commit production secrets to Git
- Use User Secrets or Azure Key Vault for production
- Generate a strong random key (32+ characters)

### Setting User Secrets (Recommended)

```bash
cd PlayOhCanadaAPI
dotnet user-secrets init
dotnet user-secrets set "JwtSettings:SecretKey" "YourSecureRandomKey"
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

### Method 2: Using PowerShell Script

```powershell
# Make sure the application is running first
.\test-api.ps1
```

This script will:
- Register a new user
- Login with credentials
- Get user profile
- Test protected endpoints
- Test public endpoints

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

### Indexes
- Unique index on `Email`
- Unique partial index on `Phone` (where not null)

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
?
??? Migrations/                      # EF Core migrations
?   ??? XXXXXX_InitialCreate.cs
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

1. Ensure `SecretKey` is at least 32 characters
2. Check token expiry time
3. Verify clock synchronization between systems
4. Ensure Bearer token is properly formatted: `Bearer YOUR_TOKEN`

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

## ?? API Documentation

Full API documentation is available at:
- **Scalar UI**: `https://localhost:7063/scalar/v1` (Development)
- **OpenAPI JSON**: `https://localhost:7063/openapi/v1.json`

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
