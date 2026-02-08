# Join Schedule & My Bookings - Complete Guide

## Overview

Users can join schedules and view their bookings through two main endpoints:
1. **POST /api/bookings/join** - Join a schedule
2. **GET /api/bookings/my-bookings** - View your bookings

## Endpoints

### 1. Join Schedule

**POST /api/bookings/join**

Allows users (both registered and guests) to join a schedule.

#### Request Body

```json
{
  "scheduleId": 123,
  "guestName": "John Doe",     // Required for guests only
  "guestMobile": "+1234567890"  // Optional for guests
}
```

#### For Registered Users

```javascript
// User must be logged in
const response = await fetch('/api/bookings/join', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${userToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    scheduleId: 123
  })
});
```

#### For Guest Users

```javascript
// No authentication required
const response = await fetch('/api/bookings/join', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    scheduleId: 123,
    guestName: "John Doe",
    guestMobile: "+1234567890"
  })
});
```

#### Response (200 Created)

```json
{
  "id": 456,
  "scheduleId": 123,
  "bookingTime": "2026-01-29T15:30:00Z",
  "sportName": "Tennis",
  "sportIconUrl": "https://...",
  "venue": "Tennis Court A",
  "scheduleStartTime": "2026-02-01T19:00:00",
  "scheduleEndTime": "2026-02-01T20:00:00",
  "maxPlayers": 10,
  "currentPlayers": 6,
  "equipmentDetails": "Bring your racket",
  "isPast": false,
  "canCancel": true
}
```

#### Error Responses

**400 Bad Request - Schedule Full:**
```json
{
  "message": "This schedule is full. No spots remaining."
}
```

**400 Bad Request - Already Booked:**
```json
{
  "message": "You have already booked this schedule"
}
```

**400 Bad Request - Schedule Started:**
```json
{
  "message": "Cannot book a schedule that has already started or passed"
}
```

**404 Not Found:**
```json
{
  "message": "Schedule not found"
}
```

### 2. My Bookings

**GET /api/bookings/my-bookings**

Get all bookings for the authenticated user.

**Authentication:** Required

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `timezoneOffsetMinutes` | int | No | Timezone offset for time conversion |
| `includeAll` | bool | No | Include past bookings (default: false) |

#### Request

```javascript
const offset = -new Date().getTimezoneOffset();

const response = await fetch(
  `/api/bookings/my-bookings?timezoneOffsetMinutes=${offset}`,
  {
    headers: {
      'Authorization': `Bearer ${userToken}`
    }
  }
);
```

#### Response

```json
[
  {
    "id": 456,
    "scheduleId": 123,
    "bookingTime": "2026-01-29T15:30:00Z",
    "sportName": "Tennis",
    "sportIconUrl": "https://...",
    "venue": "Tennis Court A",
    "scheduleStartTime": "2026-02-01T14:00:00",
    "scheduleEndTime": "2026-02-01T15:00:00",
    "maxPlayers": 10,
    "currentPlayers": 6,
    "equipmentDetails": "Bring your racket",
    "isPast": false,
    "canCancel": true
  },
  {
    "id": 457,
    "scheduleId": 124,
    "bookingTime": "2026-01-28T10:00:00Z",
    "sportName": "Basketball",
    "sportIconUrl": "https://...",
    "venue": "Community Center",
    "scheduleStartTime": "2026-02-03T18:00:00",
    "scheduleEndTime": "2026-02-03T19:00:00",
    "maxPlayers": 8,
    "currentPlayers": 4,
    "equipmentDetails": null,
    "isPast": false,
    "canCancel": true
  }
]
```

### 3. Cancel Booking

**DELETE /api/bookings/{id}**

Cancel a booking (registered users only).

**Authentication:** Required

**Rules:**
- Must be at least 2 hours before schedule start time
- Cannot cancel past schedules

#### Request

```javascript
await fetch(`/api/bookings/${bookingId}`, {
  method: 'DELETE',
  headers: {
    'Authorization': `Bearer ${userToken}`
  }
});
```

#### Response (200 OK)

```json
{
  "message": "Booking cancelled successfully"
}
```

#### Error Responses

**400 Bad Request - Too Late:**
```json
{
  "message": "Cannot cancel booking less than 2 hours before start time"
}
```

**400 Bad Request - Already Started:**
```json
{
  "message": "Cannot cancel a booking for a schedule that has already started or passed"
}
```

## UI Integration

### Join Schedule Flow

```javascript
async function joinSchedule(scheduleId, userToken) {
  try {
    const headers = {
      'Content-Type': 'application/json'
    };
    
    // Add auth header if user is logged in
    if (userToken) {
      headers['Authorization'] = `Bearer ${userToken}`;
    }
    
    const body = { scheduleId };
    
    // For guests, add name
    if (!userToken) {
      const guestName = prompt('Enter your name:');
      if (!guestName) return;
      body.guestName = guestName;
      
      const guestMobile = prompt('Enter your mobile (optional):');
      if (guestMobile) body.guestMobile = guestMobile;
    }
    
    const response = await fetch('/api/bookings/join', {
      method: 'POST',
      headers,
      body: JSON.stringify(body)
    });
    
    if (!response.ok) {
      const error = await response.json();
      alert(error.message);
      return;
    }
    
    const booking = await response.json();
    alert(`Successfully joined! ${booking.currentPlayers}/${booking.maxPlayers} players`);
    
    // Redirect to My Bookings page
    if (userToken) {
      window.location.href = '/my-bookings';
    }
  } catch (error) {
    alert('Error joining schedule. Please try again.');
  }
}
```

### Display My Bookings

```javascript
async function loadMyBookings() {
  const offset = -new Date().getTimezoneOffset();
  
  const response = await fetch(
    `/api/bookings/my-bookings?timezoneOffsetMinutes=${offset}`,
    {
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    }
  );
  
  const bookings = await response.json();
  
  bookings.forEach(booking => {
    displayBookingCard({
      sport: booking.sportName,
      icon: booking.sportIconUrl,
      venue: booking.venue,
      startTime: new Date(booking.scheduleStartTime).toLocaleString(),
      players: `${booking.currentPlayers}/${booking.maxPlayers}`,
      canCancel: booking.canCancel,
      bookingId: booking.id
    });
  });
}
```

### Cancel Booking

```javascript
async function cancelBooking(bookingId) {
  if (!confirm('Are you sure you want to cancel this booking?')) {
    return;
  }
  
  try {
    const response = await fetch(`/api/bookings/${bookingId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    });
    
    if (!response.ok) {
      const error = await response.json();
      alert(error.message);
      return;
    }
    
    const result = await response.json();
    alert(result.message);
    
    // Reload bookings
    await loadMyBookings();
  } catch (error) {
    alert('Error cancelling booking. Please try again.');
  }
}
```

## React Component Example

```jsx
function ScheduleCard({ schedule, userToken }) {
  const [isJoining, setIsJoining] = useState(false);
  
  const handleJoin = async () => {
    setIsJoining(true);
    
    try {
      const response = await fetch('/api/bookings/join', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${userToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          scheduleId: schedule.id
        })
      });
      
      if (!response.ok) {
        const error = await response.json();
        alert(error.message);
        return;
      }
      
      const booking = await response.json();
      alert('Successfully joined!');
      
      // Redirect to My Bookings
      navigate('/my-bookings');
    } catch (error) {
      alert('Error joining schedule');
    } finally {
      setIsJoining(false);
    }
  };
  
  return (
    <div className="schedule-card">
      <img src={schedule.sportIconUrl} alt={schedule.sportName} />
      <h3>{schedule.sportName}</h3>
      <p>{schedule.venue}</p>
      <p>{new Date(schedule.startTime).toLocaleString()}</p>
      <p>{schedule.spotsRemaining} spots available</p>
      <button 
        onClick={handleJoin} 
        disabled={isJoining || schedule.spotsRemaining === 0}
      >
        {isJoining ? 'Joining...' : 'JOIN SCHEDULE'}
      </button>
    </div>
  );
}

function MyBookings() {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    loadBookings();
  }, []);
  
  const loadBookings = async () => {
    const offset = -new Date().getTimezoneOffset();
    
    const response = await fetch(
      `/api/bookings/my-bookings?timezoneOffsetMinutes=${offset}`,
      {
        headers: {
          'Authorization': `Bearer ${userToken}`
        }
      }
    );
    
    const data = await response.json();
    setBookings(data);
    setLoading(false);
  };
  
  const handleCancel = async (bookingId) => {
    if (!confirm('Cancel this booking?')) return;
    
    await fetch(`/api/bookings/${bookingId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    });
    
    await loadBookings();
  };
  
  if (loading) return <div>Loading...</div>;
  
  return (
    <div>
      <h2>My Bookings</h2>
      {bookings.map(booking => (
        <div key={booking.id} className="booking-card">
          <img src={booking.sportIconUrl} alt={booking.sportName} />
          <h3>{booking.sportName}</h3>
          <p>{booking.venue}</p>
          <p>{new Date(booking.scheduleStartTime).toLocaleString()}</p>
          <p>{booking.currentPlayers}/{booking.maxPlayers} players</p>
          {booking.canCancel && (
            <button onClick={() => handleCancel(booking.id)}>
              Cancel Booking
            </button>
          )}
        </div>
      ))}
    </div>
  );
}
```

## Response Fields Explained

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Booking ID |
| `scheduleId` | int | Schedule ID |
| `bookingTime` | DateTime | When user booked |
| `sportName` | string | Sport name |
| `sportIconUrl` | string | Sport icon URL |
| `venue` | string | Venue location |
| `scheduleStartTime` | DateTime | When schedule starts (timezone converted) |
| `scheduleEndTime` | DateTime | When schedule ends (timezone converted) |
| `maxPlayers` | int | Maximum players allowed |
| `currentPlayers` | int | Current number of bookings |
| `equipmentDetails` | string | Equipment requirements |
| `isPast` | bool | Whether schedule is in the past |
| `canCancel` | bool | Whether booking can be cancelled (>2hrs before start) |

## Business Rules

### Joining

? **Can join if:**
- Schedule exists
- Schedule is in the future
- Spots are available (currentPlayers < maxPlayers)
- User hasn't already booked (for registered users)

? **Cannot join if:**
- Schedule is full
- Schedule has already started
- User already booked this schedule
- Schedule doesn't exist

### Cancellation

? **Can cancel if:**
- User owns the booking
- At least 2 hours before start time
- Schedule hasn't started yet

? **Cannot cancel if:**
- Less than 2 hours before start
- Schedule already started or passed
- Booking doesn't exist
- User doesn't own the booking

## Testing

### PowerShell Test Script

```powershell
$baseUrl = "https://localhost:7063"

# Step 1: Login
$loginBody = @{
    email = "user@example.com"
    password = "UserPass123!"
} | ConvertTo-Json

$login = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"

$token = $login.token
$headers = @{ "Authorization" = "Bearer $token" }

# Step 2: Get available schedules
$schedules = Invoke-RestMethod -Uri "$baseUrl/api/schedules?availableOnly=true"
Write-Host "Found $($schedules.Count) available schedules"

# Step 3: Join first schedule
if ($schedules.Count -gt 0) {
    $scheduleId = $schedules[0].id
    
    $joinBody = @{
        scheduleId = $scheduleId
    } | ConvertTo-Json
    
    $booking = Invoke-RestMethod -Uri "$baseUrl/api/bookings/join" `
        -Method Post -Headers $headers -Body $joinBody -ContentType "application/json"
    
    Write-Host "? Joined schedule: $($booking.sportName) at $($booking.venue)"
    Write-Host "  Players: $($booking.currentPlayers)/$($booking.maxPlayers)"
}

# Step 4: View my bookings
$offset = -([System.TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now).TotalMinutes)
$myBookings = Invoke-RestMethod -Uri "$baseUrl/api/bookings/my-bookings?timezoneOffsetMinutes=$offset" `
    -Headers $headers

Write-Host "`nMy Bookings:"
foreach ($booking in $myBookings) {
    Write-Host "  - $($booking.sportName) at $($booking.venue)"
    Write-Host "    Time: $($booking.scheduleStartTime)"
    Write-Host "    Can Cancel: $($booking.canCancel)"
}

# Step 5: Cancel a booking (if possible)
if ($myBookings.Count -gt 0 -and $myBookings[0].canCancel) {
    $bookingId = $myBookings[0].id
    
    Invoke-RestMethod -Uri "$baseUrl/api/bookings/$bookingId" `
        -Method Delete -Headers $headers
    
    Write-Host "`n? Booking cancelled"
}
```

## Summary

### Endpoints

? **POST /api/bookings/join** - Join a schedule  
? **GET /api/bookings/my-bookings** - View your bookings  
? **DELETE /api/bookings/{id}** - Cancel a booking  

### Features

? **Registered users** - Track bookings with user account  
? **Guest users** - Join without account (name required)  
? **Timezone support** - Times in local timezone  
? **Capacity checks** - Prevent overbooking  
? **Duplicate prevention** - User can't book same schedule twice  
? **Cancellation rules** - Must be 2+ hours before start  
? **Past schedules** - Cannot book/cancel past schedules  

### UI Flow

1. User browses schedules
2. Clicks "JOIN SCHEDULE" button
3. Creates booking
4. Views "My Bookings" page
5. Can cancel if >2 hours before start

---

**Now users can easily join schedules and manage their bookings!** ?????
