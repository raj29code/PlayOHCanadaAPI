# Schedule Cleanup - Serverless Migration Guide

## Overview

This document outlines the plan to migrate the `ScheduleCleanupService` from a background service to a serverless function (Azure Function or AWS Lambda).

## Current Implementation

**Location:** `PlayOhCanadaAPI\Services\ScheduleCleanupService.cs`

**Type:** .NET BackgroundService (runs continuously with the API)

**Pros:**
- ? Simple to implement
- ? No additional infrastructure needed
- ? Integrated with existing codebase

**Cons:**
- ? Runs continuously even when not needed
- ? Consumes API resources
- ? Scales with API (not independently)
- ? Harder to monitor separately
- ? API must be running for cleanup to work

## Future Architecture: Serverless Function

### Benefits of Serverless Migration

1. **Separation of Concerns**
   - Cleanup logic independent from API
   - API focuses on serving requests
   - Easier to maintain and test

2. **Cost Optimization**
   - Pay only for execution time
   - No resources consumed when idle
   - Typical cost: < $1/month for daily cleanup

3. **Independent Scaling**
   - Function scales separately from API
   - No impact on API performance
   - Can handle large cleanup operations without affecting users

4. **Better Monitoring**
   - Dedicated logs and metrics
   - Alerts specific to cleanup operations
   - Execution history and statistics

5. **Reliability**
   - Runs even if API is down
   - Automatic retries on failure
   - Managed infrastructure

## Implementation Options

### Option 1: Azure Function (Recommended for Azure)

**Technology:** Azure Functions with Timer Trigger

**Architecture:**
```
Azure Function (Timer Trigger)
    ?
Runs daily at 2 AM UTC (cron: 0 0 2 * * *)
    ?
Connects to Azure PostgreSQL
    ?
Executes cleanup logic
    ?
Logs to Application Insights
```

**Code Structure:**
```csharp
public class ScheduleCleanupFunction
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ScheduleCleanupFunction> _logger;

    public ScheduleCleanupFunction(
        ApplicationDbContext context,
        ILogger<ScheduleCleanupFunction> logger)
    {
        _context = context;
        _logger = logger;
    }

    [FunctionName("ScheduleCleanup")]
    public async Task Run(
        [TimerTrigger("0 0 2 * * *")] TimerInfo timer,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Starting scheduled cleanup at {Time}", DateTime.UtcNow);
        
        // Cleanup logic here (extracted from current service)
        await CleanupOldSchedulesAsync(cancellationToken);
        
        _logger.LogInformation("Cleanup completed at {Time}", DateTime.UtcNow);
    }
}
```

**Configuration:**
```json
{
  "Schedule": "0 0 2 * * *",
  "RetentionDays": 7,
  "ConnectionStrings": {
    "DefaultConnection": "@Microsoft.KeyVault(SecretUri=https://vault.azure.net/secrets/db-connection/)"
  }
}
```

**Deployment:**
```bash
# Using Azure CLI
func azure functionapp publish PlayOhCanadaCleanupFunction

# Using Azure Portal
# 1. Create Function App
# 2. Upload function code
# 3. Configure connection string
# 4. Set timer schedule
```

### Option 2: AWS Lambda (Recommended for AWS)

**Technology:** AWS Lambda with EventBridge (CloudWatch Events)

**Architecture:**
```
EventBridge Rule (cron: 0 2 * * ? *)
    ?
Triggers Lambda Function
    ?
Connects to RDS PostgreSQL
    ?
Executes cleanup logic
    ?
Logs to CloudWatch
```

**Code Structure:**
```csharp
public class ScheduleCleanupFunction
{
    private readonly ApplicationDbContext _context;
    private readonly ILambdaLogger _logger;

    [LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]
    public async Task<string> FunctionHandler(ScheduledEvent input, ILambdaContext context)
    {
        _logger = context.Logger;
        _logger.LogInformation("Starting scheduled cleanup");
        
        // Cleanup logic here
        var result = await CleanupOldSchedulesAsync();
        
        return $"Cleaned up {result.ScheduleCount} schedules";
    }
}
```

**Configuration:**
```json
{
  "Schedule": "cron(0 2 * * ? *)",
  "RetentionDays": 7,
  "ConnectionStrings": {
    "DefaultConnection": "{{resolve:secretsmanager:db-connection}}"
  }
}
```

**Deployment:**
```bash
# Using AWS SAM
sam build
sam deploy --guided

# Using AWS CLI
dotnet publish -c Release
aws lambda update-function-code --function-name ScheduleCleanupFunction --zip-file fileb://function.zip
```

### Option 3: Azure Durable Functions (For Complex Workflows)

**Use case:** If cleanup needs orchestration (e.g., archive ? cleanup ? send report)

**Architecture:**
```
Timer Trigger
    ?
Orchestrator Function
    ?
?? Archive Activity
?? Cleanup Activity
?? Notification Activity
```

## Migration Steps

### Phase 1: Preparation (Week 1)

1. **Extract Core Logic**
   - Create standalone cleanup method
   - Add interface for dependency injection
   - Write unit tests

2. **Create Shared Library**
   ```
   PlayOhCanada.Core/
   ??? Services/
   ?   ??? ScheduleCleanupService.cs
   ??? Models/
   ?   ??? CleanupResult.cs
   ??? Data/
       ??? ApplicationDbContext.cs
   ```

3. **Test Extraction**
   - Ensure cleanup logic works standalone
   - Verify database connection
   - Test with different retention periods

### Phase 2: Function Development (Week 2)

**For Azure:**

1. **Create Function Project**
   ```bash
   func init PlayOhCanadaCleanupFunction --dotnet
   cd PlayOhCanadaCleanupFunction
   func new --template "Timer trigger" --name ScheduleCleanup
   ```

2. **Add Dependencies**
   ```xml
   <PackageReference Include="Microsoft.Azure.Functions.Extensions" Version="1.1.0" />
   <PackageReference Include="Microsoft.EntityFrameworkCore" Version="10.0.0" />
   <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
   ```

3. **Configure Startup**
   ```csharp
   [assembly: FunctionsStartup(typeof(Startup))]
   public class Startup : FunctionsStartup
   {
       public override void Configure(IFunctionsHostBuilder builder)
       {
           builder.Services.AddDbContext<ApplicationDbContext>(options =>
               options.UseNpgsql(Environment.GetEnvironmentVariable("ConnectionStrings:DefaultConnection")));
       }
   }
   ```

**For AWS:**

1. **Create Lambda Project**
   ```bash
   dotnet new lambda.EmptyFunction -n PlayOhCanadaCleanupFunction
   ```

2. **Add Dependencies**
   ```xml
   <PackageReference Include="Amazon.Lambda.Core" Version="2.2.0" />
   <PackageReference Include="Amazon.Lambda.Serialization.SystemTextJson" Version="2.4.0" />
   <PackageReference Include="Microsoft.EntityFrameworkCore" Version="10.0.0" />
   <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
   ```

### Phase 3: Testing (Week 3)

1. **Local Testing**
   ```bash
   # Azure Functions
   func start
   
   # AWS Lambda
   sam local invoke ScheduleCleanupFunction
   ```

2. **Integration Testing**
   - Test with development database
   - Verify cleanup logic
   - Check logging output

3. **Load Testing**
   - Test with large datasets
   - Verify performance
   - Check memory usage

### Phase 4: Deployment (Week 4)

1. **Deploy to Staging**
   - Azure: Deploy to staging slot
   - AWS: Deploy to alias

2. **Monitor & Validate**
   - Check execution logs
   - Verify cleanup results
   - Monitor performance

3. **Deploy to Production**
   - Schedule during low-traffic hours
   - Monitor first execution
   - Keep background service as backup initially

### Phase 5: Cleanup (Week 5)

1. **Remove Background Service**
   ```csharp
   // Remove from Program.cs
   // builder.Services.AddHostedService<ScheduleCleanupService>();
   ```

2. **Delete Old Code**
   - Remove `ScheduleCleanupService.cs`
   - Update documentation

3. **Monitor Production**
   - Verify serverless function runs correctly
   - Check for any issues

## Cost Comparison

### Current (Background Service)

**Hosting:**
- API runs 24/7
- Resources: 1 vCPU, 2 GB RAM
- Cost: ~$50-100/month (Azure App Service B1)

**Cleanup Impact:**
- Runs continuously
- Uses ~5% of API resources
- Cost allocation: ~$2.50-5/month

### Future (Serverless)

**Azure Functions (Consumption Plan):**
- Runs once per day
- Duration: ~5 seconds
- Memory: 512 MB
- Executions: 30/month
- Cost: **< $0.01/month** (within free tier)

**AWS Lambda:**
- Runs once per day
- Duration: ~5 seconds
- Memory: 512 MB
- Executions: 30/month
- Cost: **< $0.01/month** (within free tier)

**Savings:** ~$2.50-5/month + reduced API resource usage

## Monitoring & Alerting

### Azure Function Monitoring

**Application Insights:**
```csharp
// Track custom metrics
telemetry.TrackMetric("SchedulesDeleted", schedulesDeleted);
telemetry.TrackMetric("BookingsDeleted", bookingsDeleted);
telemetry.TrackMetric("ExecutionTime", executionTime.TotalSeconds);
```

**Alerts:**
- Function failure
- Execution duration > 30 seconds
- No executions in 25 hours (should run daily)

### AWS Lambda Monitoring

**CloudWatch Metrics:**
```csharp
// Log custom metrics
var metrics = new CloudWatchClient();
await metrics.PutMetricDataAsync(new PutMetricDataRequest
{
    Namespace = "PlayOhCanada/Cleanup",
    MetricData = new List<MetricDatum>
    {
        new MetricDatum
        {
            MetricName = "SchedulesDeleted",
            Value = schedulesDeleted,
            Timestamp = DateTime.UtcNow
        }
    }
});
```

**Alerts:**
- Lambda error rate > 0
- Duration > 30 seconds
- No invocations in 25 hours

## Security Considerations

### Database Connection

**Azure:**
- Use Managed Identity
- Store connection in Key Vault
- No connection strings in code

**AWS:**
- Use IAM roles
- Store connection in Secrets Manager
- Rotate credentials automatically

### Network Security

**Azure:**
- VNet integration for private database access
- Service endpoints

**AWS:**
- VPC configuration
- Security groups

## Rollback Plan

If migration fails:

1. **Immediate Rollback**
   ```csharp
   // Re-enable in Program.cs
   builder.Services.AddHostedService<ScheduleCleanupService>();
   ```

2. **Redeploy API**
   ```bash
   dotnet publish -c Release
   # Deploy to hosting environment
   ```

3. **Disable Serverless Function**
   - Azure: Disable Function App
   - AWS: Remove EventBridge rule

4. **Investigate Issues**
   - Check logs
   - Identify root cause
   - Fix and retry

## Success Criteria

? **Function executes daily** without errors
? **Cleanup logic works correctly** (verified in logs)
? **Performance is acceptable** (< 30 seconds)
? **No impact on API** performance
? **Cost reduction** achieved
? **Monitoring and alerts** working
? **No data loss** or corruption

## Timeline Summary

| Phase | Duration | Activities |
|-------|----------|------------|
| **Preparation** | 1 week | Extract logic, create shared library, tests |
| **Development** | 1 week | Create function, configure dependencies |
| **Testing** | 1 week | Local, integration, load testing |
| **Deployment** | 1 week | Staging, production deployment |
| **Cleanup** | 1 week | Remove old code, monitor production |

**Total:** 5 weeks

## Documentation Updates

After migration, update:

1. **SCHEDULE_CLEANUP_GUIDE.md**
   - Remove Background Service references
   - Add Serverless Function details
   - Update configuration examples

2. **README.md**
   - Update architecture diagram
   - Add serverless deployment steps

3. **Program.cs comments**
   - Remove TODO comments
   - Add reference to serverless function

## Conclusion

Migrating the cleanup service to serverless architecture provides:

- ?? **Cost savings** (~$2.50-5/month)
- ?? **Better performance** (no impact on API)
- ?? **Improved monitoring** (dedicated metrics)
- ?? **Easier maintenance** (independent deployment)
- ?? **Better scalability** (independent scaling)

**Recommendation:** Prioritize this migration for production deployments.

---

**Status:** TODO - Planned for future implementation
**Priority:** Medium
**Effort:** 5 weeks
**ROI:** High (cost savings + performance improvement)
