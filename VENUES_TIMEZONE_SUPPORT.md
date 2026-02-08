# Venues Endpoint - Timezone Support Update

## Overview

The venues endpoint now includes timezone support, consistent with other schedule endpoints. Users can now see the next scheduled event time in their local timezone.

## What Changed

### Added Parameter

**timezoneOffsetMinutes (optional):**
- Converts UTC times to user's local timezone
- Same parameter used across all schedule endpoints
- Makes the API consistent

### Added Response Field

**nextScheduleTime:**
- Shows when the next event starts at this venue
- Automatically converted to user's timezone if offset provided
- Helps users make quick decisions

## Updated Endpoint

### GET /api/schedules/venues

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `timezoneOffsetMinutes` | int | No | Timezone offset for time conversion | `-300` (EST) |

**Response:**
```json
[
  {
    "name": "Tennis Court A",
    "scheduleCount": 15,
    "availableSchedules": 12,
    "sports": ["Tennis", "Pickleball"],
    "nextScheduleTime": "2026-01-29T19:00:00"
  }
]
```

## Usage Examples

### Without Timezone (UTC)

```javascript
const venues = await fetch('/api/schedules/venues').then(r => r.json());

// nextScheduleTime is in UTC
console.log(venues[0].nextScheduleTime); // "2026-01-30T00:00:00Z"
```

### With Timezone (Local Time)

```javascript
// Auto-detect user's timezone
const offset = -new Date().getTimezoneOffset();

const venues = await fetch(
  `/api/schedules/venues?timezoneOffsetMinutes=${offset}`
).then(r => r.json());

// nextScheduleTime is in user's local timezone
console.log(venues[0].nextScheduleTime); // "2026-01-29T19:00:00" (EST)
```

### Complete Example

```javascript
async function displayVenuesWithLocalTimes() {
  const offset = -new Date().getTimezoneOffset();
  
  const venues = await fetch(
    `/api/schedules/venues?timezoneOffsetMinutes=${offset}`
  ).then(r => r.json());
  
  venues.forEach(venue => {
    const nextEvent = new Date(venue.nextScheduleTime);
    
    console.log(`${venue.name}:`);
    console.log(`  Next event: ${nextEvent.toLocaleString()}`);
    console.log(`  ${venue.availableSchedules} schedules available`);
    console.log(`  Sports: ${venue.sports.join(', ')}`);
  });
}
```

## Response Format

### Before (Without Timezone)

```json
{
  "name": "Tennis Court A",
  "scheduleCount": 15,
  "availableSchedules": 12,
  "sports": ["Tennis"],
  "nextScheduleTime": "2026-01-30T00:00:00Z"
}
```

### After (With Timezone: EST, offset -300)

```json
{
  "name": "Tennis Court A",
  "scheduleCount": 15,
  "availableSchedules": 12,
  "sports": ["Tennis"],
  "nextScheduleTime": "2026-01-29T19:00:00"
}
```

**The time is automatically converted from UTC to EST!**

## Benefits

### For Users

? **See local times** - No mental conversion needed  
? **Quick decisions** - Know when next event starts  
? **Better UX** - Times in familiar format  
? **Consistent** - Same timezone handling everywhere  

### For Developers

? **Consistent API** - Same pattern across endpoints  
? **Easy integration** - Works like schedule endpoints  
? **Automatic conversion** - Server handles it  
? **Backward compatible** - Optional parameter  

## Common Timezone Offsets

| Timezone | Standard | Daylight | Usage |
|----------|----------|----------|-------|
| EST/EDT | -300 | -240 | Eastern Time |
| CST/CDT | -360 | -300 | Central Time |
| MST/MDT | -420 | -360 | Mountain Time |
| PST/PDT | -480 | -420 | Pacific Time |

### Auto-Detection (Recommended)

```javascript
// JavaScript automatically handles DST
const offset = -new Date().getTimezoneOffset();

// Use in API call
const venues = await fetch(
  `/api/schedules/venues?timezoneOffsetMinutes=${offset}`
).then(r => r.json());
```

## Frontend Integration

### React Component

```jsx
function VenueList() {
  const [venues, setVenues] = useState([]);
  
  useEffect(() => {
    async function loadVenues() {
      // Auto-detect timezone
      const offset = -new Date().getTimezoneOffset();
      
      const response = await fetch(
        `/api/schedules/venues?timezoneOffsetMinutes=${offset}`
      );
      
      const data = await response.json();
      setVenues(data);
    }
    
    loadVenues();
  }, []);
  
  return (
    <div>
      {venues.map(venue => (
        <div key={venue.name}>
          <h3>{venue.name}</h3>
          <p>Next event: {new Date(venue.nextScheduleTime).toLocaleString()}</p>
          <p>{venue.availableSchedules} schedules available</p>
        </div>
      ))}
    </div>
  );
}
```

### Vue Component

```vue
<template>
  <div>
    <div v-for="venue in venues" :key="venue.name">
      <h3>{{ venue.name }}</h3>
      <p>Next event: {{ formatTime(venue.nextScheduleTime) }}</p>
      <p>{{ venue.availableSchedules }} schedules available</p>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return { venues: [] };
  },
  async mounted() {
    const offset = -new Date().getTimezoneOffset();
    
    const response = await fetch(
      `/api/schedules/venues?timezoneOffsetMinutes=${offset}`
    );
    
    this.venues = await response.json();
  },
  methods: {
    formatTime(dateTime) {
      return new Date(dateTime).toLocaleString();
    }
  }
};
</script>
```

## Use Cases

### Use Case 1: Quick Venue Overview

Show users when the next event is at each venue:

```javascript
async function showVenueOverview() {
  const offset = -new Date().getTimezoneOffset();
  const venues = await fetch(
    `/api/schedules/venues?timezoneOffsetMinutes=${offset}`
  ).then(r => r.json());
  
  venues.forEach(venue => {
    const hours = Math.round(
      (new Date(venue.nextScheduleTime) - Date.now()) / (1000 * 60 * 60)
    );
    
    console.log(`${venue.name}: Next event in ${hours} hours`);
  });
}
```

### Use Case 2: Sort by Next Event

Help users find venues with events starting soon:

```javascript
async function getVenuesByNextEvent() {
  const offset = -new Date().getTimezoneOffset();
  const venues = await fetch(
    `/api/schedules/venues?timezoneOffsetMinutes=${offset}`
  ).then(r => r.json());
  
  // Sort by next event time (soonest first)
  return venues.sort((a, b) => 
    new Date(a.nextScheduleTime) - new Date(b.nextScheduleTime)
  );
}
```

### Use Case 3: Filter by Time Range

Show venues with events in the next few hours:

```javascript
async function getVenuesWithSoonEvents(hoursAhead = 3) {
  const offset = -new Date().getTimezoneOffset();
  const venues = await fetch(
    `/api/schedules/venues?timezoneOffsetMinutes=${offset}`
  ).then(r => r.json());
  
  const cutoff = Date.now() + (hoursAhead * 60 * 60 * 1000);
  
  return venues.filter(venue => 
    new Date(venue.nextScheduleTime) <= cutoff
  );
}
```

## Testing

### PowerShell Test

```powershell
# Get current timezone offset
$offset = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)

# Get venues with timezone conversion
$venues = Invoke-RestMethod -Uri "https://localhost:7063/api/schedules/venues?timezoneOffsetMinutes=$offset"

# Display venues with local times
foreach ($venue in $venues) {
    Write-Host "$($venue.name)" -ForegroundColor Green
    Write-Host "  Next event: $($venue.nextScheduleTime)"
    Write-Host "  Available: $($venue.availableSchedules)/$($venue.scheduleCount)"
    Write-Host ""
}
```

### Browser Test

**Without timezone:**
```
https://localhost:7063/api/schedules/venues
```

**With timezone (EST):**
```
https://localhost:7063/api/schedules/venues?timezoneOffsetMinutes=-300
```

## Comparison: Before vs After

### Before Update

**Request:**
```
GET /api/schedules/venues
```

**Response:**
```json
{
  "name": "Tennis Court A",
  "scheduleCount": 15,
  "availableSchedules": 12,
  "sports": ["Tennis"]
}
```

**Missing:**
- ? No timezone support
- ? No next event time
- ? Users had to make separate calls

### After Update

**Request:**
```
GET /api/schedules/venues?timezoneOffsetMinutes=-300
```

**Response:**
```json
{
  "name": "Tennis Court A",
  "scheduleCount": 15,
  "availableSchedules": 12,
  "sports": ["Tennis"],
  "nextScheduleTime": "2026-01-29T19:00:00"
}
```

**Benefits:**
- ? Timezone conversion supported
- ? Next event time included
- ? Single API call for all info

## API Consistency

All schedule-related endpoints now support timezone conversion:

| Endpoint | Timezone Support | Parameter |
|----------|-----------------|-----------|
| GET /api/schedules | ? | `timezoneOffsetMinutes` |
| GET /api/schedules/{id} | ? | `timezoneOffsetMinutes` |
| **GET /api/schedules/venues** | ? | `timezoneOffsetMinutes` |
| POST /api/schedules | ? | `timezoneOffsetMinutes` |
| PUT /api/schedules/{id} | ? | `timezoneOffsetMinutes` |

**Consistent API design across all endpoints!** ?

## Backward Compatibility

? **Fully backward compatible**

**Old requests (without timezone) still work:**
```javascript
// Returns UTC times
const venues = await fetch('/api/schedules/venues').then(r => r.json());
```

**New requests (with timezone):**
```javascript
// Returns local times
const offset = -new Date().getTimezoneOffset();
const venues = await fetch(
  `/api/schedules/venues?timezoneOffsetMinutes=${offset}`
).then(r => r.json());
```

## Summary

### What Was Added

? **timezoneOffsetMinutes parameter** - Optional timezone conversion  
? **nextScheduleTime field** - Shows when next event starts  
? **Automatic timezone conversion** - Server handles it  
? **Consistent API** - Same as other endpoints  

### Benefits

? **Better UX** - Users see local times  
? **Quick decisions** - Know when next event is  
? **Consistent** - Same pattern everywhere  
? **Backward compatible** - Optional parameter  

### Usage

**Without timezone:**
```
GET /api/schedules/venues
? Returns UTC times
```

**With timezone:**
```
GET /api/schedules/venues?timezoneOffsetMinutes=-300
? Returns EST times
```

---

**Now the venues endpoint includes full timezone support, consistent with all other schedule endpoints!** ????
