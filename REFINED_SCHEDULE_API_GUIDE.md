# Refined Schedule API - Date and Time Separation Guide

## Overview

The Schedule API has been refined to clearly separate **date** and **time** concepts, making it more intuitive to create schedules that occur at the same time (e.g., 7 PM - 8 PM) but on different dates (e.g., every Wednesday).

## Key Changes

### Before (Old Structure)
```json
{
  "startTime": "2026-01-15T19:00:00Z",  // Date + Time combined
  "endTime": "2026-01-15T20:00:00Z"     // Date + Time combined
}
```

### After (New Structure)
```json
{
  "startDate": "2026-01-15",  // Date only
  "startTime": "19:00:00",    // Time only (7 PM)
  "endTime": "20:00:00"       // Time only (8 PM)
}
```

## Benefits

? **Clearer Intent** - Separate concerns for when (date) and what time (time of day)
? **Easier Recurring** - Time stays consistent (7-8 PM) across all occurrences
? **Better Validation** - Can validate date ranges and time ranges independently
? **Intuitive API** - Matches how people think about schedules

## API Structure

### Create Schedule Request

```json
POST /api/schedules

{
  "sportId": 1,
  "venue": "Tennis Court A",
  "startDate": "2026-01-15",      // When the schedule starts (date)
  "startTime": "19:00:00",        // What time the game starts (7 PM)
  "endTime": "20:00:00",          // What time the game ends (8 PM)
  "maxPlayers": 8,
  "equipmentDetails": "Bring your own racket",
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,               // Weekly
    "daysOfWeek": [3],           // Wednesday
    "endDate": "2026-02-28"      // Until when to repeat (date)
  }
}
```

### Field Descriptions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `startDate` | DateOnly | First occurrence date | `"2026-01-15"` |
| `startTime` | TimeOnly | Game start time (time of day) | `"19:00:00"` (7 PM) |
| `endTime` | TimeOnly | Game end time (time of day) | `"20:00:00"` (8 PM) |
| `recurrence.endDate` | DateOnly | Last date to generate schedules | `"2026-02-28"` |

## Use Cases

### Use Case 1: Every Wednesday 7-8 PM

**Scenario:** Tennis every Wednesday from 7 PM to 8 PM, starting Jan 15 through Feb 28, 2026

```json
{
  "sportId": 1,
  "venue": "Tennis Court A",
  "startDate": "2026-01-15",
  "startTime": "19:00:00",
  "endTime": "20:00:00",
  "maxPlayers": 8,
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [3],
    "endDate": "2026-02-28"
  }
}
```

**Result:** Creates schedules for:
- Wednesday, Jan 15, 2026 @ 7-8 PM
- Wednesday, Jan 22, 2026 @ 7-8 PM
- Wednesday, Jan 29, 2026 @ 7-8 PM
- Wednesday, Feb 5, 2026 @ 7-8 PM
- Wednesday, Feb 12, 2026 @ 7-8 PM
- Wednesday, Feb 19, 2026 @ 7-8 PM
- Wednesday, Feb 26, 2026 @ 7-8 PM

### Use Case 2: Weekend Morning Games

**Scenario:** Soccer every Saturday and Sunday from 9 AM to 11 AM for March 2026

```json
{
  "sportId": 4,
  "venue": "Soccer Field",
  "startDate": "2026-03-01",
  "startTime": "09:00:00",
  "endTime": "11:00:00",
  "maxPlayers": 22,
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [0, 6],
    "endDate": "2026-03-31"
  }
}
```

**Result:** Every Saturday and Sunday in March at 9-11 AM

### Use Case 3: Monthly Tournament

**Scenario:** Tournament on the 15th of each month from 10 AM to 4 PM

```json
{
  "sportId": 2,
  "venue": "Championship Arena",
  "startDate": "2026-01-15",
  "startTime": "10:00:00",
  "endTime": "16:00:00",
  "maxPlayers": 32,
  "recurrence": {
    "isRecurring": true,
    "frequency": 4,
    "endDate": "2026-12-31"
  }
}
```

**Result:** 15th of each month from Jan-Dec 2026 at 10 AM-4 PM

### Use Case 4: Single Event

**Scenario:** Special event on July 4, 2026 from 2 PM to 6 PM

```json
{
  "sportId": 6,
  "venue": "Grand Stadium",
  "startDate": "2026-07-04",
  "startTime": "14:00:00",
  "endTime": "18:00:00",
  "maxPlayers": 100,
  "equipmentDetails": "July 4th Special Event"
}
```

**Result:** Single schedule on July 4, 2026 at 2-6 PM

## Time Formats

### TimeOnly Format

**Format:** `HH:mm:ss` (24-hour format)

| Time | Format | Description |
|------|--------|-------------|
| 7:00 AM | `"07:00:00"` | Morning |
| 12:00 PM | `"12:00:00"` | Noon |
| 7:00 PM | `"19:00:00"` | Evening |
| 11:59 PM | `"23:59:59"` | End of day |

### DateOnly Format

**Format:** `YYYY-MM-DD` (ISO 8601 date)

| Date | Format | Description |
|------|--------|-------------|
| Jan 15, 2026 | `"2026-01-15"` | January 15, 2026 |
| Feb 28, 2026 | `"2026-02-28"` | February 28, 2026 |
| Dec 31, 2026 | `"2026-12-31"` | December 31, 2026 |

## Update Schedule

### Update Date Only

```json
PUT /api/schedules/123

{
  "date": "2026-02-01"
}
```

Moves the schedule to Feb 1, keeping the same start/end times.

### Update Times Only

```json
PUT /api/schedules/123

{
  "startTime": "18:00:00",
  "endTime": "19:30:00"
}
```

Changes to 6:00 PM - 7:30 PM, keeping the same date.

### Update Both

```json
PUT /api/schedules/123

{
  "date": "2026-02-01",
  "startTime": "18:00:00",
  "endTime": "19:30:00"
}
```

Changes to Feb 1 at 6:00 PM - 7:30 PM.

## Validation Rules

### Date Validation
? `startDate` is required
? `recurrence.endDate` must be on or after `startDate` (for recurring)

### Time Validation
? `startTime` is required
? `endTime` is required
? `endTime` must be after `startTime`

### Recurrence Validation
? `frequency` required if `isRecurring` is true
? `endDate` required if `isRecurring` is true
? `daysOfWeek` required for Weekly and BiWeekly frequency

## Examples by Language

### cURL

```bash
curl -X POST https://localhost:7063/api/schedules \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sportId": 1,
    "venue": "Tennis Court A",
    "startDate": "2026-01-15",
    "startTime": "19:00:00",
    "endTime": "20:00:00",
    "maxPlayers": 8,
    "recurrence": {
      "isRecurring": true,
      "frequency": 2,
      "daysOfWeek": [3],
      "endDate": "2026-02-28"
    }
  }'
```

### PowerShell

```powershell
$token = "YOUR_ADMIN_TOKEN"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    sportId = 1
    venue = "Tennis Court A"
    startDate = "2026-01-15"
    startTime = "19:00:00"
    endTime = "20:00:00"
    maxPlayers = 8
    recurrence = @{
        isRecurring = $true
        frequency = 2
        daysOfWeek = @(3)  # Wednesday
        endDate = "2026-02-28"
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "https://localhost:7063/api/schedules" `
    -Method Post -Headers $headers -Body $body
```

### JavaScript/Fetch

```javascript
const response = await fetch('https://localhost:7063/api/schedules', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    sportId: 1,
    venue: 'Tennis Court A',
    startDate: '2026-01-15',
    startTime: '19:00:00',
    endTime: '20:00:00',
    maxPlayers: 8,
    recurrence: {
      isRecurring: true,
      frequency: 2,
      daysOfWeek: [3],  // Wednesday
      endDate: '2026-02-28'
    }
  })
});

const schedules = await response.json();
```

### C# / .NET

```csharp
var request = new CreateScheduleDto
{
    SportId = 1,
    Venue = "Tennis Court A",
    StartDate = new DateOnly(2026, 1, 15),
    StartTime = new TimeOnly(19, 0, 0),  // 7 PM
    EndTime = new TimeOnly(20, 0, 0),    // 8 PM
    MaxPlayers = 8,
    Recurrence = new RecurrenceDto
    {
        IsRecurring = true,
        Frequency = RecurrenceFrequency.Weekly,
        DaysOfWeek = new List<DayOfWeek> { DayOfWeek.Wednesday },
        EndDate = new DateOnly(2026, 2, 28)
    }
};
```

## Common Patterns

### Every Weekday Morning (Mon-Fri)

```json
{
  "startDate": "2026-01-05",
  "startTime": "06:00:00",
  "endTime": "07:00:00",
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [1, 2, 3, 4, 5],
    "endDate": "2026-12-31"
  }
}
```

### Weekend Evenings (Fri, Sat, Sun)

```json
{
  "startDate": "2026-01-03",
  "startTime": "18:00:00",
  "endTime": "20:00:00",
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [5, 6, 0],
    "endDate": "2026-12-31"
  }
}
```

### Twice a Week (Tue/Thu)

```json
{
  "startDate": "2026-01-06",
  "startTime": "19:00:00",
  "endTime": "21:00:00",
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [2, 4],
    "endDate": "2026-12-31"
  }
}
```

### Every Other Friday (BiWeekly)

```json
{
  "startDate": "2026-01-02",
  "startTime": "17:00:00",
  "endTime": "19:00:00",
  "recurrence": {
    "isRecurring": true,
    "frequency": 3,
    "daysOfWeek": [5],
    "endDate": "2026-12-31"
  }
}
```

## Error Responses

### Invalid Time Range

```json
{
  "message": "EndTime must be after StartTime"
}
```

**Cause:** `endTime` is not after `startTime`

**Solution:** Ensure `endTime` > `startTime`

### Invalid Date Range

```json
{
  "message": "Recurrence EndDate must be on or after StartDate"
}
```

**Cause:** `recurrence.endDate` is before `startDate`

**Solution:** Ensure `endDate` >= `startDate`

### Missing DaysOfWeek

```json
{
  "message": "DaysOfWeek is required for Weekly and BiWeekly recurrence"
}
```

**Cause:** Weekly/BiWeekly frequency without `daysOfWeek`

**Solution:** Specify at least one day in `daysOfWeek` array

## Migration from Old API

### Old Format
```json
{
  "startTime": "2026-01-15T19:00:00Z",
  "endTime": "2026-01-15T20:00:00Z"
}
```

### New Format
```json
{
  "startDate": "2026-01-15",
  "startTime": "19:00:00",
  "endTime": "20:00:00"
}
```

### Conversion Logic

**From DateTime to DateOnly/TimeOnly:**
```csharp
DateTime dt = DateTime.Parse("2026-01-15T19:00:00Z");
DateOnly date = DateOnly.FromDateTime(dt);      // 2026-01-15
TimeOnly time = TimeOnly.FromDateTime(dt);      // 19:00:00
```

**From DateOnly/TimeOnly to DateTime:**
```csharp
DateOnly date = new DateOnly(2026, 1, 15);
TimeOnly time = new TimeOnly(19, 0, 0);
DateTime dt = date.ToDateTime(time);            // 2026-01-15T19:00:00
```

## Best Practices

### ? DO:

- Use 24-hour time format (19:00:00 for 7 PM)
- Use ISO date format (YYYY-MM-DD)
- Validate time ranges before submission
- Keep time consistent across recurring schedules
- Specify realistic date ranges for recurring schedules

### ? DON'T:

- Mix date and time in a single field
- Use 12-hour format (7:00 PM) - use 24-hour (19:00:00)
- Create overlapping schedules for the same venue
- Set `endTime` before or equal to `startTime`
- Forget to specify `daysOfWeek` for Weekly/BiWeekly

## Summary

The refined Schedule API provides:
- ? **Clear Separation** - Date and time are separate concerns
- ? **Intuitive** - Matches how people think about schedules
- ? **Flexible** - Same time across different dates
- ? **Type-Safe** - Uses .NET DateOnly and TimeOnly types
- ? **Better Validation** - Validates dates and times independently
- ? **Easy Updates** - Change date or time independently

**Your use case (7 PM - 8 PM every Wednesday) is now more intuitive to express!** ??
