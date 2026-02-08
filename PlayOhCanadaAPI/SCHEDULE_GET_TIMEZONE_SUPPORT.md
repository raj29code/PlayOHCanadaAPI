# Schedule GET API - Timezone Support

## Overview

The schedule GET endpoints now support timezone conversion, allowing the UI to receive schedules in the user's local timezone without additional client-side conversion.

## What Changed

### Endpoints Updated

1. **GET `/api/schedules`** - List schedules with filters
2. **GET `/api/schedules/{id}`** - Get single schedule

### New Parameter

Both endpoints now accept an optional `timezoneOffsetMinutes` query parameter.

```
GET /api/schedules?timezoneOffsetMinutes=-300
GET /api/schedules/123?timezoneOffsetMinutes=-300
```

## How It Works

### Server-Side Conversion

**Without timezone parameter:**
- Returns times in UTC (as stored in database)

**With timezone parameter:**
- Converts UTC times to user's local timezone
- Adds the offset to both StartTime and EndTime

### Conversion Logic

```csharp
// If timezone offset provided, convert UTC to local
StartTime = timezoneOffsetMinutes.HasValue 
    ? schedule.StartTime.AddMinutes(timezoneOffsetMinutes.Value) 
    : schedule.StartTime;
```

## Usage Examples

### JavaScript/Frontend

```javascript
// Auto-detect user's timezone
const timezoneOffsetMinutes = -new Date().getTimezoneOffset();

// Get schedules in user's local timezone
const response = await fetch(
  `/api/schedules?sportId=1&timezoneOffsetMinutes=${timezoneOffsetMinutes}`
);

const schedules = await response.json();
// StartTime and EndTime are now in user's local timezone
```

### PowerShell

```powershell
# Get current timezone offset
$timezoneOffsetMinutes = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)

# Get schedules with timezone conversion
$schedules = Invoke-RestMethod `
    -Uri "https://localhost:7063/api/schedules?sportId=1&timezoneOffsetMinutes=$timezoneOffsetMinutes" `
    -Method Get
```

### cURL

```bash
# For EST (UTC-5)
curl "https://localhost:7063/api/schedules?sportId=1&timezoneOffsetMinutes=-300"

# For PST (UTC-8)
curl "https://localhost:7063/api/schedules?sportId=1&timezoneOffsetMinutes=-480"
```

## Example Scenarios

### Scenario 1: User in EST

**Request:**
```
GET /api/schedules?sportId=1&timezoneOffsetMinutes=-300
```

**Database (UTC):**
- StartTime: `2026-01-30 00:00:00 UTC`

**Response (EST):**
- StartTime: `2026-01-29 19:00:00 EST`

### Scenario 2: User in PST

**Request:**
```
GET /api/schedules?sportId=1&timezoneOffsetMinutes=-480
```

**Database (UTC):**
- StartTime: `2026-01-30 00:00:00 UTC`

**Response (PST):**
- StartTime: `2026-01-29 16:00:00 PST`

### Scenario 3: No Timezone Parameter

**Request:**
```
GET /api/schedules?sportId=1
```

**Response (UTC):**
- StartTime: `2026-01-30 00:00:00 UTC`
- Times returned as stored (UTC)

## Summary

### What Was Added

? **Optional `timezoneOffsetMinutes` parameter** to both GET endpoints  
? **Server-side timezone conversion** for StartTime and EndTime  
? **Backward compatible** - Works with or without parameter  
? **Consistent with POST API** - Same parameter name and logic  

### Benefits

? **Simpler frontend code** - No client-side conversion  
? **Accurate times** - Server handles conversion  
? **Better UX** - Users see local times  
? **Consistent API** - Same pattern for GET and POST  

### Usage

```javascript
// Simple usage
const offset = -new Date().getTimezoneOffset();
const schedules = await fetch(`/api/schedules?timezoneOffsetMinutes=${offset}`);
```

**Now your UI can display schedules in the user's local timezone without any client-side conversion!** ???
