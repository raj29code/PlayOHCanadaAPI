# Recurring Schedule - Quick Reference

## Your Use Case: Every Thursday 7-10 PM (Jan 1 - Feb 1, 2026)

### Request

```json
POST /api/schedules
Authorization: Bearer YOUR_ADMIN_TOKEN

{
  "sportId": 1,
  "venue": "Central Park Tennis Court",
  "startTime": "2026-01-01T19:00:00Z",
  "endTime": "2026-01-01T22:00:00Z",
  "maxPlayers": 8,
  "equipmentDetails": "Bring your own racket",
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "endDate": "2026-02-01T23:59:59Z",
    "daysOfWeek": [4]
  }
}
```

### Result

Creates schedules for:
- Thursday, Jan 2, 2026 @ 7-10 PM
- Thursday, Jan 9, 2026 @ 7-10 PM
- Thursday, Jan 16, 2026 @ 7-10 PM
- Thursday, Jan 23, 2026 @ 7-10 PM
- Thursday, Jan 30, 2026 @ 7-10 PM

## Common Patterns

### Every Monday, Wednesday, Friday

```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [1, 3, 5],
    "endDate": "2026-12-31T23:59:59Z"
  }
}
```

### Every Weekend (Sat & Sun)

```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [0, 6],
    "endDate": "2026-12-31T23:59:59Z"
  }
}
```

### Every Day for a Week

```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 1,
    "endDate": "2026-01-07T23:59:59Z"
  }
}
```

### 15th of Every Month

```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 4,
    "endDate": "2026-12-31T23:59:59Z"
  }
}
```

### Every Other Thursday (BiWeekly)

```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 3,
    "daysOfWeek": [4],
    "endDate": "2026-12-31T23:59:59Z"
  }
}
```

## Day of Week Numbers

- 0 = Sunday
- 1 = Monday
- 2 = Tuesday
- 3 = Wednesday
- 4 = Thursday
- 5 = Friday
- 6 = Saturday

## Frequency Numbers

- 1 = Daily
- 2 = Weekly (requires `daysOfWeek`)
- 3 = BiWeekly (requires `daysOfWeek`)
- 4 = Monthly

## Validation Requirements

? For recurring schedules:
- `isRecurring` must be `true`
- `frequency` is required (1-4)
- `endDate` is required and must be after `startTime`

? For Weekly/BiWeekly:
- `daysOfWeek` array is required
- Must contain at least one day (0-6)

## Testing

```powershell
# Test all patterns
.\test-recurring-schedules.ps1

# Test specific pattern (PowerShell)
$token = "YOUR_ADMIN_TOKEN"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    sportId = 1
    venue = "Tennis Court"
    startTime = "2026-01-01T19:00:00Z"
    endTime = "2026-01-01T22:00:00Z"
    maxPlayers = 8
    recurrence = @{
        isRecurring = $true
        frequency = 2
        daysOfWeek = @(4)
        endDate = "2026-02-01T23:59:59Z"
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://localhost:5000/api/schedules" `
    -Method Post -Headers $headers -Body $body
```

## Documentation

- **Complete Guide:** [RECURRING_SCHEDULE_GUIDE.md](RECURRING_SCHEDULE_GUIDE.md)
- **Implementation Details:** [RECURRING_SCHEDULE_IMPLEMENTATION.md](RECURRING_SCHEDULE_IMPLEMENTATION.md)
- **Main README:** [README.md](README.md)

## Summary

? Your use case is fully supported!
? Create schedules on specific days (like Thursday)
? Set date ranges (Jan 1 - Feb 1)
? Set specific times (7 PM - 10 PM)
? Admin-only API for schedule creation

Just send one API request and get all recurring schedules created automatically! ??
