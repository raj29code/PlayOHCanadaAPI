# ?? Quick Start: Railway Migration (2 Minutes)

## TL;DR - What Changed
? **Automatic database migration now works in Production**  
? **No manual migration needed**  
? **Just deploy and it works!**

---

## ? Quick Deploy Steps

### 1. Set Environment Variables (Railway Dashboard)

#### Your API Service ? Variables Tab:

```bash
# Database Connection (use Railway's PostgreSQL service variables)
DATABASE_URL=${{Postgres.DATABASE_URL}}

# OR if DATABASE_URL doesn't work, these are auto-available:
PGHOST=${{Postgres.PGHOST}}
PGUSER=${{Postgres.PGUSER}}
PGPASSWORD=${{Postgres.PGPASSWORD}}
PGPORT=${{Postgres.PGPORT}}
PGDATABASE=${{Postgres.PGDATABASE}}

# JWT Settings (REQUIRED)
JwtSettings__SecretKey=your-32-char-minimum-secret-key-here!
ASPNETCORE_ENVIRONMENT=Production
JwtSettings__Issuer=PlayOhCanadaAPI
JwtSettings__Audience=PlayOhCanadaAPI
JwtSettings__ExpiryMinutes=60

# CORS (Update with your frontend URL)
CorsSettings__AllowedOrigins__0=https://your-frontend.com

# Schedule Cleanup (Optional)
ScheduleCleanup__RetentionDays=7
ScheduleCleanup__CleanupIntervalHours=24
```

?? **Important:** 
- Make sure PostgreSQL service is added to your Railway project first
- Use `${{Postgres.XXX}}` format to reference PostgreSQL variables
- **DO NOT** use format like `ConnectionStrings__DefaultConnection=postgresql://...`

### 2. Deploy
```bash
git add .
git commit -m "Enable production auto-migration"
git push origin main
```

### 3. Verify (2 minutes)
```bash
# Replace with your Railway URL
curl https://your-app.railway.app/api/sports

# Should return 6 sports:
# [{"id":1,"name":"Tennis",...}, ...]
```

---

## ? Done!

Your database is automatically:
- ? Migrated (all tables created)
- ? Seeded (admin user + 6 sports)
- ? Ready to use

---

## ?? Quick Test

### PowerShell Test Script
```powershell
.\test-railway-deployment.ps1 -RailwayUrl "https://your-app.railway.app"
```

### Manual Test
```bash
# 1. Check sports
curl https://your-app.railway.app/api/sports

# 2. Admin login
curl -X POST https://your-app.railway.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@playohcanada.com","password":"Admin@123"}'
```

---

## ?? Detailed Guides

- **Complete Guide:** `RAILWAY_DEPLOYMENT_GUIDE.md`
- **Checklist:** `RAILWAY_MIGRATION_CHECKLIST.md`
- **Summary:** `MIGRATION_COMPLETE_SUMMARY.md`

---

## ?? Problem?

### Issue: "No database connection"
```bash
# Add to Railway Variables:
ConnectionStrings__DefaultConnection=${{Postgres.DATABASE_PRIVATE_URL}}
```

### Issue: "JWT SecretKey missing"
```bash
# Add to Railway Variables (min 32 chars):
JwtSettings__SecretKey=YourSuperSecretKeyMinimum32Chars!
```

### Issue: "Sports API returns empty"
See `RAILWAY_DEPLOYMENT_GUIDE.md` ? Troubleshooting section

---

**Time:** 2 minutes to deploy, 2 minutes to verify  
**Difficulty:** Easy (automatic)  
**Next:** Step 1.6 - Testing & Verification
