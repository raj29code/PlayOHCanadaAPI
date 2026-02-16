# ? Railway Variables Quick Checklist

## ?? Question: Do I need to add PG variables to API service?

### Answer: **NO!** ?

Railway automatically makes Postgres service variables available to your API service. Your code will use them automatically.

---

## ?? What You NEED to Do (5 minutes)

### In Railway Dashboard ? PlayOHCanadaAPI Service ? Variables:

#### Step 1: DELETE These
- [ ] ? `ConnectionStrings__DefaultConnection`

#### Step 2: CHANGE This
- [ ] Change `DATABASE_URL` from hardcoded string to:
  ```
  DATABASE_URL=${{Postgres.DATABASE_URL}}
  ```

#### Step 3: FIX CORS (if using single underscore)
- [ ] Change `CORS__AllowedOrigins` to:
  ```
  CorsSettings__AllowedOrigins__0=https://your-frontend.com
  ```

---

## ? Final Variable List (Your API Service Should Have)

```bash
ASPNETCORE_ENVIRONMENT=Production
DATABASE_URL=${{Postgres.DATABASE_URL}}
JwtSettings__SecretKey=[your-32-char-secret-key]
JwtSettings__Issuer=PlayOhCanadaAPI
JwtSettings__Audience=PlayOhCanadaAPI
JwtSettings__ExpiryMinutes=60
CorsSettings__AllowedOrigins__0=https://your-frontend.com
ScheduleCleanup__CleanupIntervalHours=24
ScheduleCleanup__RetentionDays=7
```

**Total: 9 variables** (not counting Railway auto-variables like PORT)

---

## ?? What You DON'T Need

You do **NOT** need to manually add these to API service:
- ? PGHOST
- ? PGUSER
- ? PGPASSWORD
- ? PGPORT
- ? PGDATABASE

**Why?** Railway makes these available automatically, and your code uses them as fallback.

---

## ?? How It Works

```
Your API tries:
1. DATABASE_URL (if you reference ${{Postgres.DATABASE_URL}})
   ? if that fails
2. Automatically uses PGHOST, PGUSER, PGPASSWORD
   (Railway makes these available from Postgres service)
```

---

## ? After Cleanup

- [ ] Save variables
- [ ] Wait for Railway auto-redeploy (~2 min)
- [ ] Check logs: Should see "Using database connection: Host=postgres.railway.internal"
- [ ] Test: `curl https://your-app.railway.app/api/sports`
- [ ] Should return 6 sports ?

---

**Time: 5 minutes | Difficulty: Easy**
