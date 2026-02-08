# TODO: Serverless Migration Summary

## ? TODO Marked for Future Migration

The Schedule Cleanup Service has been marked for future migration to serverless architecture (Azure Functions or AWS Lambda).

## Where TODOs Were Added

### 1. ScheduleCleanupService.cs

**Location:** Top of file and above cleanup method

**Comments Added:**
```csharp
// TODO: FUTURE ENHANCEMENT - Move this cleanup service to Azure Function or AWS Lambda
// Benefits:
// - Separate from main API (better separation of concerns)
// - Can run on schedule without keeping API running
// - Cost-effective (serverless, pay-per-execution)
// - Easier scaling and monitoring
// - No impact on API performance
// Implementation options:
// 1. Azure Function with Timer Trigger (cron schedule)
// 2. AWS Lambda with EventBridge (cron schedule)
// 3. Azure Durable Functions for more complex workflows
```

### 2. Program.cs

**Location:** Where ScheduleCleanupService is registered

**Comment Added:**
```csharp
// TODO: FUTURE - Remove this when migrating to Azure Function/Lambda
// This background service should be replaced with a serverless function for:
// - Better separation of concerns
// - Independent scaling
// - Cost optimization (pay per execution)
// - No impact on API performance
```

### 3. Documentation Created

**SERVERLESS_MIGRATION_PLAN.md** - Complete migration guide including:
- Current vs Future architecture comparison
- Benefits of serverless migration
- Implementation options (Azure Functions / AWS Lambda)
- Step-by-step migration plan (5-week timeline)
- Code examples for both platforms
- Cost comparison (saves ~$2.50-5/month)
- Security considerations
- Monitoring and alerting setup
- Rollback plan
- Success criteria

### 4. Configuration Example

**appsettings.json.example** - Template with ScheduleCleanup settings

## Why Migrate to Serverless?

### Current Architecture (Background Service)

```
API Server (24/7)
    ?
Background Service (always running)
    ?
Runs cleanup every 24 hours
```

**Issues:**
- Consumes API resources continuously
- Runs even when not needed
- Scales with API (not independently)
- Must keep API running for cleanup
- Harder to monitor separately

### Future Architecture (Serverless)

```
Timer/Schedule (cron)
    ?
Triggers Function (only when needed)
    ?
Connects to Database
    ?
Executes cleanup
    ?
Terminates (no idle resources)
```

**Benefits:**
- ?? **Cost:** < $0.01/month (within free tier) vs $2.50-5/month
- ?? **Performance:** No impact on API
- ?? **Monitoring:** Dedicated metrics and logs
- ?? **Maintenance:** Independent deployment
- ?? **Scaling:** Scales independently from API
- ? **Reliability:** Runs even if API is down

## Migration Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| **1. Preparation** | 1 week | Extract logic, create shared library |
| **2. Development** | 1 week | Create serverless function |
| **3. Testing** | 1 week | Local, integration, load testing |
| **4. Deployment** | 1 week | Deploy to staging & production |
| **5. Cleanup** | 1 week | Remove old code, monitor |

**Total:** 5 weeks

## Implementation Options

### Option 1: Azure Functions

**Best for:** Azure-hosted applications

**Example:**
```csharp
[FunctionName("ScheduleCleanup")]
public async Task Run(
    [TimerTrigger("0 0 2 * * *")] TimerInfo timer)
{
    await CleanupOldSchedulesAsync();
}
```

**Schedule:** `0 0 2 * * *` (runs at 2 AM daily)

### Option 2: AWS Lambda

**Best for:** AWS-hosted applications

**Example:**
```csharp
[LambdaSerializer(typeof(DefaultLambdaJsonSerializer))]
public async Task<string> FunctionHandler(
    ScheduledEvent input, 
    ILambdaContext context)
{
    return await CleanupOldSchedulesAsync();
}
```

**Schedule:** `cron(0 2 * * ? *)` (runs at 2 AM daily)

## Cost Comparison

### Current (Background Service)

- API hosting: ~$50-100/month
- Cleanup allocation: ~$2.50-5/month
- Total: Included in API cost

### Future (Serverless)

**Azure Functions:**
- Executions: 30/month
- Duration: ~5 seconds each
- Memory: 512 MB
- Cost: **< $0.01/month** ?

**AWS Lambda:**
- Invocations: 30/month
- Duration: ~5 seconds each
- Memory: 512 MB
- Cost: **< $0.01/month** ?

**Savings:** ~$2.50-5/month + reduced API resource usage

## Priority & Effort

| Aspect | Rating | Notes |
|--------|--------|-------|
| **Priority** | Medium | Not urgent but valuable for production |
| **Effort** | 5 weeks | Full migration with testing |
| **ROI** | High | Cost savings + performance improvement |
| **Risk** | Low | Can rollback if needed |

## Next Steps (When Ready to Migrate)

1. **Read the full plan:** `SERVERLESS_MIGRATION_PLAN.md`
2. **Choose platform:** Azure Functions or AWS Lambda
3. **Extract core logic:** Create standalone cleanup method
4. **Create function project:** Use platform-specific template
5. **Test locally:** Verify function works correctly
6. **Deploy to staging:** Test in staging environment
7. **Deploy to production:** Monitor first execution
8. **Remove background service:** Clean up old code

## Rollback Plan

If migration fails:
1. Re-enable background service in `Program.cs`
2. Redeploy API
3. Disable serverless function
4. Investigate and fix issues

## Documentation References

- **Full Migration Plan:** [SERVERLESS_MIGRATION_PLAN.md](SERVERLESS_MIGRATION_PLAN.md)
- **Current Implementation:** [SCHEDULE_CLEANUP_GUIDE.md](SCHEDULE_CLEANUP_GUIDE.md)
- **Cleanup Service:** [ScheduleCleanupService.cs](PlayOhCanadaAPI/Services/ScheduleCleanupService.cs)

## Build Status

? **Build Successful** - All TODOs added without breaking changes

## Files Modified

1. **ScheduleCleanupService.cs** - Added TODO comments (2 locations)
2. **Program.cs** - Added TODO comment (1 location)

## Files Created

1. **SERVERLESS_MIGRATION_PLAN.md** - Complete migration guide
2. **TODO_SERVERLESS_MIGRATION.md** - This summary
3. **appsettings.json.example** - Configuration template

## Summary

? **TODOs marked** for future serverless migration
? **Complete migration plan** documented
? **Benefits clearly outlined** (cost, performance, scalability)
? **Implementation options** provided (Azure & AWS)
? **No breaking changes** to current functionality

The cleanup service will continue to work as a background service until you're ready to migrate to serverless architecture. When that time comes, follow the detailed plan in `SERVERLESS_MIGRATION_PLAN.md`.

---

**Status:** ? TODO Marked
**Timeline:** 5 weeks when ready to implement
**Expected ROI:** High (cost savings + improved performance)
**Risk:** Low (can rollback if needed)
