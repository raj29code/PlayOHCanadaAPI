# Railway Deployment Guide - Play Oh Canada API

## ?? Step 1.5: Database Migration (15 minutes)

### Overview
This guide covers database migration setup for your Railway deployment. The API is configured for **automatic migrations on startup**, making deployment seamless.

---

## ?? Automatic Migration (Recommended - Already Configured!)

### ? What's Already Done
Your `Program.cs` has been updated to automatically:
1. Run database migrations on every startup
2. Create all necessary tables (Users, Sports, Schedules, Bookings, RevokedTokens)
3. Seed initial data (Admin user + 6 sports)

### How It Works
```csharp
// Runs automatically when your app starts on Railway
await dbContext.Database.MigrateAsync();
```

### Migration Process
1. **Railway deploys your app** ? 
2. **App starts** ? 
3. **Migrations run automatically** ? 
4. **Database is ready** ?

---

## ?? Railway Environment Variables Setup

### Required Variables (Set in Railway Dashboard)

**In your API Service ? Variables tab:**

```bash
# Database Connection (REFERENCE to Postgres service - Railway handles the rest)
DATABASE_URL=${{Postgres.DATABASE_URL}}

# JWT Configuration (REQUIRED - You must set these)
JwtSettings__SecretKey=your-super-secret-jwt-key-minimum-32-characters-long!
JwtSettings__Issuer=PlayOhCanadaAPI
JwtSettings__Audience=PlayOhCanadaAPI
JwtSettings__ExpiryMinutes=60

# Environment
ASPNETCORE_ENVIRONMENT=Production

# CORS (Add your frontend URLs)
CorsSettings__AllowedOrigins__0=https://your-frontend.railway.app
CorsSettings__AllowedOrigins__1=https://your-custom-domain.com

# Schedule Cleanup Service (Optional)
ScheduleCleanup__RetentionDays=7
ScheduleCleanup__CleanupIntervalHours=24
```

### ? Do You Need to Manually Add Database Variables?

**NO!** You do **NOT** need to manually add these to your API service:
- PGHOST
- PGUSER  
- PGPASSWORD
- PGPORT
- PGDATABASE

**Why?** Railway automatically makes Postgres service variables available to all services in your project. The code will use them as automatic fallback if `DATABASE_URL` fails.

### ? How Variable References Work

When you set `DATABASE_URL=${{Postgres.DATABASE_URL}}`:
1. Railway finds your Postgres service
2. Gets the `DATABASE_URL` value from it
3. Injects it into your API at runtime
4. If Postgres credentials change, API automatically gets updates

**This is the Railway-native way!** ?

---

## ?? Step-by-Step Migration Verification

### Step 1: Deploy to Railway
1. Push your code to GitHub
2. Railway automatically builds and deploys
3. App starts and runs migrations

### Step 2: Check Migration Status

#### Option A: Check Railway Logs
```bash
# In Railway Dashboard > Deployments > View Logs
# Look for:
? "Applying migration '20XXXXXX_InitialCreate'"
? "Applying migration '20XXXXXX_AddRevokedTokenTable'"
? "Applying migration '20XXXXXX_AddSportsSchedulingSystem'"
? "Done."
```

#### Option B: Test API Endpoints
```bash
# Get your Railway URL (e.g., https://playohcanadaapi.up.railway.app)
RAILWAY_URL="https://your-app.up.railway.app"

# 1. Test health endpoint
curl $RAILWAY_URL/scalar/v1

# 2. Test sports endpoint (should return seeded sports)
curl $RAILWAY_URL/api/sports

# Expected Response:
# [
#   {"id": 1, "name": "Tennis", "iconUrl": "..."},
#   {"id": 2, "name": "Badminton", "iconUrl": "..."},
#   ...
# ]

# 3. Test admin login (verify admin user was created)
curl -X POST $RAILWAY_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@playohcanada.com",
    "password": "Admin@123"
  }'

# Expected: JWT token returned
```

### Step 3: Verify Database Tables

#### Connect to Railway PostgreSQL
```bash
# Option 1: Using Railway CLI
railway connect

# Option 2: Using psql with Railway credentials
psql "postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE"
```

#### Check Tables
```sql
-- List all tables
\dt

-- Expected tables:
-- public | Bookings       | table | postgres
-- public | RevokedTokens  | table | postgres
-- public | Schedules      | table | postgres
-- public | Sports         | table | postgres
-- public | Users          | table | postgres
-- public | __EFMigrationsHistory | table | postgres

-- Check migration history
SELECT * FROM "__EFMigrationsHistory";

-- Verify seeded data
SELECT COUNT(*) FROM "Sports";  -- Should return 6
SELECT * FROM "Users" WHERE "Role" = 'Admin';  -- Should return 1
```

---

## ?? Manual Migration (If Needed)

### When to Use Manual Migration
- Automatic migration fails
- Need to run specific migration
- Troubleshooting migration issues

### Using Railway CLI

#### Install Railway CLI
```bash
# Windows (PowerShell)
iwr https://railway.app/install.ps1 | iex

# macOS/Linux
curl -fsSL https://railway.app/install.sh | sh
```

#### Run Migrations Manually
```bash
# 1. Login to Railway
railway login

# 2. Link to your project
railway link

# 3. Run migration command
railway run dotnet ef database update

# 4. Or connect and run manually
railway shell
dotnet ef database update
```

### Using Local Connection

#### Get Railway Database Credentials
```bash
# In Railway Dashboard > PostgreSQL > Variables
Host: your-postgres.railway.app
Port: 5432
Database: railway
Username: postgres
Password: [auto-generated]
```

#### Update appsettings.json Temporarily
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=your-postgres.railway.app;Port=5432;Database=railway;Username=postgres;Password=your-railway-password;SSL Mode=Require"
  }
}
```

#### Run Migration
```bash
dotnet ef database update
```

---

## ?? Verification Checklist

### ? Pre-Deployment
- [x] Migrations created locally (`dotnet ef migrations list`)
- [x] Program.cs updated for auto-migration
- [x] Dockerfile includes .NET 10 SDK
- [x] All environment variables documented

### ? During Deployment
- [ ] Railway build succeeds
- [ ] App starts without errors
- [ ] Migration logs appear in Railway console
- [ ] No database connection errors

### ? Post-Deployment
- [ ] Sports API returns 6 default sports
- [ ] Admin login works (admin@playohcanada.com / Admin@123)
- [ ] Database tables exist (check via Railway PostgreSQL)
- [ ] __EFMigrationsHistory shows all 3 migrations
- [ ] Can register new user
- [ ] Can create schedules (as admin)

---

## ?? Troubleshooting

### Issue: "Connection to database failed"

**Cause:** Connection string not configured

**Solution:**
```bash
# In Railway Dashboard > Variables
# Add: ConnectionStrings__DefaultConnection
ConnectionStrings__DefaultConnection=${{Postgres.DATABASE_PRIVATE_URL}}
```

### Issue: "Migration already applied"

**Cause:** Database already has tables

**Solution:** This is OK! Migrations are idempotent. If tables exist, migration is skipped.

### Issue: "JWT SecretKey not configured"

**Cause:** Missing JWT configuration

**Solution:**
```bash
# Add in Railway Variables:
JwtSettings__SecretKey=your-32-plus-character-secret-key-here!
```

### Issue: "Migration fails on startup"

**Cause:** Database permissions or connection issue

**Solution:**
1. Check Railway PostgreSQL is running
2. Verify DATABASE_URL is set
3. Check app logs for specific error
4. Try manual migration via Railway CLI

### Issue: "No sports returned from API"

**Cause:** Seeding failed or didn't run

**Solution:**
```bash
# Connect to Railway database
railway connect

# Manually seed sports
INSERT INTO "Sports" ("Name", "IconUrl") VALUES
('Tennis', 'https://cdn-icons-png.flaticon.com/512/889/889456.png'),
('Badminton', 'https://cdn-icons-png.flaticon.com/512/2913/2913133.png'),
('Basketball', 'https://cdn-icons-png.flaticon.com/512/889/889453.png'),
('Soccer', 'https://cdn-icons-png.flaticon.com/512/53/53283.png'),
('Volleyball', 'https://cdn-icons-png.flaticon.com/512/889/889502.png'),
('Pickleball', 'https://cdn-icons-png.flaticon.com/512/10529/10529471.png');
```

---

## ?? What Gets Created

### Database Tables

#### 1. Users
```sql
- Id (int, PK)
- Name (varchar)
- Email (varchar, unique)
- Phone (varchar, nullable)
- PasswordHash (varchar)
- Role (varchar) -- 'Admin' or 'User'
- CreatedAt (timestamp)
- LastLoginAt (timestamp, nullable)
- IsEmailVerified (boolean)
- IsPhoneVerified (boolean)
```

#### 2. RevokedTokens
```sql
- Id (int, PK)
- Token (varchar)
- UserId (int, FK -> Users)
- RevokedAt (timestamp)
- ExpiresAt (timestamp)
```

#### 3. Sports
```sql
- Id (int, PK)
- Name (varchar)
- IconUrl (varchar)
```

#### 4. Schedules
```sql
- Id (int, PK)
- SportId (int, FK -> Sports)
- Venue (varchar)
- StartTime (timestamp)
- EndTime (timestamp)
- MaxPlayers (int)
- EquipmentDetails (varchar, nullable)
- CreatedByAdminId (int, FK -> Users)
```

#### 5. Bookings
```sql
- Id (int, PK)
- ScheduleId (int, FK -> Schedules)
- UserId (int, FK -> Users)
- BookingTime (timestamp)
- GuestName (varchar, nullable)
```

### Seeded Data

#### Admin User
```
Email: admin@playohcanada.com
Password: Admin@123
Role: Admin
```

#### Sports (6 default)
1. Tennis
2. Badminton
3. Basketball
4. Soccer
5. Volleyball
6. Pickleball

---

## ?? Next Steps After Migration

### 1. Test All Endpoints
```bash
# Use the included test scripts
./test-api.ps1
./test-sports-api.ps1
./test-recurring-schedules.ps1
```

### 2. Update Documentation
- Document production API URL
- Update CORS origins
- Share admin credentials (securely)

### 3. Monitor Performance
- Check Railway dashboard for resource usage
- Review application logs
- Monitor database size

### 4. Set Up Alerts
- Configure Railway notifications
- Set up uptime monitoring (e.g., UptimeRobot)
- Enable error tracking (e.g., Sentry)

---

## ?? Related Documentation

- `progress.md` - Full deployment checklist
- `README.md` - API documentation
- `SPORTS_SCHEDULING_IMPLEMENTATION.md` - Feature details
- `RECURRING_SCHEDULE_GUIDE.md` - Schedule patterns
- `Dockerfile` - Railway deployment configuration

---

## ?? Pro Tips

1. **Always check logs first** - Railway logs show migration progress in real-time
2. **Migrations are automatic** - No manual intervention needed after first deploy
3. **Seeding is idempotent** - Safe to restart app, won't create duplicates
4. **Use Railway CLI** - Makes debugging database issues much easier
5. **Test locally first** - Ensure migrations work locally before deploying

---

## ? Success Indicators

Your migration is successful when:
- ? Railway app deploys without errors
- ? Application logs show "Applied migration" messages
- ? GET /api/sports returns 6 sports
- ? POST /api/auth/login with admin credentials works
- ? Database has all 5 tables + migration history
- ? No connection errors in logs

---

**Time Required:** 15 minutes  
**Difficulty:** Easy (Automatic)  
**Prerequisites:** Railway PostgreSQL service added  
**Next Step:** Testing & Verification (Step 1.6)
