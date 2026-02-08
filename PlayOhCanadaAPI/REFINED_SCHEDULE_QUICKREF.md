# Refined Schedule API - Quick Reference

## Key Concept: Date and Time Separation

**Before:** Combined date and time
```json
"startTime": "2026-01-15T19:00:00Z"
```

**After:** Separated date and time
```json
"startDate": "2026-01-15",
"startTime": "19:00:00"
```

## Your Use Case: Every Wednesday 7-8 PM

```json
POST /api/schedules

{
  "sportId": 1,
  "venue": "Tennis Court A",
  "startDate": "2026-01-07",      // First Wednesday
  "startTime": "19:00:00",        // 7 PM
  "endTime": "20:00:00",          // 8 PM
  "maxPlayers": 8,
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,               // Weekly
    "daysOfWeek": [3],           // Wednesday
    "endDate": "2026-02-28"      // Until Feb 28
  }
}
```

## Time Format Quick Reference

| Description | Format |
|-------------|--------|
| 7:00 AM | `"07:00:00"` |
| 12:00 PM (Noon) | `"12:00:00"` |
| 7:00 PM | `"19:00:00"` |
| 8:00 PM | `"20:00:00"` |
| 11:59 PM | `"23:59:59"` |

## Date Format

**Always use:** `YYYY-MM-DD`

Examples:
- `"2026-01-15"` - January 15, 2026
- `"2026-02-28"` - February 28, 2026
- `"2026-12-31"` - December 31, 2026

## Day of Week Numbers

- 0 = Sunday
- 1 = Monday
- 2 = Tuesday
- 3 = Wednesday ? Your use case
- 4 = Thursday
- 5 = Friday
- 6 = Saturday

## Common Patterns

### Every Weekday Morning
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

### Weekend Evenings
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

### Monthly on 15th
```json
{
  "startDate": "2026-01-15",
  "startTime": "10:00:00",
  "endTime": "16:00:00",
  "recurrence": {
    "isRecurring": true,
    "frequency": 4,
    "endDate": "2026-12-31"
  }
}
```

## Update Operations

### Change Only Time
```json
PUT /api/schedules/123
{
  "startTime": "18:00:00",
  "endTime": "19:30:00"
}
```

### Change Only Date
```json
PUT /api/schedules/123
{
  "date": "2026-02-01"
}
```

### Change Both
```json
PUT /api/schedules/123
{
  "date": "2026-02-01",
  "startTime": "18:00:00",
  "endTime": "19:30:00"
}
```

## Validation

? `endTime` must be after `startTime`
? `recurrence.endDate` must be on or after `startDate`
? `daysOfWeek` required for Weekly/BiWeekly

## Benefits

? **Clearer** - Separate what day from what time
? **Consistent** - Same time (7-8 PM) across all dates
? **Flexible** - Update date or time independently
? **Intuitive** - Matches how people think

## Test It

```powershell
.\test-refined-schedules.ps1
```

## Documentation

- **Complete Guide:** [REFINED_SCHEDULE_API_GUIDE.md](REFINED_SCHEDULE_API_GUIDE.md)
- **README:** [README.md](README.md)

---

**Your use case is now clearer and easier to express!** ???
