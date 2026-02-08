# Venue Management API - Complete Guide

## Decision: Keep Venues as String Field

After analysis, **venues remain as a string field** in the Schedule table for these reasons:

### ? Why NOT Move to Separate Table

1. **Simplicity** - Current approach works well
2. **Flexibility** - Admins can create venues on-the-fly
3. **Less complexity** - No joins, foreign keys, or additional tables
4. **Small scope** - Not managing venue resources/inventory
5. **Easier maintenance** - Less code to maintain

### ?? When to Reconsider

Move to separate Venue table IF you need:
- Venue-specific details (address, capacity, amenities, contact info)
- Venue availability/booking system
- Venue operating hours
- Complex venue resource management

## New Venue Management Endpoints

Instead of a separate table, we've added management endpoints to standardize and maintain venue names.

---

## Endpoints

### 1. Get Venue Suggestions (Autocomplete)

**GET /api/venues/suggestions**

Returns list of all unique venue names for autocomplete.

**Authentication:** None required

#### Response

```json
[
  "Community Center",
  "Downtown Sports Complex",
  "North Park",
  "Tennis Club",
  "Tennis Court A"
]
```

#### Usage

```javascript
// Autocomplete for venue field
async function loadVenueSuggestions() {
  const response = await fetch('/api/venues/suggestions');
  const venues = await response.json();
  
  // Populate autocomplete
  venues.forEach(venue => {
    autocomplete.addOption(venue);
  });
}
```

---

### 2. Get Venue Statistics

**GET /api/venues/statistics**

Returns detailed statistics about each venue.

**Authentication:** Admin only

#### Response

```json
[
  {
    "venueName": "Tennis Court A",
    "totalSchedules": 25,
    "futureSchedules": 15,
    "pastSchedules": 10,
    "totalBookings": 120,
    "mostPopularSport": "Tennis",
    "firstScheduleDate": "2026-01-15T19:00:00Z",
    "lastScheduleDate": "2026-03-30T20:00:00Z",
    "averageBookingsPerSchedule": 4.8
  },
  {
    "venueName": "Community Center",
    "totalSchedules": 40,
    "futureSchedules": 30,
    "pastSchedules": 10,
    "totalBookings": 250,
    "mostPopularSport": "Basketball",
    "firstScheduleDate": "2026-01-10T18:00:00Z",
    "lastScheduleDate": "2026-04-15T21:00:00Z",
    "averageBookingsPerSchedule": 6.25
  }
]
```

#### Usage

```javascript
// Admin dashboard - venue analytics
async function loadVenueStats(adminToken) {
  const response = await fetch('/api/venues/statistics', {
    headers: {
      'Authorization': `Bearer ${adminToken}`
    }
  });
  
  const stats = await response.json();
  displayVenueAnalytics(stats);
}
```

---

### 3. Rename Venue

**PUT /api/venues/rename**

Rename a venue across all schedules. Use to standardize names or fix typos.

**Authentication:** Admin only

#### Request Body

```json
{
  "oldName": "Tennis Court - A",
  "newName": "Tennis Court A"
}
```

#### Response

```json
{
  "oldName": "Tennis Court - A",
  "newName": "Tennis Court A",
  "schedulesUpdated": 15,
  "message": "Successfully renamed venue. 15 schedule(s) updated."
}
```

#### Usage

```javascript
// Fix typo in venue name
async function renameVenue(oldName, newName, adminToken) {
  const response = await fetch('/api/venues/rename', {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      oldName,
      newName
    })
  });
  
  const result = await response.json();
  alert(result.message);
}
```

---

### 4. Merge Venues

**POST /api/venues/merge**

Consolidate multiple venue names into one standardized name.

**Authentication:** Admin only

#### Request Body

```json
{
  "targetName": "Tennis Court A",
  "venuesToMerge": [
    "Tennis Court - A",
    "Tennis Court-A",
    "TennisCourtA",
    "Tennis court a"
  ]
}
```

#### Response

```json
{
  "targetName": "Tennis Court A",
  "mergedVenues": [
    "Tennis Court - A",
    "Tennis Court-A",
    "TennisCourtA",
    "Tennis court a"
  ],
  "schedulesUpdated": 42,
  "message": "Successfully merged 4 venue(s) into 'Tennis Court A'. 42 schedule(s) updated."
}
```

#### Usage

```javascript
// Consolidate inconsistent venue names
async function mergeVenues(targetName, venuesToMerge, adminToken) {
  const response = await fetch('/api/venues/merge', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      targetName,
      venuesToMerge
    })
  });
  
  const result = await response.json();
  console.log(`Merged ${result.mergedVenues.length} venues`);
  console.log(`Updated ${result.schedulesUpdated} schedules`);
}
```

---

### 5. Delete Venue

**DELETE /api/venues/{venueName}**

Delete all schedules at a venue. ?? **Use with caution!**

**Authentication:** Admin only

#### Response

```json
{
  "venueName": "Old Gym",
  "schedulesDeleted": 8,
  "bookingsAffected": 35,
  "message": "Venue 'Old Gym' deleted. 8 schedule(s) and 35 booking(s) removed."
}
```

#### Usage

```javascript
// Delete venue and all its schedules
async function deleteVenue(venueName, adminToken) {
  if (!confirm(`Delete ALL schedules at '${venueName}'? This cannot be undone!`)) {
    return;
  }
  
  const response = await fetch(`/api/venues/${encodeURIComponent(venueName)}`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${adminToken}`
    }
  });
  
  const result = await response.json();
  alert(result.message);
}
```

---

### 6. Validate Venue Name

**POST /api/venues/validate**

Check if venue name meets naming standards.

**Authentication:** Admin only

#### Request Body

```json
{
  "venueName": "  Tennis Court  A  "
}
```

#### Response

```json
{
  "venueName": "  Tennis Court  A  ",
  "isValid": false,
  "issues": [
    "Venue name has leading or trailing whitespace",
    "Venue name contains multiple consecutive spaces"
  ],
  "suggestions": [
    "Use: 'Tennis Court A'"
  ]
}
```

#### Usage

```javascript
// Validate before saving
async function validateVenueName(venueName, adminToken) {
  const response = await fetch('/api/venues/validate', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ venueName })
  });
  
  const validation = await response.json();
  
  if (!validation.isValid) {
    console.log('Issues:', validation.issues);
    console.log('Suggestions:', validation.suggestions);
  }
  
  return validation.isValid;
}
```

---

## Use Cases

### Use Case 1: Autocomplete When Creating Schedule

```javascript
// When admin creates schedule, show existing venue names
function setupVenueAutocomplete() {
  const input = document.getElementById('venueInput');
  
  // Load suggestions
  fetch('/api/venues/suggestions')
    .then(r => r.json())
    .then(venues => {
      new Autocomplete(input, {
        data: venues,
        onSelect: (venue) => {
          input.value = venue;
        }
      });
    });
}
```

### Use Case 2: Fix Typo in Venue Name

**Problem:** Admin realizes "Comunity Center" should be "Community Center"

```javascript
await renameVenue(
  "Comunity Center",
  "Community Center",
  adminToken
);

// Result: All 25 schedules updated automatically
```

### Use Case 3: Consolidate Inconsistent Names

**Problem:** Same venue with different names:
- "Tennis Court A"
- "Tennis Court - A"  
- "Tennis court a"
- "TennisCourtA"

```javascript
await mergeVenues(
  "Tennis Court A",  // Standard name
  [
    "Tennis Court - A",
    "Tennis court a",
    "TennisCourtA"
  ],
  adminToken
);

// Result: All variations now use "Tennis Court A"
```

### Use Case 4: Venue Analytics Dashboard

```javascript
async function showVenueAnalytics(adminToken) {
  const stats = await fetch('/api/venues/statistics', {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  }).then(r => r.json());
  
  // Show most popular venue
  const mostPopular = stats.sort((a, b) => 
    b.totalBookings - a.totalBookings
  )[0];
  
  console.log(`Most popular: ${mostPopular.venueName}`);
  console.log(`Total bookings: ${mostPopular.totalBookings}`);
  console.log(`Avg per schedule: ${mostPopular.averageBookingsPerSchedule.toFixed(1)}`);
}
```

### Use Case 5: Clean Up Old Venue

**Problem:** Gym closed, need to remove all schedules

```javascript
// WARNING: Deletes all schedules and bookings!
await deleteVenue("Old Community Gym", adminToken);

// Notifies affected users (implement separately)
// Result: Venue and all schedules removed
```

---

## PowerShell Examples

### Get Venue Suggestions

```powershell
$venues = Invoke-RestMethod -Uri "https://localhost:7063/api/venues/suggestions"

Write-Host "Available Venues:"
foreach ($venue in $venues) {
    Write-Host "  - $venue"
}
```

### Rename Venue

```powershell
$headers = @{ "Authorization" = "Bearer $adminToken" }

$renameBody = @{
    oldName = "Tennis Court - A"
    newName = "Tennis Court A"
} | ConvertTo-Json

$result = Invoke-RestMethod -Uri "https://localhost:7063/api/venues/rename" `
    -Method Put -Headers $headers -Body $renameBody -ContentType "application/json"

Write-Host $result.message
```

### Merge Venues

```powershell
$mergeBody = @{
    targetName = "Tennis Court A"
    venuesToMerge = @(
        "Tennis Court - A",
        "Tennis court a",
        "TennisCourtA"
    )
} | ConvertTo-Json

$result = Invoke-RestMethod -Uri "https://localhost:7063/api/venues/merge" `
    -Method Post -Headers $headers -Body $mergeBody -ContentType "application/json"

Write-Host "Merged $($result.mergedVenues.Count) venues"
Write-Host "Updated $($result.schedulesUpdated) schedules"
```

### Get Statistics

```powershell
$stats = Invoke-RestMethod -Uri "https://localhost:7063/api/venues/statistics" `
    -Headers $headers

foreach ($venue in $stats) {
    Write-Host "`n$($venue.venueName):"
    Write-Host "  Total Schedules: $($venue.totalSchedules)"
    Write-Host "  Future: $($venue.futureSchedules)"
    Write-Host "  Total Bookings: $($venue.totalBookings)"
    Write-Host "  Most Popular Sport: $($venue.mostPopularSport)"
    Write-Host "  Avg Bookings/Schedule: $([math]::Round($venue.averageBookingsPerSchedule, 2))"
}
```

---

## React Component Examples

### Venue Autocomplete

```jsx
function VenueAutocomplete({ value, onChange }) {
  const [suggestions, setSuggestions] = useState([]);
  
  useEffect(() => {
    fetch('/api/venues/suggestions')
      .then(r => r.json())
      .then(data => setSuggestions(data));
  }, []);
  
  return (
    <Autocomplete
      options={suggestions}
      value={value}
      onChange={(e, newValue) => onChange(newValue)}
      renderInput={(params) => (
        <TextField {...params} label="Venue" />
      )}
    />
  );
}
```

### Venue Statistics Dashboard

```jsx
function VenueStatistics() {
  const [stats, setStats] = useState([]);
  const { adminToken } = useAuth();
  
  useEffect(() => {
    fetch('/api/venues/statistics', {
      headers: { 'Authorization': `Bearer ${adminToken}` }
    })
      .then(r => r.json())
      .then(data => setStats(data));
  }, [adminToken]);
  
  return (
    <div>
      <h2>Venue Statistics</h2>
      {stats.map(venue => (
        <div key={venue.venueName}>
          <h3>{venue.venueName}</h3>
          <p>Total Schedules: {venue.totalSchedules}</p>
          <p>Future: {venue.futureSchedules}</p>
          <p>Total Bookings: {venue.totalBookings}</p>
          <p>Most Popular: {venue.mostPopularSport}</p>
          <p>Avg Bookings: {venue.averageBookingsPerSchedule.toFixed(1)}</p>
        </div>
      ))}
    </div>
  );
}
```

### Venue Management Panel

```jsx
function VenueManagement() {
  const [venues, setVenues] = useState([]);
  const { adminToken } = useAuth();
  
  const handleRename = async (oldName) => {
    const newName = prompt(`Rename "${oldName}" to:`);
    if (!newName) return;
    
    await fetch('/api/venues/rename', {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ oldName, newName })
    });
    
    // Reload venues
    loadVenues();
  };
  
  const handleDelete = async (venueName) => {
    if (!confirm(`Delete all schedules at "${venueName}"?`)) return;
    
    await fetch(`/api/venues/${encodeURIComponent(venueName)}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });
    
    loadVenues();
  };
  
  return (
    <div>
      {venues.map(venue => (
        <div key={venue}>
          <span>{venue}</span>
          <button onClick={() => handleRename(venue)}>Rename</button>
          <button onClick={() => handleDelete(venue)}>Delete</button>
        </div>
      ))}
    </div>
  );
}
```

---

## API Reference Summary

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/venues/suggestions` | GET | No | Get venue list for autocomplete |
| `/api/venues/statistics` | GET | Admin | Get venue analytics |
| `/api/venues/rename` | PUT | Admin | Rename venue across schedules |
| `/api/venues/merge` | POST | Admin | Consolidate multiple names |
| `/api/venues/{name}` | DELETE | Admin | Delete venue and schedules |
| `/api/venues/validate` | POST | Admin | Validate venue name format |

---

## Benefits

### ? Current Approach Benefits

1. **Simple** - No schema changes needed
2. **Flexible** - Create venues on-the-fly
3. **Manageable** - Tools to standardize names
4. **Fast** - No joins required
5. **Backward compatible** - Works with existing data

### ?? Management Features

1. **Autocomplete** - Reuse existing venue names
2. **Rename** - Fix typos/standardize
3. **Merge** - Consolidate variations
4. **Analytics** - Track venue usage
5. **Validation** - Prevent formatting issues

---

## Summary

### Decision

? **Keep venues as string field** in Schedule table

### Rationale

- Simple and flexible
- Current implementation works well
- No need for complex venue management
- Easy to standardize with new endpoints

### What We Added

? **GET /api/venues/suggestions** - Autocomplete  
? **GET /api/venues/statistics** - Analytics  
? **PUT /api/venues/rename** - Standardize names  
? **POST /api/venues/merge** - Consolidate variations  
? **DELETE /api/venues/{name}** - Remove venue  
? **POST /api/venues/validate** - Check format  

### When to Reconsider

Consider separate Venue table IF you need:
- Venue-specific details (address, capacity, contact)
- Venue resource/availability management
- Complex venue booking system
- Venue operating hours/rules

---

**Now you have powerful venue management without the complexity of a separate table!** ????
