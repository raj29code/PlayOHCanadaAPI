# Exclude Already-Joined Schedules Feature

## Overview

The schedules endpoint now supports filtering out schedules that the user has already joined, ensuring users only see schedules they can actually join.

## New Parameter

### excludeJoined

**Type:** `bool` (optional)  
**Default:** `false`  
**Requires:** Authentication  

When set to `true`, filters out schedules the user has already joined.

## Updated Endpoint

### GET /api/schedules

**Query Parameters:**

| Parameter | Type | Required | Auth Required | Description |
|-----------|------|----------|---------------|-------------|
| `sportId` | int | No | No | Filter by sport |
| `venue` | string | No | No | Filter by venue |
| `startDate` | DateTime | No | No | Filter by start date |
| `endDate` | DateTime | No | No | Filter by end date |
| `timezoneOffsetMinutes` | int | No | No | Timezone conversion |
| `includeParticipants` | bool | No | No | Include participant list |
| `availableOnly` | bool | No | No | Only schedules with open spots |
| **`excludeJoined`** | **bool** | **No** | **Yes** | **Exclude already-joined schedules** |

## Usage

### Before (Shows All Schedules)

```javascript
// User sees all schedules, including ones they've joined
const response = await fetch('/api/schedules?availableOnly=true', {
  headers: {
    'Authorization': `Bearer ${userToken}`
  }
});

// Returns schedules user has already joined too
```

### After (Excludes Joined Schedules)

```javascript
// User only sees schedules they haven't joined yet
const response = await fetch(
  '/api/schedules?availableOnly=true&excludeJoined=true',
  {
    headers: {
      'Authorization': `Bearer ${userToken}`
    }
  }
);

// Returns only schedules user can still join
```

## UI Integration

### Home Page - Available Schedules

```javascript
async function loadAvailableSchedules(userToken) {
  const offset = -new Date().getTimezoneOffset();
  
  // Build query parameters
  const params = new URLSearchParams({
    availableOnly: 'true',
    timezoneOffsetMinutes: offset
  });
  
  // Add excludeJoined if user is logged in
  if (userToken) {
    params.append('excludeJoined', 'true');
  }
  
  const response = await fetch(`/api/schedules?${params}`, {
    headers: userToken ? {
      'Authorization': `Bearer ${userToken}`
    } : {}
  });
  
  const schedules = await response.json();
  
  // Display schedules user can join
  displaySchedules(schedules);
}
```

### React Component

```jsx
function AvailableSchedules() {
  const [schedules, setSchedules] = useState([]);
  const { userToken } = useAuth();
  
  useEffect(() => {
    async function loadSchedules() {
      const offset = -new Date().getTimezoneOffset();
      const params = new URLSearchParams({
        availableOnly: 'true',
        timezoneOffsetMinutes: offset,
        excludeJoined: 'true'  // Only show schedules user hasn't joined
      });
      
      const response = await fetch(`/api/schedules?${params}`, {
        headers: {
          'Authorization': `Bearer ${userToken}`
        }
      });
      
      const data = await response.json();
      setSchedules(data);
    }
    
    if (userToken) {
      loadSchedules();
    }
  }, [userToken]);
  
  return (
    <div>
      <h2>Available Schedules</h2>
      {schedules.map(schedule => (
        <ScheduleCard 
          key={schedule.id} 
          schedule={schedule}
          showJoinButton={true}  // User hasn't joined these
        />
      ))}
    </div>
  );
}
```

### Vue Component

```vue
<template>
  <div>
    <h2>Available Schedules</h2>
    <div v-for="schedule in schedules" :key="schedule.id">
      <ScheduleCard 
        :schedule="schedule"
        :show-join-button="true"
      />
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
    await this.loadSchedules();
  },
  methods: {
    async loadSchedules() {
      const offset = -new Date().getTimezoneOffset();
      const params = new URLSearchParams({
        availableOnly: 'true',
        timezoneOffsetMinutes: offset,
        excludeJoined: 'true'
      });
      
      const response = await fetch(`/api/schedules?${params}`, {
        headers: {
          'Authorization': `Bearer ${this.$store.state.userToken}`
        }
      });
      
      this.schedules = await response.json();
    }
  }
};
</script>
```

## How It Works

### Backend Logic

1. **User makes request** with `excludeJoined=true`
2. **Check authentication** - Must be logged in
3. **Get user's bookings** - Query all schedules user has joined
4. **Filter schedules** - Exclude already-joined schedules
5. **Return filtered list** - Only schedules user can join

### Database Query

```csharp
// Get schedule IDs user has already joined
var joinedScheduleIds = await _context.Bookings
    .Where(b => b.UserId == userId)
    .Select(b => b.ScheduleId)
    .ToListAsync();

// Filter out already-joined schedules
schedules = schedules.Where(s => !joinedScheduleIds.Contains(s.Id)).ToList();
```

## Use Cases

### Use Case 1: Home Page - Show Only Joinable Schedules

**Scenario:** User sees schedules on home page

**Before:**
- Shows all schedules (including already joined)
- User confused seeing Feb 8 schedule they already joined
- Wasted clicks trying to join again

**After:**
```javascript
// API call
GET /api/schedules?availableOnly=true&excludeJoined=true

// Result: Only shows schedules user hasn't joined yet
```

### Use Case 2: Sport-Specific View

**Scenario:** User browsing Tennis schedules

```javascript
const params = new URLSearchParams({
  sportId: 1,              // Tennis
  availableOnly: 'true',   // Has open spots
  excludeJoined: 'true'    // Not already joined
});

const schedules = await fetch(`/api/schedules?${params}`, {
  headers: { 'Authorization': `Bearer ${token}` }
}).then(r => r.json());

// Shows only Tennis schedules user can actually join
```

### Use Case 3: Venue-Specific View

**Scenario:** User looking for schedules at a specific venue

```javascript
const params = new URLSearchParams({
  venue: 'Tennis Court A',
  availableOnly: 'true',
  excludeJoined: 'true'
});

// Shows only schedules at this venue that user hasn't joined
```

## Error Handling

### Not Authenticated

**Request:**
```
GET /api/schedules?excludeJoined=true
(No Authorization header)
```

**Response (401 Unauthorized):**
```json
{
  "message": "Authentication required to use excludeJoined filter"
}
```

### Solution

```javascript
// Check if user is logged in before using excludeJoined
if (userToken) {
  params.append('excludeJoined', 'true');
}
```

## Combining Filters

### Example 1: Available Tennis Schedules (Not Joined)

```
GET /api/schedules?sportId=1&availableOnly=true&excludeJoined=true
```

**Returns:** Tennis schedules with:
- ? Open spots
- ? User hasn't joined
- ? In the future

### Example 2: Venue + Not Joined + Available

```
GET /api/schedules?venue=Community Center&availableOnly=true&excludeJoined=true
```

**Returns:** Community Center schedules with:
- ? Open spots
- ? User hasn't joined
- ? In the future

### Example 3: Date Range + Not Joined

```
GET /api/schedules?startDate=2026-02-01&endDate=2026-02-07&excludeJoined=true
```

**Returns:** Schedules this week that:
- ? User hasn't joined
- ? In the future

## Best Practices

### 1. Always Use for Logged-In Users

```javascript
function loadSchedules(userToken) {
  const params = new URLSearchParams({
    availableOnly: 'true'
  });
  
  // Add excludeJoined for logged-in users
  if (userToken) {
    params.append('excludeJoined', 'true');
  }
  
  // Make request...
}
```

### 2. Handle Unauthorized Error

```javascript
async function loadSchedules(userToken) {
  try {
    const response = await fetch(
      '/api/schedules?excludeJoined=true',
      {
        headers: {
          'Authorization': `Bearer ${userToken}`
        }
      }
    );
    
    if (response.status === 401) {
      // User not authenticated - reload without excludeJoined
      return loadSchedules(null);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error loading schedules:', error);
  }
}
```

### 3. Refresh After Joining

```javascript
async function joinSchedule(scheduleId) {
  // Join schedule
  await fetch('/api/bookings/join', {
    method: 'POST',
    body: JSON.stringify({ scheduleId }),
    headers: {
      'Authorization': `Bearer ${userToken}`,
      'Content-Type': 'application/json'
    }
  });
  
  // Refresh schedule list - joined schedule will now be excluded
  await loadSchedules(userToken);
}
```

## Comparison: Before vs After

### Before Implementation

**User's View:**
```
Available Schedules:
1. Tennis - Feb 8 (1/10 players) ? User already joined
2. Tennis - Feb 9 (0/10 players)
3. Tennis - Feb 10 (0/10 players)
4. Tennis - Feb 11 (0/10 players) ? User already joined
5. Basketball - Feb 12 (3/8 players)
```

**Problems:**
- Shows schedules user already joined
- Confusing UX
- Wasted clicks

### After Implementation

**API Call:**
```
GET /api/schedules?excludeJoined=true&availableOnly=true
```

**User's View:**
```
Available Schedules:
1. Tennis - Feb 9 (0/10 players)   ? Can join
2. Tennis - Feb 10 (0/10 players)  ? Can join
3. Basketball - Feb 12 (3/8 players) ? Can join
```

**Benefits:**
- Only shows schedules user can join
- Clear UX
- No wasted clicks

## Testing

### PowerShell Test

```powershell
$baseUrl = "https://localhost:7063"

# Login as user
$login = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
    -Method Post -Body (@{
        email = "user@example.com"
        password = "UserPass123!"
    } | ConvertTo-Json) -ContentType "application/json"

$token = $login.token
$headers = @{ "Authorization" = "Bearer $token" }

# Get all schedules
$allSchedules = Invoke-RestMethod -Uri "$baseUrl/api/schedules?availableOnly=true" `
    -Headers $headers

Write-Host "All available schedules: $($allSchedules.Count)"

# Get schedules excluding joined ones
$notJoinedSchedules = Invoke-RestMethod -Uri "$baseUrl/api/schedules?availableOnly=true&excludeJoined=true" `
    -Headers $headers

Write-Host "Schedules not yet joined: $($notJoinedSchedules.Count)"

# The difference is schedules user has already joined
$alreadyJoined = $allSchedules.Count - $notJoinedSchedules.Count
Write-Host "Schedules already joined: $alreadyJoined"
```

### Manual Test

1. **Login as user**
2. **Join a schedule** (e.g., Feb 8)
3. **Call API without excludeJoined:**
   ```
   GET /api/schedules?availableOnly=true
   ```
   ? Shows Feb 8 schedule

4. **Call API with excludeJoined:**
   ```
   GET /api/schedules?availableOnly=true&excludeJoined=true
   ```
   ? Does NOT show Feb 8 schedule

## Summary

### What Changed

? **Added `excludeJoined` parameter** to GET /api/schedules  
? **Requires authentication** when using this parameter  
? **Filters out joined schedules** automatically  
? **Cleaner UX** - only shows joinable schedules  

### Benefits

? **Better UX** - Users don't see schedules they've already joined  
? **Less confusion** - Clear which schedules are available  
? **Fewer errors** - Can't accidentally try to join twice  
? **Flexible** - Optional parameter (backward compatible)  

### Usage

**For logged-in users:**
```
GET /api/schedules?availableOnly=true&excludeJoined=true
```

**For guest users:**
```
GET /api/schedules?availableOnly=true
(Don't use excludeJoined without authentication)
```

### Recommendation

**Always use `excludeJoined=true` for authenticated users** on the home page to show only schedules they can join.

---

**Now users will only see schedules they haven't joined yet, creating a much better user experience!** ???
