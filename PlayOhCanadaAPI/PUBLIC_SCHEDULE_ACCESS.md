# Public Schedule Access for Non-Admin Users

## Overview

The GET schedule endpoints are **publicly accessible** to all users (both authenticated and non-authenticated), allowing everyone to view available schedules and join them.

## Current Status ?

**GET endpoints are already public** - No authentication required!

- ? `GET /api/schedules` - List all schedules
- ? `GET /api/schedules/{id}` - Get specific schedule details

## Key Features

### 1. Public Access
- **No authentication required** - Anyone can view schedules
- **No admin privileges needed** - Regular users can see all schedules
- **Guest access** - Even non-registered users can browse

### 2. Comprehensive Information
Each schedule shows:
- Sport name and icon
- Venue location
- Date and time (with timezone support)
- **Current player count**
- **Maximum players**
- **Spots remaining** (available slots)
- Equipment details
- Participant list (optional)

### 3. Powerful Filtering
Users can filter by:
- Sport (e.g., Tennis, Basketball)
- Venue (e.g., "Court A")
- Date range (start/end dates)
- **Available spots only** (new!)
- Timezone (for correct time display)

## New Feature: Available Spots Filter

### availableOnly Parameter

Added a new `availableOnly` query parameter to show only schedules with open spots.

**Usage:**
```
GET /api/schedules?availableOnly=true
```

**Result:** Returns only schedules where `spotsRemaining > 0`

## API Reference

### GET /api/schedules

**Authentication:** None required (public endpoint)

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `sportId` | int | No | Filter by sport ID |
| `venue` | string | No | Filter by venue name (partial match) |
| `startDate` | DateTime | No | Show schedules starting from this date |
| `endDate` | DateTime | No | Show schedules up to this date |
| `timezoneOffsetMinutes` | int | No | Timezone offset for time conversion |
| `includeParticipants` | bool | No | Include participant list (default: false) |
| `availableOnly` | bool | No | Show only schedules with available spots (default: false) |

**Response:**
```json
[
  {
    "id": 123,
    "sportId": 1,
    "sportName": "Tennis",
    "sportIconUrl": "https://...",
    "venue": "Tennis Court A",
    "startTime": "2026-01-29T19:00:00",
    "endTime": "2026-01-29T20:00:00",
    "maxPlayers": 8,
    "currentPlayers": 5,
    "spotsRemaining": 3,
    "equipmentDetails": "Bring your own racket",
    "participants": []
  }
]
```

### GET /api/schedules/{id}

**Authentication:** None required (public endpoint)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | int | Yes | Schedule ID |

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `timezoneOffsetMinutes` | int | No | Timezone offset for time conversion |

**Response:**
```json
{
  "id": 123,
  "sportId": 1,
  "sportName": "Tennis",
  "sportIconUrl": "https://...",
  "venue": "Tennis Court A",
  "startTime": "2026-01-29T19:00:00",
  "endTime": "2026-01-29T20:00:00",
  "maxPlayers": 8,
  "currentPlayers": 5,
  "spotsRemaining": 3,
  "equipmentDetails": "Bring your own racket",
  "participants": [
    {
      "name": "John Doe",
      "bookingTime": "2026-01-28T10:00:00"
    }
  ]
}
```

## Usage Examples

### Example 1: Browse All Available Schedules

**Scenario:** User wants to see all schedules they can join

```javascript
// No authentication needed!
const response = await fetch('/api/schedules?availableOnly=true');
const schedules = await response.json();

schedules.forEach(schedule => {
  console.log(`${schedule.sportName} at ${schedule.venue}`);
  console.log(`${schedule.spotsRemaining} spots available`);
});
```

### Example 2: Find Tennis Courts with Open Spots

**Scenario:** User looking for tennis games to join

```javascript
const sportId = 1; // Tennis
const offset = -new Date().getTimezoneOffset(); // User's timezone

const response = await fetch(
  `/api/schedules?sportId=${sportId}&availableOnly=true&timezoneOffsetMinutes=${offset}`
);

const tennisSchedules = await response.json();
```

### Example 3: View Schedule Details Before Joining

**Scenario:** User wants to see who's playing before joining

```javascript
const scheduleId = 123;

const response = await fetch(`/api/schedules/${scheduleId}`);
const schedule = await response.json();

console.log(`${schedule.currentPlayers}/${schedule.maxPlayers} players`);
console.log('Participants:', schedule.participants);

if (schedule.spotsRemaining > 0) {
  console.log('You can join this schedule!');
}
```

### Example 4: Guest User Browsing Schedules

**Scenario:** Non-registered user browsing schedules

```javascript
// No token needed - guest access!
async function browseSchedules() {
  const response = await fetch('/api/schedules?availableOnly=true');
  const schedules = await response.json();
  
  // Display schedules to guest user
  displaySchedulesToGuest(schedules);
  
  // Prompt to register/login to join
  showRegisterPrompt();
}
```

## Use Cases

### 1. Public Schedule Board

Display all available schedules on a public page:

```javascript
async function loadPublicSchedules() {
  const offset = -new Date().getTimezoneOffset();
  
  const response = await fetch(
    `/api/schedules?availableOnly=true&timezoneOffsetMinutes=${offset}`
  );
  
  const schedules = await response.json();
  
  return schedules.map(s => ({
    sport: s.sportName,
    venue: s.venue,
    time: new Date(s.startTime).toLocaleString(),
    available: s.spotsRemaining,
    canJoin: s.spotsRemaining > 0
  }));
}
```

### 2. Sport-Specific Listings

Show schedules for a specific sport:

```javascript
async function getTennisSchedules() {
  const response = await fetch(
    '/api/schedules?sportId=1&availableOnly=true'
  );
  
  return await response.json();
}
```

### 3. Venue-Based View

Find schedules at a specific venue:

```javascript
async function getVenueSchedules(venueName) {
  const response = await fetch(
    `/api/schedules?venue=${encodeURIComponent(venueName)}&availableOnly=true`
  );
  
  return await response.json();
}
```

### 4. Date Range Filter

Show schedules for this week:

```javascript
async function getWeekSchedules() {
  const today = new Date().toISOString().split('T')[0];
  const nextWeek = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    .toISOString().split('T')[0];
  
  const response = await fetch(
    `/api/schedules?startDate=${today}&endDate=${nextWeek}&availableOnly=true`
  );
  
  return await response.json();
}
```

## Benefits for Non-Admin Users

### ? Easy Discovery
- Browse all available schedules without registration
- Filter by sport, venue, or date
- See real-time availability

### ? Informed Decisions
- View current player count
- See who else is joining (participant list)
- Check equipment requirements
- Know exact times in local timezone

### ? No Barriers
- No authentication required for browsing
- Register only when ready to join
- Guest-friendly interface

### ? Complete Information
```json
{
  "spotsRemaining": 3,  // Know availability
  "currentPlayers": 5,   // See how popular it is
  "maxPlayers": 8,       // Know total capacity
  "participants": [...]  // See who's playing
}
```

## Frontend Integration

### React Example

```jsx
function ScheduleList() {
  const [schedules, setSchedules] = useState([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    async function loadSchedules() {
      const offset = -new Date().getTimezoneOffset();
      
      const response = await fetch(
        `/api/schedules?availableOnly=true&timezoneOffsetMinutes=${offset}`
      );
      
      const data = await response.json();
      setSchedules(data);
      setLoading(false);
    }
    
    loadSchedules();
  }, []);
  
  if (loading) return <div>Loading schedules...</div>;
  
  return (
    <div>
      <h2>Available Schedules</h2>
      {schedules.map(schedule => (
        <div key={schedule.id}>
          <h3>{schedule.sportName} at {schedule.venue}</h3>
          <p>{new Date(schedule.startTime).toLocaleString()}</p>
          <p>{schedule.spotsRemaining} spots available</p>
          <button>Join Schedule</button>
        </div>
      ))}
    </div>
  );
}
```

### Vue Example

```vue
<template>
  <div>
    <h2>Available Schedules</h2>
    <div v-for="schedule in schedules" :key="schedule.id">
      <h3>{{ schedule.sportName }} at {{ schedule.venue }}</h3>
      <p>{{ formatTime(schedule.startTime) }}</p>
      <p>{{ schedule.spotsRemaining }} spots available</p>
      <button @click="joinSchedule(schedule.id)">Join</button>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      schedules: []
    };
  },
  async mounted() {
    const offset = -new Date().getTimezoneOffset();
    
    const response = await fetch(
      `/api/schedules?availableOnly=true&timezoneOffsetMinutes=${offset}`
    );
    
    this.schedules = await response.json();
  },
  methods: {
    formatTime(dateTime) {
      return new Date(dateTime).toLocaleString();
    },
    joinSchedule(id) {
      // Redirect to login if not authenticated
      // Or directly join if authenticated
    }
  }
};
</script>
```

## Filtering Combinations

### Common Filter Combinations

**1. Available Tennis Courts Today:**
```
GET /api/schedules?sportId=1&startDate=2026-01-29&availableOnly=true
```

**2. All Sports at Specific Venue:**
```
GET /api/schedules?venue=Community Center&availableOnly=true
```

**3. Next Week's Available Schedules:**
```
GET /api/schedules?startDate=2026-02-01&endDate=2026-02-07&availableOnly=true
```

**4. Basketball Games with Participants:**
```
GET /api/schedules?sportId=3&includeParticipants=true&availableOnly=true
```

## Response Fields Explained

### Key Fields for Users

| Field | Type | Description | User Benefit |
|-------|------|-------------|--------------|
| `spotsRemaining` | int | Open slots | Know if can join |
| `currentPlayers` | int | Players joined | See popularity |
| `maxPlayers` | int | Total capacity | Know group size |
| `startTime` | DateTime | When it starts | Plan arrival |
| `endTime` | DateTime | When it ends | Plan schedule |
| `equipmentDetails` | string | What to bring | Come prepared |
| `participants` | array | Who's playing | Know the group |

## Security & Privacy

### What's Public
? Schedule times and venues
? Available spots count
? Sport information
? Current player count

### What's Protected
?? To **join** schedules - Authentication required
?? To **create** schedules - Admin only
?? To **modify** schedules - Admin only
?? To **delete** schedules - Admin only

### Participant Privacy
- Participant names are shown in the list
- Full participant details require authentication (when booking)
- Users consent to name display when joining

## PowerShell Example

```powershell
# Browse available schedules (no authentication needed)
$offset = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)

$schedules = Invoke-RestMethod -Uri "https://localhost:7063/api/schedules?availableOnly=true&timezoneOffsetMinutes=$offset"

# Display schedules
foreach ($schedule in $schedules) {
    Write-Host "$($schedule.sportName) at $($schedule.venue)" -ForegroundColor Cyan
    Write-Host "  Time: $($schedule.startTime)"
    Write-Host "  Available: $($schedule.spotsRemaining)/$($schedule.maxPlayers) spots" -ForegroundColor Green
    Write-Host ""
}
```

## Summary

### Current Status

? **GET endpoints are public** - No authentication required  
? **All users can view schedules** - Including non-admin users  
? **Complete schedule information** - Spots, times, participants  
? **Powerful filtering** - Sport, venue, date, availability  
? **New availableOnly filter** - Show only joinable schedules  

### What Non-Admin Users Can Do

? **Browse all schedules** without logging in  
? **View schedule details** including availability  
? **See participant lists** (who's playing)  
? **Filter schedules** by multiple criteria  
? **Check equipment needs** before joining  
? **View times in local timezone** automatically  

### What Requires Authentication

?? **Join schedules** - POST /api/bookings/join  
?? **Leave schedules** - POST /api/bookings/leave/{id}  
?? **View my bookings** - GET /api/bookings/my-bookings  

### What Requires Admin

?? **Create schedules** - POST /api/schedules  
?? **Update schedules** - PUT /api/schedules/{id}  
?? **Delete schedules** - DELETE /api/schedules/{id}  

---

**The schedule GET endpoints are already fully accessible to all users, including non-admin users! No changes were needed - just enhanced documentation and added the helpful `availableOnly` filter.** ?????
