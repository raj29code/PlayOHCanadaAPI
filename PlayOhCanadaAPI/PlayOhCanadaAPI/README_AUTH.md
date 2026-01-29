# Play Oh Canada API - Authentication Setup

## Features Implemented

### Phase 1: Forms Authentication ?
- **User Registration** (`POST /api/auth/register`)
- **User Login** (`POST /api/auth/login`)
- **Get Current User Profile** (`GET /api/auth/me`)
- JWT Token-based authentication
- PostgreSQL database with EF Core
- Secure password hashing using BCrypt

### Phase 2: Coming Soon ??
- SSO Integration (Google, Microsoft, Apple)
- Phone number login with verification
- Email verification
- Password reset functionality

## Database Setup

### 1. Install PostgreSQL
Download and install PostgreSQL from https://www.postgresql.org/download/

### 2. Update Connection String
Edit `appsettings.Development.json` and update the connection string:
```json
"ConnectionStrings": {
  "DefaultConnection": "Host=localhost;Port=5432;Database=PlayOhCanadaDb_Dev;Username=postgres;Password=YOUR_PASSWORD"
}
```

### 3. Run Migrations
```bash
# Create initial migration
dotnet ef migrations add InitialCreate --project PlayOhCanadaAPI

# Apply migration to database
dotnet ef database update --project PlayOhCanadaAPI
```

The application will automatically apply migrations in Development mode when it starts.

## User Model

```csharp
public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }          // Unique, required
    public string? Phone { get; set; }         // Unique (if provided)
    public string PasswordHash { get; set; }
    public string Role { get; set; }           // "Admin" or "User"
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }
    
    // Future Phase 2 fields
    public string? ExternalProvider { get; set; }
    public string? ExternalProviderId { get; set; }
    public bool IsPhoneVerified { get; set; }
    public bool IsEmailVerified { get; set; }
}
```

## API Endpoints

### Register New User
```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "SecurePassword123!",
  "confirmPassword": "SecurePassword123!"
}
```

**Response:**
```json
{
  "userId": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "role": "User",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": "2024-01-01T12:00:00Z"
}
```

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePassword123!"
}
```

**Response:** Same as registration response

### Get Current User Profile
```http
GET /api/auth/me
Authorization: Bearer {token}
```

**Response:**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "role": "User",
  "createdAt": "2024-01-01T10:00:00Z",
  "lastLoginAt": "2024-01-01T11:30:00Z"
}
```

## Testing with Scalar UI

1. Run the application: `dotnet run --project PlayOhCanadaAPI`
2. Open browser to: `https://localhost:7063/scalar/v1`
3. Use the interactive UI to:
   - Register a new user
   - Login with credentials
   - Copy the JWT token from the response
   - Click "Authorize" and paste the token
   - Test the `/api/auth/me` endpoint

## Default Admin Account

For development, a default admin account is seeded:
- **Email:** admin@playohcanada.com
- **Password:** Admin@123
- **Role:** Admin

## Security Features

- ? Passwords hashed with BCrypt
- ? JWT tokens with configurable expiry
- ? Email uniqueness validation
- ? Phone number uniqueness validation
- ? Role-based authorization ready
- ? Secure token validation
- ? Input validation on all endpoints

## JWT Configuration

Update `appsettings.json` for production:
```json
"JwtSettings": {
  "SecretKey": "YOUR_SUPER_SECRET_KEY_AT_LEAST_32_CHARACTERS",
  "Issuer": "PlayOhCanadaAPI",
  "Audience": "PlayOhCanadaAPI",
  "ExpiryMinutes": "60"
}
```

?? **Important:** Change the `SecretKey` in production!

## Phase 2 Planning

### SSO Integration
- Google OAuth 2.0
- Microsoft Azure AD
- Apple Sign In
- External provider mapping in User table

### Phone Login
- SMS verification code service
- Phone number validation
- OTP generation and verification
- Rate limiting for SMS

### Additional Features
- Email verification with confirmation links
- Password reset with email tokens
- Refresh tokens for extended sessions
- Account lockout after failed attempts
- Two-factor authentication (2FA)

## Project Structure

```
PlayOhCanadaAPI/
??? Controllers/
?   ??? AuthController.cs       # Authentication endpoints
?   ??? WeatherForecastController.cs
??? Models/
?   ??? User.cs                # User entity
?   ??? DTOs/
?       ??? AuthDtos.cs        # Request/Response DTOs
??? Data/
?   ??? ApplicationDbContext.cs # EF Core DbContext
??? Services/
?   ??? JwtService.cs          # JWT token generation/validation
?   ??? AuthService.cs         # Authentication business logic
??? Migrations/                 # EF Core migrations
??? appsettings.json           # Configuration
```

## Next Steps

1. Install PostgreSQL and configure connection string
2. Run migrations to create database
3. Test authentication endpoints using Scalar UI
4. Implement protected endpoints using `[Authorize]` attribute
5. Plan Phase 2 SSO and phone authentication features
