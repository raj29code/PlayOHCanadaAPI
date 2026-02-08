# Recurring Schedule Feature - Complete Guide

## Overview

The Schedule API now supports creating recurring schedules with flexible patterns. Admins can create schedules that repeat daily, weekly (on specific days), bi-weekly, or monthly.

## Use Case Example

**Scenario:** Create a tennis schedule that occurs every Thursday from 7 PM to 10 PM, from January 1, 2026, to February 1, 2026.

## API Endpoint

### POST `/api/schedules`

**Authentication:** Required (Admin only)

**Request Body:**

```json
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

**Response:** Array of created schedules (201 Created)

```json
[
  {
    "id": 101,
    "sportId": 1,
    "venue": "Central Park Tennis Court",
    "startTime": "2026-01-02T19:00:00Z",
    "endTime": "2026-01-02T22:00:00Z",
    "maxPlayers": 8,
    "equipmentDetails": "Bring your own racket",
    "createdByAdminId": 1
  },
  {
    "id": 102,
    "sportId": 1,
    "venue": "Central Park Tennis Court",
    "startTime": "2026-01-09T19:00:00Z",
    "endTime": "2026-01-09T22:00:00Z",
    "maxPlayers": 8,
    "equipmentDetails": "Bring your own racket",
    "createdByAdminId": 1
  }
  // ... more schedules for each Thursday until Feb 1, 2026
]
```

## Recurrence Options

### 1. Daily Recurrence

Creates a schedule every day within the date range.

```json
{
  "sportId": 1,
  "venue": "Morning Yoga Studio",
  "startTime": "2026-01-01T06:00:00Z",
  "endTime": "2026-01-01T07:00:00Z",
  "maxPlayers": 20,
  "recurrence": {
    "isRecurring": true,
    "frequency": 1,
    "endDate": "2026-01-31T23:59:59Z"
  }
}
```

**Result:** Creates 31 schedules (one for each day in January 2026)

### 2. Weekly Recurrence (Specific Days)

Creates schedules on specific days of the week.

**Days of Week Mapping:**
- Sunday = 0
- Monday = 1
- Tuesday = 2
- Wednesday = 3
- Thursday = 4
- Friday = 5
- Saturday = 6

**Example: Every Monday, Wednesday, and Friday**

```json
{
  "sportId": 2,
  "venue": "Basketball Court A",
  "startTime": "2026-01-01T18:00:00Z",
  "endTime": "2026-01-01T20:00:00Z",
  "maxPlayers": 10,
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "endDate": "2026-01-31T23:59:59Z",
    "daysOfWeek": [1, 3, 5]
  }
}
```

**Result:** Creates schedules for every Mon, Wed, Fri in January 2026

**Example: Weekend Only (Saturday and Sunday)**

```json
{
  "sportId": 3,
  "venue": "Community Soccer Field",
  "startTime": "2026-01-04T10:00:00Z",
  "endTime": "2026-01-04T12:00:00Z",
  "maxPlayers": 22,
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "endDate": "2026-02-28T23:59:59Z",
    "daysOfWeek": [0, 6]
  }
}
```

**Result:** Creates schedules for every Sat & Sun in Jan-Feb 2026

### 3. BiWeekly Recurrence

Creates schedules every two weeks on specified days.

**Example: Every other Thursday**

```json
{
  "sportId": 1,
  "venue": "Tennis Court B",
  "startTime": "2026-01-01T19:00:00Z",
  "endTime": "2026-01-01T21:00:00Z",
  "maxPlayers": 4,
  "recurrence": {
    "isRecurring": true,
    "frequency": 3,
    "endDate": "2026-06-30T23:59:59Z",
    "daysOfWeek": [4]
  }
}
```

**Result:** Creates schedules every other Thursday for 6 months

### 4. Monthly Recurrence

Creates schedules on the same day of each month.

**Example: 15th of every month**

```json
{
  "sportId": 4,
  "venue": "Volleyball Court",
  "startTime": "2026-01-15T18:00:00Z",
  "endTime": "2026-01-15T20:00:00Z",
  "maxPlayers": 12,
  "recurrence": {
    "isRecurring": true,
    "frequency": 4,
    "endDate": "2026-12-31T23:59:59Z"
  }
}
```

**Result:** Creates 12 schedules (one on the 15th of each month)

**Note:** For months with fewer days (e.g., February 30th), the system automatically adjusts to the last day of that month.

## Frequency Types

| Value | Frequency | Description |
|-------|-----------|-------------|
| 1 | Daily | Every day |
| 2 | Weekly | Specific days of the week (requires `daysOfWeek`) |
| 3 | BiWeekly | Every two weeks on specific days |
| 4 | Monthly | Same day each month |

## Validation Rules

### Required Fields
- ? `sportId` - Must exist in the database
- ? `venue` - 3-200 characters
- ? `startTime` - Must be a valid datetime
- ? `endTime` - Must be after `startTime`
- ? `maxPlayers` - 1-100

### Recurrence Validation
When `isRecurring` is `true`:
- ? `frequency` is required
- ? `endDate` is required and must be after `startTime`
- ? `daysOfWeek` is required for Weekly (frequency = 2)
- ? At least one schedule must be generated

## Complete Examples

### Example 1: Tennis Every Thursday Evening

**Scenario:** Tennis from 7-10 PM every Thursday for 2 months

```bash
curl -X POST https://localhost:7063/api/schedules \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sportId": 1,
    "venue": "Downtown Tennis Center",
    "startTime": "2026-01-01T19:00:00Z",
    "endTime": "2026-01-01T22:00:00Z",
    "maxPlayers": 8,
    "equipmentDetails": "Rackets available for rent",
    "recurrence": {
      "isRecurring": true,
      "frequency": 2,
      "endDate": "2026-02-28T23:59:59Z",
      "daysOfWeek": [4]
    }
  }'
```

### Example 2: Morning Yoga Every Weekday

**Scenario:** Yoga from 6-7 AM Monday through Friday for January

```bash
curl -X POST https://localhost:7063/api/schedules \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sportId": 5,
    "venue": "Wellness Studio",
    "startTime": "2026-01-01T06:00:00Z",
    "endTime": "2026-01-01T07:00:00Z",
    "maxPlayers": 20,
    "equipmentDetails": "Bring your own mat",
    "recurrence": {
      "isRecurring": true,
      "frequency": 2,
      "endDate": "2026-01-31T23:59:59Z",
      "daysOfWeek": [1, 2, 3, 4, 5]
    }
  }'
```

### Example 3: Weekend Soccer Games

**Scenario:** Soccer every Saturday and Sunday morning for 3 months

```bash
curl -X POST https://localhost:7063/api/schedules \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sportId": 4,
    "venue": "City Park Field 3",
    "startTime": "2026-01-03T09:00:00Z",
    "endTime": "2026-01-03T11:00:00Z",
    "maxPlayers": 22,
    "equipmentDetails": "Shin guards required",
    "recurrence": {
      "isRecurring": true,
      "frequency": 2,
      "endDate": "2026-03-31T23:59:59Z",
      "daysOfWeek": [0, 6]
    }
  }'
```

### Example 4: Monthly Tournament

**Scenario:** Tournament on the first Saturday of each month

```bash
curl -X POST https://localhost:7063/api/schedules \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sportId": 2,
    "venue": "Championship Arena",
    "startTime": "2026-01-03T10:00:00Z",
    "endTime": "2026-01-03T16:00:00Z",
    "maxPlayers": 32,
    "equipmentDetails": "Tournament format, bring ID",
    "recurrence": {
      "isRecurring": true,
      "frequency": 4,
      "endDate": "2026-12-31T23:59:59Z"
    }
  }'
```

### Example 5: Single Schedule (No Recurrence)

**Scenario:** One-time special event

```bash
curl -X POST https://localhost:7063/api/schedules \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sportId": 6,
    "venue": "Grand Stadium",
    "startTime": "2026-07-04T14:00:00Z",
    "endTime": "2026-07-04T18:00:00Z",
    "maxPlayers": 100,
    "equipmentDetails": "July 4th Special Event"
  }'
```

## PowerShell Examples

### Create Weekly Thursday Schedule

```powershell
$token = "YOUR_ADMIN_TOKEN"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    sportId = 1
    venue = "Tennis Court A"
    startTime = "2026-01-01T19:00:00Z"
    endTime = "2026-01-01T22:00:00Z"
    maxPlayers = 8
    equipmentDetails = "BYOR - Bring Your Own Racket"
    recurrence = @{
        isRecurring = $true
        frequency = 2
        endDate = "2026-02-01T23:59:59Z"
        daysOfWeek = @(4)  # Thursday
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://localhost:7063/api/schedules" `
    -Method Post `
    -Headers $headers `
    -Body $body
```

### Create Daily Morning Workout

```powershell
$body = @{
    sportId = 5
    venue = "Fitness Center"
    startTime = "2026-01-01T06:00:00Z"
    endTime = "2026-01-01T07:00:00Z"
    maxPlayers = 15
    recurrence = @{
        isRecurring = $true
        frequency = 1  # Daily
        endDate = "2026-01-31T23:59:59Z"
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://localhost:7063/api/schedules" `
    -Method Post `
    -Headers $headers `
    -Body $body
```

## Response Handling

### Success Response (201 Created)

```json
[
  {
    "id": 101,
    "sportId": 1,
    "venue": "Tennis Court A",
    "startTime": "2026-01-02T19:00:00Z",
    "endTime": "2026-01-02T22:00:00Z",
    "maxPlayers": 8,
    "currentPlayers": 0,
    "spotsRemaining": 8,
    "equipmentDetails": "BYOR",
    "createdByAdminId": 1
  },
  // ... additional schedules
]
```

### Error Responses

**400 Bad Request - Invalid Sport**
```json
{
  "message": "Invalid SportId"
}
```

**400 Bad Request - Invalid Times**
```json
{
  "message": "EndTime must be after StartTime"
}
```

**400 Bad Request - Missing Frequency**
```json
{
  "message": "Frequency is required for recurring schedules"
}
```

**400 Bad Request - Missing Days for Weekly**
```json
{
  "message": "DaysOfWeek is required for Weekly recurrence"
}
```

**400 Bad Request - No Schedules Generated**
```json
{
  "message": "No schedules were generated. Please check your recurrence settings."
}
```

**401 Unauthorized**
```json
{
  "message": "Unauthorized"
}
```

**403 Forbidden - Not Admin**
```json
{
  "message": "User does not have the required role"
}
```

## Best Practices

### 1. Date Selection
- Use UTC times for consistency
- Ensure `endDate` is realistic (not too far in the future)
- Consider venue availability before creating recurring schedules

### 2. Weekly Schedules
- Always specify `daysOfWeek` for weekly recurrence
- Use Sunday=0, Monday=1, ..., Saturday=6
- Can specify multiple days: `[1, 3, 5]` for Mon, Wed, Fri

### 3. Managing Large Recurrences
- Daily schedules for a year create 365 entries
- Consider using Weekly instead of Daily when possible
- Monitor database size with long-running recurring schedules

### 4. Updating Recurring Schedules
- Updates affect individual schedules, not the series
- To modify a series, delete and recreate
- Consider impact on existing bookings

### 5. Deleting Recurring Schedules
- Each schedule can be deleted individually
- To delete a series, filter by criteria and delete multiple
- Existing bookings are cascade deleted (notify users!)

## Common Use Cases

### Fitness Classes
```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [1, 3, 5],  // Mon, Wed, Fri
    "endDate": "2026-12-31T23:59:59Z"
  }
}
```

### Weekend Tournaments
```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 2,
    "daysOfWeek": [6],  // Saturday
    "endDate": "2026-06-30T23:59:59Z"
  }
}
```

### Monthly Meetups
```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 4,  // Monthly
    "endDate": "2026-12-31T23:59:59Z"
  }
}
```

### Summer Camp (Daily for 8 weeks)
```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 1,  // Daily
    "endDate": "2026-08-30T23:59:59Z"
  }
}
```

## Troubleshooting

### Issue: No schedules created
**Cause:** Date range too small or `daysOfWeek` doesn't match any days in range
**Solution:** Verify date range includes at least one occurrence of specified days

### Issue: Too many schedules created
**Cause:** Daily frequency with large date range
**Solution:** Use Weekly frequency with specific days instead

### Issue: February 30th doesn't exist
**Cause:** Monthly recurrence on day 30 or 31
**Solution:** System automatically adjusts to last day of month

### Issue: Wrong timezone
**Cause:** Not using UTC times
**Solution:** Always use UTC (Z) timezone in ISO format

## Summary

The recurring schedule feature supports:
- ? Daily, Weekly, BiWeekly, and Monthly patterns
- ? Specific days of the week selection
- ? Flexible date ranges
- ? Single or multiple schedules creation
- ? Complete validation and error handling
- ? Admin-only access for schedule creation

This enables comprehensive schedule management for sports facilities, fitness centers, and recreational activities!
