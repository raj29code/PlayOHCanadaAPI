# JWT SecretKey Validation Guide

## Overview

The application now includes **runtime validation** for the JWT SecretKey to ensure security and prevent common configuration errors. This validation occurs at two points:

1. **Application Startup** (`Program.cs`) - Fails fast if configuration is invalid
2. **JwtService Constructor** - Additional safety check when service is instantiated

## Validation Rules

### Minimum Requirements

? **Length:** Must be at least **32 characters**
? **Not Empty:** Cannot be null, empty, or whitespace
? **Configured:** Must be present in configuration

## Error Messages

### Missing SecretKey

```
InvalidOperationException: JWT SecretKey is not configured. 
Please set JwtSettings:SecretKey in appsettings.json or user secrets.
```

**Solution:** Add the SecretKey to your configuration file.

### SecretKey Too Short

```
InvalidOperationException: JWT SecretKey must be at least 32 characters long. 
Current length: 16 characters. 
Please update JwtSettings:SecretKey in appsettings.json or user secrets.
```

**Solution:** Generate a longer, more secure key.

## How to Fix

### Option 1: Update appsettings.json (Development Only)

**DON'T use this for production!**

```json
{
  "JwtSettings": {
    "SecretKey": "YourSuperSecretKeyForJWTTokenGenerationMinimum32Characters!",
    "Issuer": "PlayOhCanadaAPI",
    "Audience": "PlayOhCanadaAPI",
    "ExpiryMinutes": "60"
  }
}
```

### Option 2: Use User Secrets (Recommended for Development)

```bash
cd PlayOhCanadaAPI
dotnet user-secrets init
dotnet user-secrets set "JwtSettings:SecretKey" "YourSuperSecretKeyForJWTTokenGenerationMinimum32Characters!"
```

### Option 3: Environment Variables (Recommended for Production)

**Windows:**
```powershell
$env:JwtSettings__SecretKey = "YourSuperSecretKeyForJWTTokenGenerationMinimum32Characters!"
```

**Linux/Mac:**
```bash
export JwtSettings__SecretKey="YourSuperSecretKeyForJWTTokenGenerationMinimum32Characters!"
```

**Docker:**
```yaml
environment:
  - JwtSettings__SecretKey=YourSuperSecretKeyForJWTTokenGenerationMinimum32Characters!
```

### Option 4: Azure App Service / Key Vault (Production)

1. Store in Azure Key Vault
2. Reference in App Service Configuration:
   ```
   Name: JwtSettings:SecretKey
   Value: @Microsoft.KeyVault(SecretUri=https://your-vault.vault.azure.net/secrets/jwt-secret/)
   ```

## Generating a Secure Key

### PowerShell (Windows)

```powershell
# Generate a random 64-character key
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})
```

### Bash (Linux/Mac)

```bash
# Generate a random 64-character key
openssl rand -base64 48
```

### C# Console

```csharp
using System.Security.Cryptography;

var key = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
Console.WriteLine(key);
```

### Online Tools

- **Base64 Encoder**: https://generate.plus/en/base64
- **Random String Generator**: https://randomkeygen.com/

?? **Important:** Never use keys from online generators for production. Always generate locally.

## Best Practices

### ? DO:

- Use at least **64 characters** for production
- Generate cryptographically secure random keys
- Store secrets in secure vaults (Azure Key Vault, AWS Secrets Manager)
- Use User Secrets for local development
- Rotate keys periodically
- Use different keys for different environments

### ? DON'T:

- Commit secrets to Git repositories
- Use weak or short keys (< 32 characters)
- Use predictable patterns (e.g., "Password123")
- Share keys across multiple applications
- Store keys in plaintext files
- Use the same key for development and production

## Configuration Hierarchy

ASP.NET Core loads configuration in this order (later sources override earlier ones):

1. `appsettings.json`
2. `appsettings.{Environment}.json`
3. User Secrets (Development only)
4. Environment Variables
5. Command-line arguments

## Example Configurations

### Development (User Secrets)

```bash
cd PlayOhCanadaAPI
dotnet user-secrets set "JwtSettings:SecretKey" "DevSecretKeyForLocalTestingOnlyMinimum32CharactersLong!"
dotnet user-secrets set "JwtSettings:Issuer" "PlayOhCanadaAPI"
dotnet user-secrets set "JwtSettings:Audience" "PlayOhCanadaAPI"
dotnet user-secrets set "JwtSettings:ExpiryMinutes" "1440"
```

### Production (Environment Variables)

```bash
JwtSettings__SecretKey="ProdSecretKeyFromAzureKeyVaultOrSecureStorageMinimum64Chars!"
JwtSettings__Issuer="PlayOhCanadaAPI"
JwtSettings__Audience="PlayOhCanadaAPI"
JwtSettings__ExpiryMinutes="60"
```

### Docker Compose

```yaml
version: '3.8'
services:
  api:
    image: playohcanadaapi:latest
    environment:
      - JwtSettings__SecretKey=${JWT_SECRET_KEY}
      - JwtSettings__Issuer=PlayOhCanadaAPI
      - JwtSettings__Audience=PlayOhCanadaAPI
      - JwtSettings__ExpiryMinutes=60
    env_file:
      - .env.production
```

## Troubleshooting

### Issue: "JWT SecretKey is not configured"

**Cause:** Missing configuration entry

**Solution:**
1. Check `appsettings.json` has `JwtSettings:SecretKey`
2. Verify User Secrets are set: `dotnet user-secrets list`
3. Check environment variables: `echo $env:JwtSettings__SecretKey` (Windows) or `echo $JwtSettings__SecretKey` (Linux)

### Issue: "JWT SecretKey must be at least 32 characters long"

**Cause:** Key is too short

**Solution:**
1. Generate a new key (see "Generating a Secure Key" section)
2. Update your configuration with the new key
3. Restart the application

### Issue: Application starts but JWT validation fails

**Cause:** Key mismatch between token generation and validation

**Solution:**
1. Ensure the same key is used in all environments
2. Clear old tokens
3. Users must re-login to get new tokens

### Issue: Works locally but fails in production

**Cause:** Configuration not deployed correctly

**Solution:**
1. Verify environment variables are set in production
2. Check Azure App Service Configuration
3. Ensure Key Vault access is configured
4. Review deployment logs

## Security Considerations

### Key Strength

- **32 characters minimum** (enforced)
- **64+ characters recommended** for production
- **High entropy** - use random, unpredictable characters

### Key Storage

- **Never in source code** - Always use external configuration
- **Encrypted at rest** - Use secure vaults
- **Encrypted in transit** - Use HTTPS/TLS
- **Access control** - Restrict who can read secrets

### Key Rotation

Implement a key rotation strategy:

1. Generate new key
2. Configure application to validate both old and new keys
3. Issue new tokens with new key
4. After grace period, remove old key

### Monitoring

- Log failed token validations (without exposing key)
- Monitor for suspicious patterns
- Alert on configuration errors
- Track token expiration and renewal

## References

- [ASP.NET Core Configuration](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/)
- [User Secrets](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets)
- [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/)
- [JWT Best Practices](https://datatracker.ietf.org/doc/html/rfc8725)

## Summary

The JWT SecretKey validation ensures:
- ? Configuration errors are caught at startup
- ? Descriptive error messages guide developers
- ? Security best practices are enforced
- ? Application fails fast with clear feedback

This prevents runtime errors and improves security by ensuring proper JWT configuration before the application accepts requests.
