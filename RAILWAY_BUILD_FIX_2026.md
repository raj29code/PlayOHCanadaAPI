# Railway Build Fix - Project Path Issue

## Problem
Railway build was failing with error:
```
MSBUILD : error MSB1009: Project file does not exist.
Switch: PlayOhCanadaAPI/PlayOhCanadaAPI.csproj
```

## Root Cause
The `railway.json` file had a custom `buildCommand` that was overriding the Dockerfile instructions. This caused Railway to run dotnet commands in the wrong context.

## Solution Applied

### 1. Updated `Dockerfile`
- Changed COPY command to use explicit array syntax for better path handling
- Ensured proper quoting of paths with the project name

### 2. Updated `railway.json`
- **Removed** custom `buildCommand` - let Dockerfile handle the build
- **Removed** custom `startCommand` - Dockerfile already has ENTRYPOINT
- Simplified configuration to only specify the builder type

## Files Modified
- `Dockerfile` - Improved path handling
- `railway.json` - Removed conflicting build commands

## What Railway Will Do Now
1. Clone your repository
2. Find the `Dockerfile` at the root
3. Execute the Dockerfile which:
   - Copies `PlayOhCanadaAPI/PlayOhCanadaAPI.csproj` to the build container
   - Runs `dotnet restore`
   - Copies the rest of the `PlayOhCanadaAPI/` directory
   - Builds and publishes the application
   - Creates a runtime container with the published output

## Next Steps
1. Commit these changes:
   ```bash
   git add Dockerfile railway.json
   git commit -m "Fix Railway build path issue"
   git push
   ```

2. Railway will automatically trigger a new build

3. The build should now succeed

## Verification
Once deployed, test the API:
```bash
curl https://your-railway-app.up.railway.app/api/health
```

## Important Notes
- The repository structure has the project at: `PlayOhCanadaAPI/PlayOhCanadaAPI.csproj`
- Dockerfile is at the repository root
- Railway clones the entire repository and uses the Dockerfile at the root
- The Dockerfile correctly references the nested project structure
