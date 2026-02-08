# ?? Railway Deployment - Quick Start

## ? **Problem You Encountered**

```
? Script start.sh not found
? Railpack could not determine how to build the app.
```

Railway couldn't automatically detect how to build your .NET 10 application.

---

## ? **Solution Implemented**

Created Railway configuration files so Railway knows how to build and deploy your .NET 10 API.

---

## ?? **Files Created (4 files)**

| File | Purpose | Required |
|------|---------|----------|
| `Dockerfile` | Docker build instructions (most reliable) | ? Yes |
| `nixpacks.toml` | Nixpacks configuration (Railway's native) | ?? Optional |
| `railway.json` | Railway project settings | ?? Optional |
| `.dockerignore` | Optimize Docker builds | ? Recommended |

**Railway will automatically use `Dockerfile` first** (most reliable for .NET 10).

---

## ?? **Quick Deploy (3 Steps)**

### **Step 1: Commit & Push**

```powershell
# Run the automated script
.\railway-fix-deploy.ps1
```

**OR manually:**
```bash
git add Dockerfile nixpacks.toml railway.json .dockerignore RAILWAY_BUILD_FIX.md
git commit -m "Add Railway deployment configuration for .NET 10"
git push origin feature/sports-api
```

---

### **Step 2: Monitor Railway Build**

1. Go to: https://railway.app/dashboard
2. Click on your **PlayOHCanadaAPI** project
3. Click on **Deployments** tab
4. Watch the build logs

**Expected output:**
```
? Building with Dockerfile
? [1/2] Build stage completed (restore + publish)
? [2/2] Runtime stage completed
? Image built successfully
? Deploying...
? Deployment successful
```

**Build time:** 5-10 minutes (first time), 2-3 minutes (subsequent)

---

### **Step 3: Verify Deployment**

Once build completes, Railway will give you a URL like:
```
https://playohcanadaapi-production.up.railway.app
```

**Test it:**
```powershell
# Replace with your Railway URL
$baseUrl = "https://your-app.up.railway.app"

# Test API
Invoke-RestMethod -Uri "$baseUrl/api/sports" -Method Get

# Open Scalar UI
Start-Process "$baseUrl/scalar/v1"
```

---

## ?? **If Build Still Fails**

### **Option 1: Force Docker Build**

Railway Dashboard ? Project ? Settings ? Build:
- **Builder**: Select `DOCKERFILE`
- **Dockerfile Path**: `Dockerfile`
- Click **Save**
- Go to **Deployments** ? Click **Redeploy**

---

### **Option 2: Check Dockerfile Path**

Ensure your project structure is:
```
PlayOHCanadaAPI/               ? Root (where you cloned)
??? Dockerfile                  ? Must be here
??? nixpacks.toml               ? Must be here
??? railway.json                ? Must be here
??? PlayOhCanadaAPI/            ? Project folder
    ??? PlayOhCanadaAPI.csproj
    ??? Program.cs
    ??? Controllers/
```

---

### **Option 3: Check Build Logs**

Railway Dashboard ? Deployments ? Click failed deployment ? View logs

**Common errors:**

1. **"Project file not found"**
   - **Fix:** Check path in Dockerfile: `COPY PlayOhCanadaAPI/PlayOhCanadaAPI.csproj`

2. **"Port binding failed"**
   - **Fix:** Already handled in Dockerfile: `ENV ASPNETCORE_URLS=http://+:8080`

3. **".NET 10 SDK not found"**
   - **Fix:** Dockerfile uses official Microsoft images with .NET 10

---

## ? **Success Indicators**

You'll know it's working when you see:

**In Railway Logs:**
```
info: Microsoft.Hosting.Lifetime[0]
      Now listening on: http://0.0.0.0:8080
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

**In Browser:**
- Visit `https://your-app.up.railway.app/api/sports`
- Should return JSON array of sports
- Visit `https://your-app.up.railway.app/scalar/v1`
- Should show Scalar API documentation UI

---

## ?? **Post-Deployment Checklist**

After successful build:

- [ ] API URL accessible (returns JSON, not 404)
- [ ] Environment variables configured (from previous step)
- [ ] Database migration completed (next step)
- [ ] Test endpoints work
- [ ] Scalar UI loads

---

## ?? **Next Steps**

Continue with Phase 2 deployment:

### **Step 5: Database Migration** (NEXT)
```powershell
# Install Railway CLI
npm i -g @railway/cli

# Login and link project
railway login
railway link

# Run migrations
railway run dotnet ef database update --project PlayOhCanadaAPI
```

### **Step 6: Testing** (After migration)
- Register test user
- Login and get token
- Test all endpoints
- Verify data persistence

### **Day 2: CI/CD Setup**
- GitHub Actions workflow
- Automated deployments
- Monitoring setup

**See:** `PROGRESS.md` ? Phase 2 for complete steps

---

## ?? **Documentation**

- **`RAILWAY_BUILD_FIX.md`** - Detailed fix documentation
- **`PROGRESS.md`** - Complete Phase 2 deployment guide
- **`Dockerfile`** - Build configuration (with comments)

---

## ?? **Why Dockerfile?**

**Dockerfile is the most reliable method for .NET 10 because:**

1. ? **Explicit .NET 10 SDK/Runtime** - Uses official Microsoft images
2. ? **Multi-stage build** - Smaller final image (SDK ? Runtime)
3. ? **Widely supported** - Railway has excellent Docker support
4. ? **No version detection issues** - Explicitly states .NET 10
5. ? **Future-proof** - Works regardless of Nixpacks updates

**Nixpacks support for .NET 10 may be added later**, but Dockerfile works now.

---

## ?? **Troubleshooting Commands**

```powershell
# View Railway logs in real-time
railway logs

# Check Railway service status
railway status

# Restart deployment
railway up

# SSH into Railway container (if needed)
railway shell
```

---

## ?? **Need Help?**

**Railway Discord:** https://discord.gg/railway  
**Railway Docs:** https://docs.railway.app  
**This Project Issues:** https://github.com/raj29code/PlayOHCanadaAPI/issues  

---

## ?? **Timeline**

| Task | Time |
|------|------|
| Commit & push config files | 2 minutes |
| Railway build (first time) | 5-10 minutes |
| Deploy to production | 1-2 minutes |
| **Total** | **~10-15 minutes** |

---

**Status:** ? Ready to deploy  
**Last Updated:** Phase 2 - Railway Build Configuration  
**Next:** Database migration (Step 5)
