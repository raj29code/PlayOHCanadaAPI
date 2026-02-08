# Admin Registration Feature

## Overview

The registration endpoint now supports creating both admin and non-admin users using the `isAdmin` flag.

## What Changed

### RegisterRequest DTO

Added `isAdmin` property:

```csharp
public class RegisterRequest
{
    // ... existing properties ...
    
    /// <summary>
    /// Flag to indicate if the user should be created as an admin
    /// Defaults to false (regular user)
    /// </summary>
    public bool IsAdmin { get; set; } = false;
}
```

### AuthService

Updated to use the `isAdmin` flag:

```csharp
// Determine role based on isAdmin flag
var role = request.IsAdmin ? UserRoles.Admin : UserRoles.User;

var user = new User
{
    // ... other properties ...
    Role = role,
    // ...
};
```

## Usage

### Register Regular User

**Request:**
```json
POST /api/auth/register

{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!",
  "isAdmin": false
}
```

**Response:**
```json
{
  "userId": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "role": "User",
  "isAdmin": false,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expiresAt": "2026-01-29T12:00:00Z"
}
```

### Register Admin User

**Request:**
```json
POST /api/auth/register

{
  "name": "Admin User",
  "email": "admin@example.com",
  "password": "AdminPass123!",
  "confirmPassword": "AdminPass123!",
  "isAdmin": true
}
```

**Response:**
```json
{
  "userId": 124,
  "name": "Admin User",
  "email": "admin@example.com",
  "phone": null,
  "role": "Admin",
  "isAdmin": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expiresAt": "2026-01-29T12:00:00Z"
}
```

### Register Without isAdmin Flag (Default Behavior)

**Request:**
```json
POST /api/auth/register

{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!"
}
```

**Response:**
```json
{
  "userId": 125,
  "name": "Jane Doe",
  "email": "jane@example.com",
  "phone": null,
  "role": "User",
  "isAdmin": false,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expiresAt": "2026-01-29T12:00:00Z"
}
```

**Note:** When `isAdmin` is not provided, it defaults to `false`, creating a regular user.

## Examples

### JavaScript/Frontend

```javascript
// Register regular user
async function registerUser(userData) {
  const response = await fetch('/api/auth/register', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      name: userData.name,
      email: userData.email,
      password: userData.password,
      confirmPassword: userData.confirmPassword,
      isAdmin: false  // Regular user
    })
  });
  
  return await response.json();
}

// Register admin user
async function registerAdmin(userData) {
  const response = await fetch('/api/auth/register', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      name: userData.name,
      email: userData.email,
      password: userData.password,
      confirmPassword: userData.confirmPassword,
      isAdmin: true  // Admin user
    })
  });
  
  return await response.json();
}
```

### PowerShell

```powershell
# Register regular user
$regularUser = @{
    name = "John Doe"
    email = "john@example.com"
    password = "SecurePass123!"
    confirmPassword = "SecurePass123!"
    isAdmin = $false
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://localhost:7063/api/auth/register" `
    -Method Post -Body $regularUser -ContentType "application/json"

Write-Host "User registered: $($response.name) (Role: $($response.role))"

# Register admin user
$adminUser = @{
    name = "Admin User"
    email = "admin@example.com"
    password = "AdminPass123!"
    confirmPassword = "AdminPass123!"
    isAdmin = $true
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://localhost:7063/api/auth/register" `
    -Method Post -Body $adminUser -ContentType "application/json"

Write-Host "Admin registered: $($response.name) (Role: $($response.role))"
```

### cURL

```bash
# Register regular user
curl -X POST https://localhost:7063/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123!",
    "confirmPassword": "SecurePass123!",
    "isAdmin": false
  }' \
  -k

# Register admin user
curl -X POST https://localhost:7063/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin User",
    "email": "admin@example.com",
    "password": "AdminPass123!",
    "confirmPassword": "AdminPass123!",
    "isAdmin": true
  }' \
  -k
```

## Use Cases

### Use Case 1: Self-Service Regular User Registration

**Scenario:** New users sign up through the app

```javascript
// In registration form
const handleRegister = async (formData) => {
  const response = await fetch('/api/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      ...formData,
      isAdmin: false  // Always false for self-registration
    })
  });
  
  const data = await response.json();
  
  if (response.ok) {
    localStorage.setItem('token', data.token);
    navigate('/dashboard');
  }
};
```

### Use Case 2: Admin Creates Another Admin

**Scenario:** Existing admin creates a new admin account

```javascript
// In admin panel
const createAdminUser = async (formData) => {
  const response = await fetch('/api/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      ...formData,
      isAdmin: true  // Create as admin
    })
  });
  
  const data = await response.json();
  
  if (response.ok) {
    alert(`Admin created: ${data.name}`);
  }
};
```

### Use Case 3: First-Time Setup

**Scenario:** Setting up the first admin during initial deployment

```powershell
# Create initial admin account
$adminData = @{
    name = "System Administrator"
    email = "admin@playohcanada.com"
    password = "InitialAdminPass123!"
    confirmPassword = "InitialAdminPass123!"
    isAdmin = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://localhost:7063/api/auth/register" `
    -Method Post -Body $adminData -ContentType "application/json"
```

## Security Considerations

### Current Implementation

?? **Public Registration Endpoint** - Anyone can register as admin by setting `isAdmin: true`

**This is suitable for:**
- Development/testing
- Initial setup
- Small internal applications
- When you control who has access to the API

### Recommended for Production

For production, you should add additional security:

#### Option 1: Admin Authorization Required

Only existing admins can create new admins:

```csharp
[HttpPost("register")]
public async Task<IActionResult> Register([FromBody] RegisterRequest request)
{
    // If trying to register as admin, require admin authorization
    if (request.IsAdmin)
    {
        // Check if user is authenticated and is admin
        if (!User.Identity?.IsAuthenticated ?? true)
        {
            return Unauthorized(new { message = "Admin registration requires authentication" });
        }
        
        if (!User.IsInRole(UserRoles.Admin))
        {
            return Forbid("Only admins can create admin accounts");
        }
    }
    
    // Rest of registration logic...
}
```

#### Option 2: Secret Key for Admin Registration

Require a secret key to create admin accounts:

```csharp
public class RegisterRequest
{
    // ... existing properties ...
    
    public bool IsAdmin { get; set; } = false;
    
    /// <summary>
    /// Required when IsAdmin is true
    /// </summary>
    public string? AdminSecretKey { get; set; }
}

// In AuthService
public async Task<AuthResponse?> RegisterAsync(RegisterRequest request)
{
    // If admin registration, verify secret key
    if (request.IsAdmin)
    {
        var expectedKey = _configuration["AdminRegistration:SecretKey"];
        if (string.IsNullOrEmpty(request.AdminSecretKey) || 
            request.AdminSecretKey != expectedKey)
        {
            _logger.LogWarning("Invalid admin secret key provided");
            return null;
        }
    }
    
    // Rest of registration logic...
}
```

#### Option 3: Disable Public Admin Registration

Force admin accounts to be created via database/migration only:

```csharp
[HttpPost("register")]
public async Task<IActionResult> Register([FromBody] RegisterRequest request)
{
    // Prevent admin registration via API
    if (request.IsAdmin)
    {
        return BadRequest(new { message = "Admin accounts cannot be created through public registration" });
    }
    
    // Rest of registration logic...
}
```

**Use migrations or direct database insertion for admin accounts.**

## Best Practices

### ? DO:

1. **For Development:**
   - Use `isAdmin: true` freely for testing
   - Create test admin accounts easily

2. **For Production:**
   - Implement one of the security options above
   - Audit admin account creation
   - Use strong passwords for admins
   - Limit admin access

3. **General:**
   - Validate passwords properly
   - Log admin account creation
   - Monitor admin activity

### ? DON'T:

1. **Don't allow public admin registration in production** without additional security
2. **Don't share admin credentials** across multiple users
3. **Don't ignore security** - even for internal applications
4. **Don't forget to log** admin account creation

## Backward Compatibility

? **Fully backward compatible**

**Old registration requests (without isAdmin) still work:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!"
}
```

**Defaults to regular user (isAdmin: false)**

## Testing

### Test Regular User Registration

```powershell
$user = @{
    name = "Test User"
    email = "testuser@example.com"
    password = "TestPass123!"
    confirmPassword = "TestPass123!"
    isAdmin = $false
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://localhost:7063/api/auth/register" `
    -Method Post -Body $user -ContentType "application/json"

# Verify role
if ($response.role -eq "User" -and $response.isAdmin -eq $false) {
    Write-Host "? Regular user created successfully" -ForegroundColor Green
}
```

### Test Admin User Registration

```powershell
$admin = @{
    name = "Test Admin"
    email = "testadmin@example.com"
    password = "AdminPass123!"
    confirmPassword = "AdminPass123!"
    isAdmin = $true
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://localhost:7063/api/auth/register" `
    -Method Post -Body $admin -ContentType "application/json"

# Verify role
if ($response.role -eq "Admin" -and $response.isAdmin -eq $true) {
    Write-Host "? Admin user created successfully" -ForegroundColor Green
}
```

### Test Default Behavior

```powershell
$defaultUser = @{
    name = "Default User"
    email = "default@example.com"
    password = "DefaultPass123!"
    confirmPassword = "DefaultPass123!"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://localhost:7063/api/auth/register" `
    -Method Post -Body $defaultUser -ContentType "application/json"

# Verify defaults to regular user
if ($response.role -eq "User" -and $response.isAdmin -eq $false) {
    Write-Host "? Default registration creates regular user" -ForegroundColor Green
}
```

## Logging

The service now logs the role when registering:

```
New User registered: john@example.com
New Admin registered: admin@example.com
```

This helps track admin account creation.

## Summary

### What Was Added

? **isAdmin flag** to RegisterRequest DTO  
? **Role determination** based on flag in AuthService  
? **Default to regular user** (isAdmin: false)  
? **Backward compatible** - works without flag  
? **Enhanced logging** - logs role on registration  

### Benefits

? **Flexible registration** - Create both user types  
? **Simple API** - Single endpoint for both  
? **Easy testing** - Quick admin account creation  
? **Backward compatible** - Existing code works  

### Security Note

?? **For production:** Add additional security (see Security Considerations section)

### Usage

```json
// Regular user
{ ..., "isAdmin": false }

// Admin user
{ ..., "isAdmin": true }

// Default (no flag)
{ ... }  ? Creates regular user
```

**Now you can easily create both regular users and admin users through the registration endpoint!** ???
