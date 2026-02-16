# ?? Railway Variables Cleanup Guide

## Current State Analysis

Based on your Railway dashboard screenshots:

### ? PostgreSQL Service (GOOD)
- Status: Online
- Variables: All auto-generated (DATABASE_URL, PGHOST, PGUSER, PGPASSWORD, etc.)
- **Action Required:** None - Leave as-is

### ?? API Service (NEEDS CLEANUP)

---

## ?? Step-by-Step Cleanup

### Step 1: Remove Incorrect Variables

In Railway Dashboard ? **PlayOHCanadaAPI** service ? Variables tab:

**DELETE these variables:**

1. ? `ConnectionStrings__DefaultConnection`
   - **Reason:** Wrong format, code now uses DATABASE_URL or PG variables

2. ? `CORS__AllowedOrigins` (if using single underscore)
   - **Reason:** Wrong naming, should be `CorsSettings__AllowedOrigins__0`

---

### Step 2: Update DATABASE_URL Reference

**CHANGE:**
```bash
? DATABASE_URL=postgresql://postgres:gQzKNytMTsRZvzItGIHfJmFFZqUUZIni@postgres.railway.internal:5432/railway
```

**TO:**
```bash
? DATABASE_URL=${{Postgres.DATABASE_URL}}
```

**Why?** This references the PostgreSQL service variable dynamically. If Railway changes the password or host, your API automatically gets the update.

---

### Step 3: Fix CORS Variable

**CHANGE:**
```bash
? CORS__AllowedOrigins=...
```

**TO:**
```bash
? CorsSettings__AllowedOrigins__0=https://your-frontend-url.com
```

**Why?** .NET configuration uses double underscore and array index syntax.

---

### Step 4: Verify Required Variables

After cleanup, your API service should have **EXACTLY** these variables:

```bash
# Environment
? ASPNETCORE_ENVIRONMENT=Production

# Database (Reference to Postgres service)
? DATABASE_URL=${{Postgres.DATABASE_URL}}

# JWT Settings
? JwtSettings__SecretKey=[your-32-char-secret]
? JwtSettings__Issuer=PlayOhCanadaAPI
? JwtSettings__Audience=PlayOhCanadaAPI
? JwtSettings__ExpiryMinutes=60

# CORS Settings
? CorsSettings__AllowedOrigins__0=https://your-frontend.railway.app
# Add more origins if needed:
# CorsSettings__AllowedOrigins__1=https://custom-domain.com

# Schedule Cleanup (Optional)
? ScheduleCleanup__CleanupIntervalHours=24
? ScheduleCleanup__RetentionDays=7
```

---

## ? Do You Need to Add PG Variables Manually?

### **NO!** Here's why:

Your code has **automatic fallback**:

```csharp
// Step 1: Try DATABASE_URL first
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");

// Step 2: If that fails, automatically use PGHOST, PGUSER, PGPASSWORD
var pgHost = Environment.GetEnvironmentVariable("PGHOST");
var pgUser = Environment.GetEnvironmentVariable("PGUSER");
var pgPassword = Environment.GetEnvironmentVariable("PGPASSWORD");
```

Railway **automatically makes Postgres service variables available** to services in the same project. You don't need to manually copy them.

---

## ?? Final API Service Variables List

After cleanup, you should have **9-11 variables** total:

| Variable Name | Value | Source |
|--------------|-------|--------|
| ASPNETCORE_ENVIRONMENT | Production | Manual |
| DATABASE_URL | ${{Postgres.DATABASE_URL}} | Reference |
| JwtSettings__SecretKey | [32+ chars] | Manual |
| JwtSettings__Issuer | PlayOhCanadaAPI | Manual |
| JwtSettings__Audience | PlayOhCanadaAPI | Manual |
| JwtSettings__ExpiryMinutes | 60 | Manual |
| CorsSettings__AllowedOrigins__0 | https://... | Manual |
| ScheduleCleanup__CleanupIntervalHours | 24 | Manual |
| ScheduleCleanup__RetentionDays | 7 | Manual |

**Plus Railway auto-provided variables:**
- PORT (auto by Railway)
- RAILWAY_* variables (auto by Railway)

---

## ?? How Railway Variable References Work

When you use `${{Postgres.DATABASE_URL}}`:

1. Railway looks for a service named "Postgres" in your project
2. Finds the `DATABASE_URL` variable in that service
3. Injects the actual value at runtime
4. If Postgres password changes, API automatically gets new value

**This is better than hardcoding** the connection string!

---

## ? Verification Checklist

After cleanup, verify:

- [ ] `ConnectionStrings__DefaultConnection` removed
- [ ] `DATABASE_URL` uses `${{Postgres.DATABASE_URL}}` format
- [ ] CORS variable uses `CorsSettings__AllowedOrigins__0` format
- [ ] All JWT variables present
- [ ] No duplicate or conflicting variables
- [ ] Total variables: 9-11 (not counting Railway auto-variables)

---

## ?? After Cleanup

1. **Railway will auto-redeploy** when you save variable changes
2. **Watch the logs** for successful connection:
   ```
   ? Using database connection: Host=postgres.railway.internal
   ? Applied migration '...'
   ```
3. **Test the API:**
   ```bash
   curl https://your-app.railway.app/api/sports
   ```

---

## ?? Pro Tips

### Tip 1: Variable Naming
- .NET config uses **double underscore** `__` for nested properties
- Arrays use index: `__0`, `__1`, `__2`
- Example: `CorsSettings__AllowedOrigins__0`

### Tip 2: Service References
- Use `${{ServiceName.VariableName}}` to reference other services
- Case-sensitive!
- Example: `${{Postgres.DATABASE_URL}}` not `${{postgres.database_url}}`

### Tip 3: Environment Variables
- All variables are environment variables at runtime
- `Environment.GetEnvironmentVariable("DATABASE_URL")` reads them
- No need to manually copy between services

### Tip 4: Secrets
- Sensitive values (passwords, keys) are automatically hidden in UI
- Use Railway's secret management
- Never commit secrets to git

---

## ?? Before vs After

### Before (Current - Needs Cleanup)
```
? ConnectionStrings__DefaultConnection = postgresql://...
? CORS__AllowedOrigins = ...
??  DATABASE_URL = postgresql://... (hardcoded)
? JwtSettings__SecretKey = ...
? ASPNETCORE_ENVIRONMENT = Production
...
```

### After (Cleaned Up)
```
? DATABASE_URL = ${{Postgres.DATABASE_URL}} (referenced)
? CorsSettings__AllowedOrigins__0 = https://...
? JwtSettings__SecretKey = ...
? JwtSettings__Issuer = PlayOhCanadaAPI
? JwtSettings__Audience = PlayOhCanadaAPI
? ASPNETCORE_ENVIRONMENT = Production
...
```

---

## ?? Time Required
- **5 minutes** to clean up variables
- **2 minutes** for Railway to redeploy
- **3 minutes** to verify
- **Total: ~10 minutes**

---

## ?? If Something Goes Wrong

### Issue: App won't start after cleanup

**Check logs for:**
```
? "Database connection not configured"
```

**Solution:**
```bash
# Add DATABASE_URL reference
DATABASE_URL=${{Postgres.DATABASE_URL}}
```

### Issue: CORS errors

**Check:**
```bash
# Verify format (double underscore + index)
CorsSettings__AllowedOrigins__0=https://your-frontend.com
```

### Issue: JWT errors

**Check:**
```bash
# Ensure all JWT settings exist
JwtSettings__SecretKey=[min 32 chars]
JwtSettings__Issuer=PlayOhCanadaAPI
JwtSettings__Audience=PlayOhCanadaAPI
```

---

## ?? Related Documentation
- Railway Variable References: https://docs.railway.app/deploy/variables
- .NET Configuration: https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/

---

**Ready to clean up?** Follow the steps above and your deployment will be production-ready! ??
