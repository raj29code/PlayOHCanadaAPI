# Timezone Handling Guide

## Problem

When users in different timezones create schedules, the date/time needs to be properly converted to UTC for storage. Without timezone information, a schedule created for "7 PM EST" would be stored as "7 PM UTC", resulting in a 5-hour mismatch.

## Solution

The API now accepts a `timezoneOffsetMinutes` field to properly convert local times to UTC.

## How It Works

### Creating a Schedule

**User in EST (UTC-5) wants to create a schedule for 7 PM local time:**

```json
POST /api/schedules

{
  "sportId": 1,
  "venue": "Tennis Court A",
  "startDate": "2026-01-29",
  "startTime": "19:00:00",              // 7 PM local time
  "endTime": "20:00:00",                // 8 PM local time
  "timezoneOffsetMinutes": -300,        // EST is UTC-5 (-5 * 60 = -300)
  "maxPlayers": 8
}
```

**What happens:**
1. Server receives: January 29, 2026 at 7:00 PM (local time in EST)
2. Server converts: `7:00 PM - (-300 minutes) = 7:00 PM + 5 hours = 12:00 AM UTC (next day)`
3. Database stores: `2026-01-30 00:00:00 UTC`
4. When user retrieves: Converted back to `2026-01-29 19:00:00 EST` ?

## Timezone Offset Values

### Common US Timezones

| Timezone | Standard Offset | Daylight Offset | Standard Name | Daylight Name |
|----------|----------------|-----------------|---------------|---------------|
| Eastern | -300 | -240 | EST (UTC-5) | EDT (UTC-4) |
| Central | -360 | -300 | CST (UTC-6) | CDT (UTC-5) |
| Mountain | -420 | -360 | MST (UTC-7) | MDT (UTC-6) |
| Pacific | -480 | -420 | PST (UTC-8) | PDT (UTC-7) |

### Canadian Timezones

| Timezone | Standard Offset | Daylight Offset |
|----------|----------------|-----------------|
| Newfoundland | -210 | -150 |
| Atlantic | -240 | -180 |
| Eastern | -300 | -240 |
| Central | -360 | -300 |
| Mountain | -420 | -360 |
| Pacific | -480 | -420 |

### How to Calculate

**Formula:** `offsetMinutes = (UTC - LocalTime) * 60`

**Examples:**
- EST (UTC-5): `(-5) * 60 = -300`
- PST (UTC-8): `(-8) * 60 = -480`
- IST (UTC+5:30): `(+5.5) * 60 = +330`
- UTC: `0`

## JavaScript/Frontend Implementation

### Get User's Timezone Offset

```javascript
// Get current timezone offset in minutes
const timezoneOffsetMinutes = -new Date().getTimezoneOffset();

// Example: User in EST during winter
// getTimezoneOffset() returns 300 (minutes ahead of UTC)
// We negate it to get -300 (EST is UTC-5)
```

### Complete Example

```javascript
async function createSchedule(scheduleData) {
  // Get user's timezone offset
  const timezoneOffsetMinutes = -new Date().getTimezoneOffset();
  
  const response = await fetch('/api/schedules', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      sportId: 1,
      venue: 'Tennis Court A',
      startDate: '2026-01-29',
      startTime: '19:00:00',  // User's local time
      endTime: '20:00:00',    // User's local time
      timezoneOffsetMinutes: timezoneOffsetMinutes,  // Auto-detected
      maxPlayers: 8,
      equipmentDetails: 'Bring your own racket'
    })
  });
  
  return await response.json();
}
```

### React Example

```jsx
import { useState, useEffect } from 'react';

function CreateScheduleForm() {
  const [timezoneOffset, setTimezoneOffset] = useState(0);
  
  useEffect(() => {
    // Get user's timezone offset
    setTimezoneOffset(-new Date().getTimezoneOffset());
  }, []);
  
  const handleSubmit = async (formData) => {
    const payload = {
      ...formData,
      timezoneOffsetMinutes: timezoneOffset
    };
    
    const response = await fetch('/api/schedules', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    
    return await response.json();
  };
  
  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
      <input type="hidden" value={timezoneOffset} />
    </form>
  );
}
```

## PowerShell Example

```powershell
# Get timezone offset for EST (manually)
$timezoneOffsetMinutes = -300  # EST is UTC-5

# Or calculate from current timezone
$timezoneOffsetMinutes = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)

$body = @{
    sportId = 1
    venue = "Tennis Court A"
    startDate = "2026-01-29"
    startTime = "19:00:00"
    endTime = "20:00:00"
    timezoneOffsetMinutes = $timezoneOffsetMinutes
    maxPlayers = 8
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://localhost:7063/api/schedules" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    } `
    -Body $body
```

## cURL Example

```bash
# For EST (UTC-5)
curl -X POST https://localhost:7063/api/schedules \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sportId": 1,
    "venue": "Tennis Court A",
    "startDate": "2026-01-29",
    "startTime": "19:00:00",
    "endTime": "20:00:00",
    "timezoneOffsetMinutes": -300,
    "maxPlayers": 8
  }'
```

## Recurring Schedules

For recurring schedules, the same timezone offset applies to all occurrences:

```json
{
  "sportId": 1,
  "venue": "Tennis Court A",
  "startDate": "2026-01-07",
  "startTime": "19:00:00",
  "endTime": "20:00:00",
  "timezoneOffsetMinutes": -300,  // All Wednesdays at 7 PM EST
  "maxPlayers": 8,
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [3],
    "endDate": "2026-02-28"
  }
}
```

**Result:** All Wednesday schedules will be at 7-8 PM in the user's timezone (EST).

## Updating Schedules

When updating a schedule, provide the timezone offset if changing date or time:

```json
PUT /api/schedules/123

{
  "date": "2026-02-01",
  "startTime": "18:00:00",
  "endTime": "19:00:00",
  "timezoneOffsetMinutes": -300  // EST
}
```

## Default Behavior

If `timezoneOffsetMinutes` is not provided or is `0`, the system assumes **UTC**.

```json
{
  "startTime": "19:00:00",
  "timezoneOffsetMinutes": 0  // Assumes UTC (or omit the field)
}
```

## Validation

The `timezoneOffsetMinutes` field is validated to be between -720 and +720 (±12 hours):

```csharp
[Range(-720, 720)]
public int TimezoneOffsetMinutes { get; set; } = 0;
```

## Daylight Saving Time (DST)

?? **Important:** The client is responsible for determining if DST is active.

**During EST (Standard Time):**
```javascript
// January (Standard Time)
const offset = -new Date('2026-01-29').getTimezoneOffset();  // -300
```

**During EDT (Daylight Time):**
```javascript
// July (Daylight Time)
const offset = -new Date('2026-07-29').getTimezoneOffset();  // -240
```

JavaScript's `getTimezoneOffset()` automatically handles DST.

## Display Times to Users

When retrieving schedules, convert UTC times back to user's local timezone:

```javascript
async function getSchedules() {
  const response = await fetch('/api/schedules');
  const schedules = await response.json();
  
  return schedules.map(schedule => ({
    ...schedule,
    // Convert UTC to local time for display
    startTimeLocal: new Date(schedule.startTime).toLocaleString(),
    endTimeLocal: new Date(schedule.endTime).toLocaleString()
  }));
}
```

## Testing Different Timezones

### Test EST Schedule (Winter - Standard Time)

```json
{
  "startDate": "2026-01-29",
  "startTime": "19:00:00",
  "endTime": "20:00:00",
  "timezoneOffsetMinutes": -300
}
```

**Stored in DB:** `2026-01-30 00:00:00 UTC`

### Test EDT Schedule (Summer - Daylight Time)

```json
{
  "startDate": "2026-07-29",
  "startTime": "19:00:00",
  "endTime": "20:00:00",
  "timezoneOffsetMinutes": -240
}
```

**Stored in DB:** `2026-07-29 23:00:00 UTC`

### Test PST Schedule

```json
{
  "startDate": "2026-01-29",
  "startTime": "19:00:00",
  "endTime": "20:00:00",
  "timezoneOffsetMinutes": -480
}
```

**Stored in DB:** `2026-01-30 03:00:00 UTC`

## Best Practices

### ? DO:

1. **Always provide timezone offset** from the client
2. **Use JavaScript's `getTimezoneOffset()`** to auto-detect
3. **Store UTC in database** (handled automatically)
4. **Convert to local time for display**
5. **Handle DST automatically** using JavaScript Date API

### ? DON'T:

1. **Don't assume UTC** unless explicitly intended
2. **Don't hardcode timezone offsets** - detect automatically
3. **Don't forget DST transitions**
4. **Don't mix timezones** in the same request

## Troubleshooting

### Issue: Schedule appears 5 hours off

**Cause:** Timezone offset not provided or incorrect

**Solution:** Ensure client sends correct `timezoneOffsetMinutes`

```javascript
// Correct way
const offset = -new Date().getTimezoneOffset();
```

### Issue: DST transition causes time shift

**Cause:** Using hardcoded offset value

**Solution:** Calculate offset for the specific date:

```javascript
// Calculate offset for the schedule date
const scheduleDate = new Date('2026-07-29');
const offset = -scheduleDate.getTimezoneOffset();
```

### Issue: Different users see different times

**Cause:** This is expected behavior!

**Solution:** Users in different timezones will see schedules converted to their local time. This is correct.

**Example:**
- Schedule created for 7 PM EST
- User in EST sees: 7:00 PM
- User in PST sees: 4:00 PM ?

## Summary

? **Timezone-Aware:** Properly handles user timezones
? **Auto-Detection:** Client can auto-detect timezone
? **UTC Storage:** All times stored as UTC in database
? **DST Support:** Handles daylight saving time
? **Backward Compatible:** Defaults to UTC if not provided
? **Simple API:** Just one integer field

**Your timezone concern is now fully addressed!** ???
