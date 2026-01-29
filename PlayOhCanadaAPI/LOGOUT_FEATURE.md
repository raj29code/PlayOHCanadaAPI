# Logout Feature Documentation

## Overview
The logout feature has been implemented using a token blacklist approach. When a user logs out, their JWT token is added to a blacklist (RevokedTokens table), preventing further use of that token even though it hasn't technically expired.

## Implementation Details

### Components Added

1. **RevokedToken Model** (`Models/RevokedToken.cs`)
   - Stores revoked tokens with their expiration times
   - Automatically cleaned up after token expiration

2. **TokenBlacklistService** (`Services/TokenBlacklistService.cs`)
   - Manages token revocation and validation
   - Provides cleanup method for expired tokens
   - Interface: `ITokenBlacklistService`

3. **TokenBlacklistMiddleware** (`Middleware/TokenBlacklistMiddleware.cs`)
   - Intercepts all requests with JWT tokens
   - Checks if token is blacklisted before proceeding
   - Returns 401 Unauthorized for revoked tokens

4. **Database Migration**
   - New `RevokedTokens` table with indexes for performance
   - Automatically applied on next run

### API Endpoint

#### POST `/api/auth/logout`

**Description:** Logout the current user by revoking their JWT token

**Authentication:** Required (Bearer Token)

**Request Headers:**
```
Authorization: Bearer <your-jwt-token>
```

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

**Response (401 Unauthorized):**
```json
{
  "message": "Invalid token"
}
```

**Response (500 Internal Server Error):**
```json
{
  "message": "Logout failed"
}
```

## How It Works

1. **User initiates logout:**
   - Sends POST request to `/api/auth/logout` with their token in Authorization header

2. **Token is blacklisted:**
   - Token is extracted from the Authorization header
   - Token's expiration time is retrieved
   - Token is added to RevokedTokens table with user ID and expiration

3. **Subsequent requests blocked:**
   - Middleware checks every request for blacklisted tokens
   - If token is in blacklist and not expired, request is rejected with 401
   - User must login again to get a new valid token

4. **Automatic cleanup:**
   - Expired tokens can be cleaned up from the blacklist
   - Call `CleanupExpiredTokensAsync()` on the service
   - Can be scheduled as a background job

## Testing

Run the test script to verify logout functionality:

```powershell
.\test-logout.ps1
```

This will:
1. Login with admin credentials
2. Retrieve user profile with token
3. Logout (revoke token)
4. Attempt to use revoked token (should fail)
5. Login again with new token
6. Verify new token works

## Database Setup

Run the migration script to add the RevokedTokens table:

```powershell
.\add-logout-migration.ps1
```

Or manually:
```powershell
cd PlayOhCanadaAPI
dotnet ef migrations add AddRevokedTokenTable
dotnet ef database update
```

## Usage Examples

### JavaScript/Fetch Example

```javascript
// Logout
async function logout() {
  const token = localStorage.getItem('token');
  
  try {
    const response = await fetch('http://localhost:5000/api/auth/logout', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      // Clear token from storage
      localStorage.removeItem('token');
      console.log('Logged out successfully');
      // Redirect to login page
      window.location.href = '/login';
    }
  } catch (error) {
    console.error('Logout failed:', error);
  }
}
```

### React Example

```jsx
import { useState } from 'react';

function LogoutButton() {
  const [loading, setLoading] = useState(false);
  
  const handleLogout = async () => {
    setLoading(true);
    const token = localStorage.getItem('token');
    
    try {
      const response = await fetch('http://localhost:5000/api/auth/logout', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (response.ok) {
        localStorage.removeItem('token');
        // Navigate to login page
        window.location.href = '/login';
      } else {
        alert('Logout failed');
      }
    } catch (error) {
      console.error('Error:', error);
      alert('Logout failed');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <button onClick={handleLogout} disabled={loading}>
      {loading ? 'Logging out...' : 'Logout'}
    </button>
  );
}
```

### cURL Example

```bash
# Logout with token
curl -X POST http://localhost:5000/api/auth/logout \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

## Security Considerations

1. **Token Storage on Client:**
   - Always clear token from client storage (localStorage/sessionStorage) after logout
   - Never rely solely on server-side revocation

2. **Token Expiration:**
   - Revoked tokens are kept in the blacklist until their original expiration
   - This ensures security during the token's intended lifetime

3. **Performance:**
   - Blacklist checks are optimized with database indexes
   - Consider implementing caching (Redis) for high-traffic applications

4. **Cleanup:**
   - Schedule periodic cleanup of expired tokens
   - Prevents database bloat from accumulating expired entries

## Optional: Background Cleanup Job

To automatically clean up expired tokens, you can add a background service:

```csharp
// Services/TokenCleanupService.cs
public class TokenCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<TokenCleanupService> _logger;
    
    public TokenCleanupService(
        IServiceProvider serviceProvider,
        ILogger<TokenCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }
    
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var tokenService = scope.ServiceProvider
                    .GetRequiredService<ITokenBlacklistService>();
                
                await tokenService.CleanupExpiredTokensAsync();
                
                // Run cleanup every hour
                await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in token cleanup service");
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
        }
    }
}

// Register in Program.cs
builder.Services.AddHostedService<TokenCleanupService>();
```

## Frontend Integration

After logout, ensure you:
1. Clear the token from storage
2. Clear any user state
3. Redirect to login page
4. Remove Authorization header from API client

Example with Axios:
```javascript
// Clear token and redirect
delete axios.defaults.headers.common['Authorization'];
localStorage.removeItem('token');
window.location.href = '/login';
```

## Troubleshooting

**Issue:** Logout returns 401
- **Cause:** Token is already expired or invalid
- **Solution:** This is expected behavior; clear token on client side

**Issue:** Can still use token after logout
- **Cause:** Middleware not registered or registered in wrong order
- **Solution:** Ensure `app.UseTokenBlacklist()` is after `app.UseAuthentication()`

**Issue:** Database errors during logout
- **Cause:** Migration not applied
- **Solution:** Run `dotnet ef database update`

## Summary

The logout feature provides secure token revocation with:
- ? Token blacklisting
- ? Middleware validation
- ? Automatic cleanup support
- ? Easy integration
- ? Complete test coverage
