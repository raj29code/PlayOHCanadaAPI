# Railway Deployment Fix Guide

## ?? Problem Fixed

**Error:** `? Script start.sh not found` and `? Railpack could not determine how to build the app.`

**Root Cause:** Railway couldn't auto-detect how to build a .NET 10 application.

**Solution:** Added explicit build configuration files.

---

## ?? Files Added

### 1. **`nixpacks.toml`** ?
Railway's preferred configuration method using Nixpacks.

**What it does:**
- Specifies .NET SDK 10 as build dependency
- Defines restore and publish commands
- Sets up the start command
- Configures ASPNETCORE_URLS for Railway's dynamic ports

### 2. **`railway.json`** ?
Alternative Railway configuration (JSON format).

**What it does:**
- Defines build and deploy commands
- Configures restart policy
- Provides explicit builder type (NIXPACKS)

### 3. **`Dockerfile`** ? (Most Reliable)
Docker-based deployment configuration.

**What it does:**
- Multi-stage build (SDK for build, runtime for deployment)
- Optimized image size
- Explicit .NET 10 runtime
- Port configuration (8080)

**Why use Dockerfile?**
- Most reliable for .NET 10 (newest version)
- Railway has excellent Docker support
- Explicit control over build process
- Works even if Nixpacks doesn't support .NET 10 yet

### 4. **`.dockerignore`** ?
Optimizes Docker builds by excluding unnecessary files.

---

## ?? Deployment Steps

### **Option 1: Automatic (Recommended)**

Railway will now automatically detect and use these configuration files:

1. **Commit and push the new files:**
   ```bash
   git add nixpacks.toml railway.json Dockerfile .dockerignore
   git commit -m "Add Railway deployment configuration for .NET 10"
   git push origin feature/sports-api
   ```

2. **Railway will automatically:**
   - Detect the `Dockerfile` (first priority)
   - Or use `nixpacks.toml` (if no Dockerfile)
   - Build your application
   - Deploy to production

3. **Monitor deployment:**
   - Go to Railway Dashboard
   - Click on your project
   - Watch the build logs
   - Wait for deployment to complete (5-10 minutes)

---

### **Option 2: Force Specific Build Method**

If Railway doesn't automatically use Dockerfile:

**Railway Dashboard ? Project Settings ? Build:**
- Set **Builder**: `DOCKERFILE`
- Set **Dockerfile Path**: `Dockerfile`
- Click **Save**

Then trigger a redeploy:
- Click **Deployments** tab
- Click **Redeploy** on the latest deployment

---

## ? What to Expect

### **Build Process:**
```
Building with Dockerfile...
[1/2] Build stage
  ? Restoring dependencies...
  ? Building project...
  ? Publishing to /app/publish...
[2/2] Runtime stage
  ? Using ASP.NET Core 10 runtime
  ? Copying published files...
Build completed successfully ?
```

### **Deploy Process:**
```
Starting PlayOhCanadaAPI.dll...
Application started on port 8080
Health check passed ?
Deployment successful ?
```

---

## ?? Verify Configuration Files

### **nixpacks.toml Check:**
```toml
[phases.setup]
nixPkgs = ["dotnet-sdk_10"]  # Correct .NET version

[phases.build]
cmds = [
    "dotnet restore PlayOhCanadaAPI/PlayOhCanadaAPI.csproj",  # Correct path
    "dotnet publish PlayOhCanadaAPI/PlayOhCanadaAPI.csproj -c Release -o out"
]

[phases.start]
cmd = "cd out && dotnet PlayOhCanadaAPI.dll"  # Correct DLL name
```

### **Dockerfile Check:**
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build  # .NET 10 SDK
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime  # .NET 10 Runtime
```

---

## ?? Troubleshooting

### **Issue 1: Build still fails**
```
Error: dotnet-sdk_10 not found in Nixpacks
```

**Solution:** Railway will use Dockerfile automatically since Nixpacks may not support .NET 10 yet.

**Action:** No action needed - Dockerfile is the fallback.

---

### **Issue 2: Port binding error**
```
Error: Unable to bind to http://localhost:5000
```

**Solution:** Railway uses dynamic ports via `$PORT` environment variable.

**Fix:** Already configured in all config files:
- Dockerfile: `ENV ASPNETCORE_URLS=http://+:8080`
- nixpacks.toml: `ASPNETCORE_URLS = "http://0.0.0.0:$PORT"`

**Verify in Railway:**
- Go to Variables tab
- Check if `PORT` variable exists (Railway auto-creates this)

---

### **Issue 3: Wrong project path**
```
Error: Could not find project file
```

**Solution:** Verify your project structure matches:
```
PlayOHCanadaAPI/          # Root repo directory
??? Dockerfile             # ? At root
??? nixpacks.toml          # ? At root
??? railway.json           # ? At root
??? PlayOhCanadaAPI/       # Project directory
    ??? PlayOhCanadaAPI.csproj
```

---

## ?? Post-Deployment Checklist

After successful deployment:

- [ ] ? Build completed without errors
- [ ] ? Application started successfully
- [ ] ? Health check endpoint responds (if configured)
- [ ] ? Environment variables loaded correctly
- [ ] ? Database connection working
- [ ] ? API endpoints accessible

**Test the deployment:**
```powershell
# Replace with your Railway URL
$baseUrl = "https://your-app.up.railway.app"

# Test sports endpoint
Invoke-RestMethod -Uri "$baseUrl/api/sports" -Method Get

# Test Scalar UI
Start-Process "$baseUrl/scalar/v1"
```

---

## ?? Next Steps After Successful Deployment

1. **Run Database Migrations** (see RAILWAY_DEPLOYMENT.md Step 5)
2. **Test All Endpoints** (see RAILWAY_DEPLOYMENT.md Step 6)
3. **Configure CI/CD** (see RAILWAY_DEPLOYMENT.md Day 2)
4. **Update Documentation** with production URLs

---

## ?? Additional Resources

**Railway Documentation:**
- [.NET Deployment Guide](https://docs.railway.app/guides/dotnet)
- [Nixpacks .NET Support](https://nixpacks.com/docs/providers/csharp)
- [Dockerfile Builds](https://docs.railway.app/deploy/builds#dockerfile)

**Microsoft .NET 10 Documentation:**
- [.NET 10 Docker Images](https://hub.docker.com/_/microsoft-dotnet)
- [ASP.NET Core Deployment](https://learn.microsoft.com/aspnet/core/host-and-deploy/)

---

## ?? Alternative: If Docker Doesn't Work

If Docker builds are slow or fail, Railway offers **direct Nixpacks support**.

**Wait for Nixpacks update:**
Railway/Nixpacks may add .NET 10 support soon. Check:
```bash
# Check current Nixpacks .NET support
npx nixpacks detect
```

**Temporary workaround:**
Use .NET 8 temporarily (stable Nixpacks support):
```toml
[phases.setup]
nixPkgs = ["dotnet-sdk_8"]  # Change from 10 to 8
```

Then update to .NET 10 when Nixpacks adds support.

---

## ? Success Confirmation

You'll know it's working when you see:

**Railway Build Logs:**
```
? Building with Dockerfile
? [1/2] Build stage completed
? [2/2] Runtime stage completed
? Image built successfully
? Pushing to registry...
? Deployment successful
```

**Railway Deployment Logs:**
```
info: Microsoft.Hosting.Lifetime[0]
      Now listening on: http://0.0.0.0:8080
info: Microsoft.Hosting.Lifetime[0]
      Application started
```

---

## ?? Pro Tips

1. **Use Dockerfile for .NET 10** - Most reliable until Nixpacks adds official support
2. **Monitor build time** - First build: 5-10 min, Subsequent: 2-3 min (cached)
3. **Check Railway status** - https://status.railway.app if builds fail
4. **Use Railway CLI** - For faster iteration during setup

**Install Railway CLI:**
```bash
npm i -g @railway/cli
railway login
railway link
railway logs  # View real-time logs
```

---

## ?? Need Help?

**Railway Support:**
- Discord: https://discord.gg/railway
- Documentation: https://docs.railway.app
- Status Page: https://status.railway.app

**This Project:**
- Check `PROGRESS.md` for Phase 2 deployment steps
- Check `README.md` for local setup
- Create GitHub issue for bugs

---

**Last Updated:** Phase 2 - Railway Deployment Configuration  
**Status:** ? Ready to deploy
