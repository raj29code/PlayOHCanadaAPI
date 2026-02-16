# ? Step 1.5: Database Migration Checklist (15 minutes)

## ?? Objective
Ensure database migrations run successfully on Railway PostgreSQL and all tables are created with seeded data.

---

## ?? Pre-Migration Checklist

### ? Code Changes Complete
- [x] **Program.cs updated** - Auto-migration enabled for production
- [x] **Migrations exist** - Run `dotnet ef migrations list` to verify
- [x] **Dockerfile ready** - Includes .NET 10 SDK and runtime

### ? Railway Setup Complete
- [ ] **PostgreSQL service added** to Railway project
- [ ] **DATABASE_URL variable** is available (auto-set by Railway)
- [ ] **App deployed** and running on Railway

---

## ?? Migration Steps

### Step 1: Verify Railway PostgreSQL Service (2 min)
1. Go to Railway Dashboard
2. Open your project
3. Confirm **PostgreSQL** service is present
4. Click on PostgreSQL ? **Variables** tab
5. Copy the following for reference:
   - `PGHOST`
   - `PGPORT`
   - `PGDATABASE`
   - `PGUSER`
   - `PGPASSWORD`

**Status:** [ ] ? Completed

---

### Step 2: Check Environment Variables (3 min)
In Railway Dashboard ? Your API Service ? **Variables** tab:

```bash
# Required Variables
? DATABASE_URL=${{Postgres.DATABASE_URL}}
? JwtSettings__SecretKey=[your-32-char-secret]
? ASPNETCORE_ENVIRONMENT=Production
? CorsSettings__AllowedOrigins__0=[your-frontend-url]
```

**Status:** [ ] ? Completed

---

### Step 3: Deploy & Monitor Logs (5 min)

#### Deploy the App
```bash
# If not auto-deployed, push to GitHub
git add .
git commit -m "Enable production auto-migration"
git push origin main
```

#### Watch Railway Logs
1. Go to Railway Dashboard ? Your API Service
2. Click **Deployments** ? Latest deployment ? **View Logs**
3. Look for migration messages:

```log
? Expected Log Output:
info: Microsoft.EntityFrameworkCore.Migrations[20402]
      Applying migration '20240XXX_InitialCreate'.
info: Microsoft.EntityFrameworkCore.Migrations[20402]
      Applying migration '20240XXX_AddRevokedTokenTable'.
info: Microsoft.EntityFrameworkCore.Migrations[20402]
      Applying migration '20240XXX_AddSportsSchedulingSystem'.
info: Microsoft.EntityFrameworkCore.Migrations[20405]
      Applied migration '20240XXX_InitialCreate'.
info: Microsoft.EntityFrameworkCore.Migrations[20405]
      Applied migration '20240XXX_AddRevokedTokenTable'.
info: Microsoft.EntityFrameworkCore.Migrations[20405]
      Applied migration '20240XXX_AddSportsSchedulingSystem'.
```

**Status:** [ ] ? Completed

---

### Step 4: Verify Migration Success (3 min)

#### Test 1: Check Sports API
```bash
# Replace with your Railway URL
curl https://your-app.up.railway.app/api/sports
```

**Expected Response:**
```json
[
  {"id": 1, "name": "Tennis", "iconUrl": "..."},
  {"id": 2, "name": "Badminton", "iconUrl": "..."},
  {"id": 3, "name": "Basketball", "iconUrl": "..."},
  {"id": 4, "name": "Soccer", "iconUrl": "..."},
  {"id": 5, "name": "Volleyball", "iconUrl": "..."},
  {"id": 6, "name": "Pickleball", "iconUrl": "..."}
]
```

**Status:** [ ] ? Completed

---

#### Test 2: Admin Login
```bash
curl -X POST https://your-app.up.railway.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@playohcanada.com",
    "password": "Admin@123"
  }'
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "Admin User",
    "email": "admin@playohcanada.com",
    "role": "Admin"
  }
}
```

**Status:** [ ] ? Completed

---

#### Test 3: Use Test Script (Automated)
```powershell
# Run comprehensive test
.\test-railway-deployment.ps1 -RailwayUrl "https://your-app.up.railway.app"
```

**Status:** [ ] ? Completed

---

### Step 5: Verify Database Tables (2 min)

#### Option A: Using Railway CLI
```bash
# Install Railway CLI (if not installed)
# Windows: iwr https://railway.app/install.ps1 | iex
# Mac/Linux: curl -fsSL https://railway.app/install.sh | sh

# Connect to database
railway login
railway link
railway connect Postgres

# Check tables
\dt

# Expected tables:
# - Users
# - RevokedTokens
# - Sports
# - Schedules
# - Bookings
# - __EFMigrationsHistory
```

#### Option B: Using pgAdmin or psql
```bash
# Use credentials from Railway PostgreSQL Variables
psql "postgresql://PGUSER:PGPASSWORD@PGHOST:PGPORT/PGDATABASE"

# List tables
\dt

# Check migration history
SELECT * FROM "__EFMigrationsHistory";

# Count seeded data
SELECT COUNT(*) FROM "Sports";  -- Should be 6
SELECT COUNT(*) FROM "Users";   -- Should be 1 (admin)
```

**Status:** [ ] ? Completed

---

## ?? Success Criteria

### ? All Must Pass
- [ ] App deployed without errors
- [ ] Migration logs show "Applied migration" messages
- [ ] GET /api/sports returns 6 sports
- [ ] Admin login returns JWT token
- [ ] Database has 5 tables + migration history
- [ ] No database connection errors in logs
- [ ] Scalar UI accessible at /scalar/v1

---

## ?? Troubleshooting

### Issue: "No database connection"
```bash
# Check Railway Variables
? Verify DATABASE_URL is set
? Verify PostgreSQL service is running
? Check app logs for connection string format

# Solution:
# Add explicit connection string in Railway Variables:
ConnectionStrings__DefaultConnection=Host=${{Postgres.PGHOST}};Port=${{Postgres.PGPORT}};Database=${{Postgres.PGDATABASE}};Username=${{Postgres.PGUSER}};Password=${{Postgres.PGPASSWORD}};SSL Mode=Require
```

### Issue: "Migrations already applied"
```bash
# This is OK! It means database is already up-to-date
# Check logs for: "No migrations were applied. The database is already up to date."
```

### Issue: "Sports API returns empty array"
```bash
# Seeding may have failed
# Connect to database and manually seed:
INSERT INTO "Sports" ("Name", "IconUrl") VALUES
('Tennis', 'https://cdn-icons-png.flaticon.com/512/889/889456.png'),
('Badminton', 'https://cdn-icons-png.flaticon.com/512/2913/2913133.png'),
('Basketball', 'https://cdn-icons-png.flaticon.com/512/889/889453.png'),
('Soccer', 'https://cdn-icons-png.flaticon.com/512/53/53283.png'),
('Volleyball', 'https://cdn-icons-png.flaticon.com/512/889/889502.png'),
('Pickleball', 'https://cdn-icons-png.flaticon.com/512/10529/10529471.png');
```

### Issue: "Admin login fails"
```bash
# Admin user may not have been created
# Connect to database and manually create:
INSERT INTO "Users" ("Name", "Email", "Phone", "PasswordHash", "Role", "CreatedAt", "IsEmailVerified", "IsPhoneVerified")
VALUES (
  'Admin User',
  'admin@playohcanada.com',
  NULL,
  '$2a$11$YourBcryptHashHere',  -- Hash of "Admin@123"
  'Admin',
  NOW(),
  true,
  false
);
```

---

## ?? What Gets Created

### Database Schema
```
Users
??? Id (PK)
??? Name
??? Email (Unique)
??? PasswordHash
??? Role (Admin/User)

RevokedTokens
??? Id (PK)
??? Token
??? UserId (FK ? Users)
??? ExpiresAt

Sports
??? Id (PK)
??? Name
??? IconUrl

Schedules
??? Id (PK)
??? SportId (FK ? Sports)
??? Venue
??? StartTime
??? EndTime
??? MaxPlayers
??? CreatedByAdminId (FK ? Users)

Bookings
??? Id (PK)
??? ScheduleId (FK ? Schedules)
??? UserId (FK ? Users)
??? BookingTime
```

### Seeded Data
- **1 Admin User**: admin@playohcanada.com / Admin@123
- **6 Sports**: Tennis, Badminton, Basketball, Soccer, Volleyball, Pickleball

---

## ?? Time Breakdown
- **Step 1**: Verify PostgreSQL (2 min)
- **Step 2**: Check variables (3 min)
- **Step 3**: Deploy & monitor (5 min)
- **Step 4**: Verify migration (3 min)
- **Step 5**: Check database (2 min)
- **Total**: ~15 minutes

---

## ? Completion Sign-Off

**Migration Completed By:** ________________  
**Date:** ________________  
**Time Taken:** _______ minutes  

**Notes:**
_______________________________________________
_______________________________________________
_______________________________________________

---

## ?? Related Documents
- `RAILWAY_DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `progress.md` - Overall deployment progress
- `test-railway-deployment.ps1` - Automated test script

---

## ?? Next Step
**Step 1.6**: Testing & Verification (30 minutes)
- Run comprehensive API tests
- Verify all endpoints
- Test authentication flow
- Create test schedules and bookings

**Status:** [ ] Ready to start
