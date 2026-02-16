# ? Railway Database Connection Checklist

## ?? Problem
Database connection failing because credentials are missing from connection string.

## ? Solution Applied
Updated `Program.cs` to use Railway's PostgreSQL environment variables with automatic fallback.

---

## ?? Action Items (Complete These Now)

### Step 1: Verify PostgreSQL Service (2 min)
- [ ] Go to Railway Dashboard
- [ ] Confirm PostgreSQL service exists in your project
- [ ] Click on PostgreSQL service
- [ ] Go to "Variables" tab
- [ ] Verify these variables exist:
  - [ ] `PGHOST`
  - [ ] `PGPORT`
  - [ ] `PGDATABASE`
  - [ ] `PGUSER`
  - [ ] `PGPASSWORD`
  - [ ] `DATABASE_URL`

---

### Step 2: Configure API Service Variables (3 min)

#### Go to: Railway Dashboard ? Your API Service ? Variables Tab

#### **REMOVE** These (Wrong Format):
- [ ] Delete: `ConnectionStrings__DefaultConnection` (if exists)

#### **ADD/UPDATE** These:

**Database Connection:**
```bash
? DATABASE_URL=${{Postgres.DATABASE_URL}}
```

**JWT Settings (REQUIRED):**
```bash
? JwtSettings__SecretKey=[Generate a 32+ character secret key]
? JwtSettings__Issuer=PlayOhCanadaAPI
? JwtSettings__Audience=PlayOhCanadaAPI
? JwtSettings__ExpiryMinutes=60
```

**Environment:**
```bash
? ASPNETCORE_ENVIRONMENT=Production
```

**CORS (Update with your actual frontend URL):**
```bash
? CorsSettings__AllowedOrigins__0=https://your-frontend-url.com
```

**Optional - Schedule Cleanup:**
```bash
? ScheduleCleanup__RetentionDays=7
? ScheduleCleanup__CleanupIntervalHours=24
```

---

### Step 3: Deploy Updated Code (2 min)
```bash
# Commit and push changes
git add Program.cs RAILWAY_DATABASE_FIX.md
git commit -m "fix: robust Railway database connection with fallback"
git push origin feature/sports-api
```

- [ ] Code pushed to GitHub
- [ ] Railway auto-deployment triggered

---

### Step 4: Monitor Deployment (5 min)

#### Watch Railway Logs:
Railway Dashboard ? Your API Service ? Deployments ? Latest ? View Logs

#### ? Look for SUCCESS indicators:
```log
? Using database connection: Host=postgres.railway.internal
? Applying migration '20240316_InitialCreate'
? Applied migration '20240316_InitialCreate'
? Applying migration '20240316_AddRevokedTokenTable'
? Applied migration '20240316_AddRevokedTokenTable'
? Applying migration '20240316_AddSportsSchedulingSystem'
? Applied migration '20240316_AddSportsSchedulingSystem'
```

#### ? If you see ERRORS:
```log
? "DATABASE_URL is missing username or password"
   ? Code will auto-fallback to PGHOST, PGUSER, PGPASSWORD

? "Database connection not configured"
   ? Check that DATABASE_URL or PG variables exist

? "JWT SecretKey is not configured"
   ? Add JwtSettings__SecretKey variable
```

---

### Step 5: Test API (3 min)

#### Test 1: Sports API
```bash
curl https://your-app.railway.app/api/sports
```

**Expected:** Returns 6 sports
```json
[
  {"id": 1, "name": "Tennis", ...},
  {"id": 2, "name": "Badminton", ...},
  ...
]
```

- [ ] Sports API works

#### Test 2: Admin Login
```bash
curl -X POST https://your-app.railway.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@playohcanada.com",
    "password": "Admin@123"
  }'
```

**Expected:** Returns JWT token
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {...}
}
```

- [ ] Admin login works

#### Test 3: Automated Test (Recommended)
```powershell
.\test-railway-deployment.ps1 -RailwayUrl "https://your-app.railway.app"
```

- [ ] Automated test passes

---

### Step 6: Verify Database Tables (2 min)

#### Using Railway CLI:
```bash
# Install Railway CLI (if not installed)
# Windows: iwr https://railway.app/install.ps1 | iex

railway login
railway link
railway connect Postgres

# Check tables
\dt

# Expected:
# Users
# RevokedTokens
# Sports
# Schedules
# Bookings
# __EFMigrationsHistory
```

- [ ] All tables created
- [ ] Migration history exists

---

## ?? Success Criteria (All Must Pass)

- [ ] ? Railway build succeeds
- [ ] ? App starts without database errors
- [ ] ? Logs show "Using database connection: Host=postgres.railway.internal"
- [ ] ? Logs show "Applied migration" (x3)
- [ ] ? GET /api/sports returns 6 sports
- [ ] ? POST /api/auth/login returns JWT token
- [ ] ? Database has 5 tables + migration history
- [ ] ? No connection errors in logs

---

## ?? Common Issues & Quick Fixes

### Issue 1: "DATABASE_URL is missing username or password"
**Status:** ? HANDLED - Code auto-falls back to PGHOST, PGUSER, PGPASSWORD

### Issue 2: "Database connection not configured"
**Fix:**
1. Verify PostgreSQL service exists in Railway
2. Add `DATABASE_URL=${{Postgres.DATABASE_URL}}` to API variables
3. Or ensure PGHOST, PGUSER, PGPASSWORD variables exist

### Issue 3: "JWT SecretKey is not configured"
**Fix:**
1. Generate a secret key (min 32 chars)
2. Add to Railway: `JwtSettings__SecretKey=YourSecretKey123456789012345678901234`

### Issue 4: Connection timeout
**Fix:**
1. Use `postgres.railway.internal` for HOST (internal networking)
2. Ensure SSL Mode=Require is in connection string (? already in code)

---

## ?? Railway Variables Summary

### What You NEED to Set:
```bash
DATABASE_URL=${{Postgres.DATABASE_URL}}
JwtSettings__SecretKey=[32+ chars]
ASPNETCORE_ENVIRONMENT=Production
CorsSettings__AllowedOrigins__0=[your-frontend]
```

### What Railway AUTO-PROVIDES:
```bash
PGHOST (auto from Postgres service)
PGPORT (auto from Postgres service)
PGDATABASE (auto from Postgres service)
PGUSER (auto from Postgres service)
PGPASSWORD (auto from Postgres service)
DATABASE_URL (auto from Postgres service)
```

---

## ?? Estimated Time
- Step 1: Verify PostgreSQL - **2 min**
- Step 2: Configure variables - **3 min**
- Step 3: Deploy code - **2 min**
- Step 4: Monitor logs - **5 min**
- Step 5: Test API - **3 min**
- Step 6: Verify database - **2 min**
- **Total: ~17 minutes**

---

## ?? Completion

**Date:** _______________  
**Time Taken:** _______ minutes  

**Status:**
- [ ] Database connection working
- [ ] Migrations applied successfully
- [ ] API endpoints responding
- [ ] Ready for Step 1.6 (Testing & Verification)

---

## ?? Related Documents
- `RAILWAY_DATABASE_FIX.md` - Detailed fix explanation
- `RAILWAY_DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `QUICK_START_RAILWAY.md` - Quick reference
- `test-railway-deployment.ps1` - Automated test script

---

**Next Step:** Proceed to **Step 1.6: Testing & Verification** ?
