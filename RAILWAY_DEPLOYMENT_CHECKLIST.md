# Railway Deployment Checklist

## ? Pre-Deployment (Completed)
- [x] Phase 1 features complete
- [x] Local testing passed
- [x] Documentation complete
- [x] Railway account created
- [x] PostgreSQL service added
- [x] Environment variables configured

---

## ?? Configuration Fix (Current Step)

### **Railway Build Configuration**
- [ ] Run verification: `.\verify-railway-config.ps1`
  - Expected: All critical checks pass ?
  
- [ ] Review files created:
  - [ ] `Dockerfile` exists
  - [ ] `nixpacks.toml` exists (optional)
  - [ ] `railway.json` exists (optional)
  - [ ] `.dockerignore` exists
  - [ ] Documentation files created

---

## ?? Deployment Steps

### **Step 1: Commit Configuration Files**
- [ ] Review changes: `git status`
- [ ] Option A: Run automated script
  ```powershell
  .\railway-fix-deploy.ps1
  ```
- [ ] Option B: Manual commit
  ```bash
  git add Dockerfile nixpacks.toml railway.json .dockerignore
  git add RAILWAY_*.md railway-*.ps1 verify-*.ps1
  git commit -m "Add Railway deployment configuration for .NET 10"
  git push origin feature/sports-api
  ```

---

### **Step 2: Monitor Railway Build**
- [ ] Open Railway Dashboard: https://railway.app/dashboard
- [ ] Navigate to PlayOHCanadaAPI project
- [ ] Click **Deployments** tab
- [ ] Watch build logs

**Expected Timeline:**
- Build start: Immediate
- Build duration: 5-10 minutes (first build)
- Deployment: 1-2 minutes
- Total: ~10-15 minutes

**Success Indicators:**
- [ ] ? "Building with Dockerfile" appears
- [ ] ? "[1/2] Build stage completed"
- [ ] ? "[2/2] Runtime stage completed"
- [ ] ? "Image built successfully"
- [ ] ? "Deployment successful"

---

### **Step 3: Verify Environment Variables**

Before proceeding, ensure these are set in Railway:

**Required Variables:**
- [ ] `ASPNETCORE_ENVIRONMENT` = `Production`
- [ ] `ConnectionStrings__DefaultConnection` = `${{Postgres.DATABASE_URL}}`
- [ ] `JwtSettings__SecretKey` = (64-char secret key)
- [ ] `JwtSettings__Issuer` = `PlayOhCanadaAPI`
- [ ] `JwtSettings__Audience` = `PlayOhCanadaAPI`
- [ ] `JwtSettings__ExpiryMinutes` = `60`
- [ ] `CorsSettings__AllowedOrigins__0` = (your frontend URL)
- [ ] `ScheduleCleanup__RetentionDays` = `7`
- [ ] `ScheduleCleanup__CleanupIntervalHours` = `24`

**If missing, add them now:**
- Railway Dashboard ? Variables tab ? Add each variable

---

### **Step 4: Check Application Logs**
- [ ] Railway Dashboard ? Click your service
- [ ] Click **Logs** tab
- [ ] Look for successful startup:
  ```
  info: Microsoft.Hosting.Lifetime[0]
        Now listening on: http://0.0.0.0:8080
  info: Microsoft.Hosting.Lifetime[0]
        Application started
  ```

**Common Issues:**
- [ ] If "JWT SecretKey is not configured" ? Check environment variables
- [ ] If "Connection refused" ? Check DATABASE_URL variable
- [ ] If "Port already in use" ? Railway will auto-retry

---

### **Step 5: Get Application URL**
- [ ] Railway Dashboard ? Settings ? Domains
- [ ] Copy the Railway-provided URL:
  ```
  https://playohcanadaapi-production.up.railway.app
  ```
- [ ] Save this URL for testing

---

### **Step 6: Quick Smoke Test**

Test basic connectivity:

```powershell
# Set your Railway URL
$baseUrl = "https://your-app.up.railway.app"

# Test 1: Health check (sports endpoint)
try {
    $sports = Invoke-RestMethod -Uri "$baseUrl/api/sports" -Method Get
    Write-Host "? API is accessible" -ForegroundColor Green
    Write-Host "   Sports count: $($sports.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "? API not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Scalar UI
Start-Process "$baseUrl/scalar/v1"
Write-Host "? Opened Scalar UI in browser" -ForegroundColor Green
```

**Expected Results:**
- [ ] API returns JSON (sports list)
- [ ] Scalar UI loads in browser
- [ ] No 404 or 500 errors

---

## ??? Database Migration (Next Step)

### **Install Railway CLI**
- [ ] Install: `npm i -g @railway/cli`
- [ ] Login: `railway login`
- [ ] Link project: `railway link`

### **Run Migrations**
- [ ] Navigate to project root
- [ ] Run migration:
  ```powershell
  railway run dotnet ef database update --project PlayOhCanadaAPI
  ```

**Expected Output:**
```
Applying migration '20240101_InitialCreate'...
Applying migration '20240102_AddRevokedTokenTable'...
Applying migration '20240103_AddSportsSchedulingSystem'...
Done.
```

**Verify Migration:**
- [ ] Check Railway PostgreSQL logs
- [ ] No errors in migration output
- [ ] Tables created successfully

---

## ?? Full Testing

### **Test 1: User Registration**
```powershell
$registerBody = @{
    name = "Test User"
    email = "test@example.com"
    phone = "+1234567890"
    password = "TestPass123!"
    confirmPassword = "TestPass123!"
} | ConvertTo-Json

$registerResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" `
    -Method Post -Body $registerBody -ContentType "application/json"

Write-Host "? Registration successful" -ForegroundColor Green
```

- [ ] Registration succeeds
- [ ] Returns user data and token
- [ ] No errors in logs

---

### **Test 2: User Login**
```powershell
$loginBody = @{
    email = "test@example.com"
    password = "TestPass123!"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"

$token = $loginResponse.token
Write-Host "? Login successful" -ForegroundColor Green
Write-Host "   Token: $($token.Substring(0, 20))..." -ForegroundColor Cyan
```

- [ ] Login succeeds
- [ ] Returns JWT token
- [ ] Token is valid (starts with "eyJ")

---

### **Test 3: Protected Endpoint**
```powershell
$headers = @{
    Authorization = "Bearer $token"
}

$profile = Invoke-RestMethod -Uri "$baseUrl/api/auth/me" `
    -Method Get -Headers $headers

Write-Host "? Protected endpoint accessible" -ForegroundColor Green
Write-Host "   User: $($profile.name)" -ForegroundColor Cyan
```

- [ ] Profile endpoint works
- [ ] Returns user data
- [ ] JWT authentication working

---

### **Test 4: Sports List**
```powershell
$sports = Invoke-RestMethod -Uri "$baseUrl/api/sports" -Method Get

Write-Host "? Sports endpoint working" -ForegroundColor Green
Write-Host "   Default sports loaded: $($sports.Count)" -ForegroundColor Cyan

foreach ($sport in $sports) {
    Write-Host "   - $($sport.name)" -ForegroundColor Gray
}
```

- [ ] Sports endpoint returns data
- [ ] Default sports seeded (Tennis, Badminton, etc.)
- [ ] Count matches expected (6 default sports)

---

## ?? Post-Deployment Verification

### **Application Health**
- [ ] No errors in Railway logs
- [ ] Application responds to requests
- [ ] Database queries working
- [ ] Authentication flow complete

### **Performance**
- [ ] API response time < 500ms
- [ ] Database connection stable
- [ ] Memory usage normal (Railway metrics)
- [ ] No memory leaks detected

### **Security**
- [ ] HTTPS enabled (Railway provides SSL)
- [ ] CORS configured correctly
- [ ] JWT authentication working
- [ ] Environment variables secure (not exposed)

---

## ?? Documentation Updates

- [ ] Update README.md with production URL:
  ```markdown
  ## Production Deployment
  **Live API:** https://your-app.up.railway.app
  **API Docs:** https://your-app.up.railway.app/scalar/v1
  ```

- [ ] Create DEPLOYMENT_NOTES.md with:
  - Deployment date
  - Railway URL
  - Environment configuration
  - Known issues (if any)

---

## ?? Success Criteria

### **Must Have (Before Proceeding)**
- [ ] ? Railway build successful
- [ ] ? Application deployed and running
- [ ] ? Database migrations applied
- [ ] ? Authentication working
- [ ] ? All API endpoints accessible
- [ ] ? No critical errors in logs

### **Should Have**
- [ ] ? Scalar UI accessible
- [ ] ? Default sports seeded
- [ ] ? Response times acceptable
- [ ] ? Documentation updated

---

## ?? Rollback Plan (If Needed)

If deployment fails:

1. **Railway Rollback:**
   - [ ] Railway Dashboard ? Deployments
   - [ ] Click previous successful deployment
   - [ ] Click "Redeploy"

2. **Fix Locally:**
   - [ ] Review error logs
   - [ ] Fix issues in local environment
   - [ ] Test locally before redeploying

3. **Redeploy:**
   - [ ] Commit fixes
   - [ ] Push to GitHub
   - [ ] Railway auto-redeploys

---

## ?? Day 2: CI/CD Setup (After Successful Deployment)

- [ ] Create GitHub Actions workflow
- [ ] Configure automatic deployments
- [ ] Set up monitoring
- [ ] Configure alerts
- [ ] Add custom domain (optional)

**See:** `PROGRESS.md` ? Phase 2 ? Day 2

---

## ?? Completion

When all checkboxes are marked:

? **Phase 2 Step 1-4 Complete**  
? **Application deployed to production**  
? **Database operational**  
? **API fully functional**  
? **Ready for CI/CD setup**  

---

## ?? Support

**If stuck on any step:**

1. Check error logs in Railway Dashboard
2. Review `RAILWAY_BUILD_FIX.md` for troubleshooting
3. Run `.\verify-railway-config.ps1` to diagnose
4. Check Railway Discord: https://discord.gg/railway
5. Review GitHub issues: https://github.com/raj29code/PlayOHCanadaAPI/issues

---

**Last Updated:** Railway Deployment Configuration  
**Current Phase:** Phase 2 - Deployment  
**Next:** CI/CD Pipeline Setup
