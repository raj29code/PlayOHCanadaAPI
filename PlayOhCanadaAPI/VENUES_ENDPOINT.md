# Venues Endpoint - Documentation

## Overview

A new public endpoint has been added to retrieve all available venues where schedules exist. This helps users discover where they can join sports activities.

## Endpoint Details

### GET /api/schedules/venues

**Authentication:** None required (public endpoint)

**Description:** Returns a list of all unique venues with schedule information

**Response:** Array of venue objects with statistics

## Response Format

```json
[
  {
    "name": "Tennis Court A",
    "scheduleCount": 15,
    "availableSchedules": 12,
    "sports": ["Tennis", "Pickleball"]
  },
  {
    "name": "Community Center",
    "scheduleCount": 8,
    "availableSchedules": 5,
    "sports": ["Basketball", "Volleyball"]
  },
  {
    "name": "Downtown Sports Complex",
    "scheduleCount": 20,
    "availableSchedules": 18,
    "sports": ["Soccer", "Tennis", "Basketball"]
  }
]
```

## Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Venue name |
| `scheduleCount` | int | Total number of future schedules at this venue |
| `availableSchedules` | int | Number of schedules with open spots |
| `sports` | string[] | List of sports available at this venue |

## Features

### What It Shows

? **All venues** with future schedules  
? **Total schedules** at each venue  
? **Available schedules** (with open spots)  
? **Sports offered** at each venue  
? **Sorted alphabetically** by venue name  

### What It Filters

- ? Only future schedules (past schedules excluded)
- ? Grouped by venue name
- ? Distinct sports per venue

## Usage Examples

### JavaScript/Frontend

```javascript
// Get all venues
async function loadVenues() {
  const response = await fetch('/api/schedules/venues');
  const venues = await response.json();
  
  console.log(`Found ${venues.length} venues`);
  
  venues.forEach(venue => {
    console.log(`${venue.name}:`);
    console.log(`  - ${venue.availableSchedules}/${venue.scheduleCount} schedules available`);
    console.log(`  - Sports: ${venue.sports.join(', ')}`);
  });
}

// Use in venue selector
async function populateVenueDropdown() {
  const venues = await fetch('/api/schedules/venues').then(r => r.json());
  
  const select = document.getElementById('venueSelect');
  
  venues.forEach(venue => {
    const option = document.createElement('option');
    option.value = venue.name;
    option.textContent = `${venue.name} (${venue.availableSchedules} available)`;
    select.appendChild(option);
  });
}
```

### PowerShell

```powershell
# Get all venues
$venues = Invoke-RestMethod -Uri "https://localhost:7063/api/schedules/venues"

Write-Host "Available Venues:" -ForegroundColor Cyan
Write-Host ""

foreach ($venue in $venues) {
    Write-Host "$($venue.name)" -ForegroundColor Green
    Write-Host "  Schedules: $($venue.availableSchedules) available / $($venue.scheduleCount) total"
    Write-Host "  Sports: $($venue.sports -join ', ')"
    Write-Host ""
}
```

### cURL

```bash
# Get all venues
curl https://localhost:7063/api/schedules/venues -k
```

## Use Cases

### Use Case 1: Venue Filter

Display venues in a filter dropdown:

```javascript
async function createVenueFilter() {
  const venues = await fetch('/api/schedules/venues').then(r => r.json());
  
  const filterHtml = `
    <select id="venueFilter">
      <option value="">All Venues</option>
      ${venues.map(v => `
        <option value="${v.name}">
          ${v.name} (${v.availableSchedules} available)
        </option>
      `).join('')}
    </select>
  `;
  
  return filterHtml;
}
```

### Use Case 2: Venue Discovery

Show venues with available activities:

```javascript
async function showAvailableVenues() {
  const venues = await fetch('/api/schedules/venues').then(r => r.json());
  
  const available = venues.filter(v => v.availableSchedules > 0);
  
  return available.map(venue => ({
    name: venue.name,
    message: `${venue.availableSchedules} activities available`,
    sports: venue.sports
  }));
}
```

### Use Case 3: Venue Details Page

Display comprehensive venue information:

```javascript
async function getVenueDetails(venueName) {
  const venues = await fetch('/api/schedules/venues').then(r => r.json());
  const venue = venues.find(v => v.name === venueName);
  
  if (!venue) return null;
  
  // Get schedules for this venue
  const schedules = await fetch(
    `/api/schedules?venue=${encodeURIComponent(venueName)}&availableOnly=true`
  ).then(r => r.json());
  
  return {
    ...venue,
    schedules: schedules
  };
}
```

### Use Case 4: Popular Venues

Show most active venues:

```javascript
async function getPopularVenues() {
  const venues = await fetch('/api/schedules/venues').then(r => r.json());
  
  // Sort by schedule count
  return venues
    .sort((a, b) => b.scheduleCount - a.scheduleCount)
    .slice(0, 5); // Top 5
}
```

## Frontend Integration

### React Component

```jsx
function VenueList() {
  const [venues, setVenues] = useState([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    async function loadVenues() {
      const response = await fetch('/api/schedules/venues');
      const data = await response.json();
      setVenues(data);
      setLoading(false);
    }
    
    loadVenues();
  }, []);
  
  if (loading) return <div>Loading venues...</div>;
  
  return (
    <div>
      <h2>Available Venues</h2>
      {venues.map(venue => (
        <div key={venue.name} className="venue-card">
          <h3>{venue.name}</h3>
          <p>{venue.availableSchedules} of {venue.scheduleCount} schedules available</p>
          <p>Sports: {venue.sports.join(', ')}</p>
          <button onClick={() => viewVenue(venue.name)}>
            View Schedules
          </button>
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
    <h2>Available Venues</h2>
    <div v-for="venue in venues" :key="venue.name" class="venue-card">
      <h3>{{ venue.name }}</h3>
      <p>{{ venue.availableSchedules }} / {{ venue.scheduleCount }} schedules available</p>
      <p>Sports: {{ venue.sports.join(', ') }}</p>
      <button @click="viewVenue(venue.name)">View Schedules</button>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      venues: []
    };
  },
  async mounted() {
    const response = await fetch('/api/schedules/venues');
    this.venues = await response.json();
  },
  methods: {
    viewVenue(venueName) {
      this.$router.push(`/venues/${encodeURIComponent(venueName)}`);
    }
  }
};
</script>
```

### Angular Service

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

interface Venue {
  name: string;
  scheduleCount: number;
  availableSchedules: number;
  sports: string[];
}

@Injectable({ providedIn: 'root' })
export class VenueService {
  private apiUrl = '/api/schedules/venues';
  
  constructor(private http: HttpClient) {}
  
  getVenues(): Observable<Venue[]> {
    return this.http.get<Venue[]>(this.apiUrl);
  }
  
  getPopularVenues(): Observable<Venue[]> {
    return this.http.get<Venue[]>(this.apiUrl).pipe(
      map(venues => venues
        .sort((a, b) => b.scheduleCount - a.scheduleCount)
        .slice(0, 5)
      )
    );
  }
}
```

## Benefits

### For Users

? **Discover locations** - See all venues easily  
? **Check availability** - Know which venues have open schedules  
? **Find sports** - See what sports each venue offers  
? **Make decisions** - Choose venue based on availability  

### For Frontend Developers

? **Simple integration** - Single endpoint for venue data  
? **No authentication** - Public access  
? **Comprehensive data** - All info in one response  
? **Ready-to-use** - No additional processing needed  

## Combined with Schedule Filter

Use venues endpoint with schedules endpoint:

```javascript
// Step 1: Get all venues
const venues = await fetch('/api/schedules/venues').then(r => r.json());

// Step 2: User selects a venue
const selectedVenue = venues[0].name;

// Step 3: Get schedules for that venue
const schedules = await fetch(
  `/api/schedules?venue=${encodeURIComponent(selectedVenue)}&availableOnly=true`
).then(r => r.json());

// Now display schedules for the selected venue
```

## Example Workflow

### User Journey

1. **User visits app**
   ```javascript
   GET /api/schedules/venues
   ? Shows all venues
   ```

2. **User selects venue**
   ```
   User clicks "Tennis Court A"
   ```

3. **Load venue schedules**
   ```javascript
   GET /api/schedules?venue=Tennis Court A&availableOnly=true
   ? Shows available schedules at that venue
   ```

4. **User joins schedule**
   ```javascript
   POST /api/bookings/join
   ? User books a spot
   ```

## Response Examples

### Multiple Venues

```json
[
  {
    "name": "Community Center",
    "scheduleCount": 25,
    "availableSchedules": 20,
    "sports": ["Basketball", "Volleyball", "Badminton"]
  },
  {
    "name": "Downtown Sports Complex",
    "scheduleCount": 40,
    "availableSchedules": 35,
    "sports": ["Tennis", "Soccer", "Basketball", "Swimming"]
  },
  {
    "name": "North Park",
    "scheduleCount": 15,
    "availableSchedules": 10,
    "sports": ["Soccer", "Frisbee"]
  },
  {
    "name": "Tennis Club",
    "scheduleCount": 30,
    "availableSchedules": 25,
    "sports": ["Tennis", "Pickleball"]
  }
]
```

### Single Venue

```json
[
  {
    "name": "Local Gym",
    "scheduleCount": 5,
    "availableSchedules": 3,
    "sports": ["Basketball", "Yoga"]
  }
]
```

### No Venues

```json
[]
```

## Error Handling

### Success (200 OK)

```json
[
  {
    "name": "Venue Name",
    "scheduleCount": 10,
    "availableSchedules": 8,
    "sports": ["Tennis"]
  }
]
```

### Empty Result

```json
[]
```

**Note:** Returns empty array if no venues found (not an error)

## Performance

### Optimized Query

The endpoint uses a single database query with grouping:

```csharp
_context.Schedules
    .Where(s => s.StartTime > DateTime.UtcNow)  // Only future
    .GroupBy(s => s.Venue)                       // Group by venue
    .Select(g => new VenueDto { ... })           // Project to DTO
```

**Benefits:**
- ? Single database query
- ? Efficient grouping
- ? No N+1 query problem
- ? Fast response time

## Testing

### Manual Test

```powershell
# Test venues endpoint
$venues = Invoke-RestMethod -Uri "https://localhost:7063/api/schedules/venues"

Write-Host "Found $($venues.Count) venues"

# Verify structure
$venues | ForEach-Object {
    Write-Host "Venue: $($_.name)"
    Write-Host "  Total: $($_.scheduleCount)"
    Write-Host "  Available: $($_.availableSchedules)"
    Write-Host "  Sports: $($_.sports -join ', ')"
}
```

### Browser Test

Simply open:
```
https://localhost:7063/api/schedules/venues
```

## API Reference Summary

### Endpoint

**GET /api/schedules/venues**

### Authentication

None required (public)

### Parameters

None

### Response

**200 OK:**
```json
[
  {
    "name": "string",
    "scheduleCount": 0,
    "availableSchedules": 0,
    "sports": ["string"]
  }
]
```

### Features

- ? Returns all venues with future schedules
- ? Includes schedule statistics
- ? Lists available sports
- ? Sorted alphabetically
- ? Public access (no auth required)

## Summary

### What Was Added

? **GET /api/schedules/venues** endpoint  
? **VenueDto** response model  
? **Venue statistics** (count, availability, sports)  
? **Public access** (no authentication)  
? **Optimized query** (single database call)  

### Use Cases

? **Venue discovery** - Browse all locations  
? **Filter options** - Populate dropdowns  
? **Venue details** - Show statistics  
? **Popular venues** - Rank by activity  

### Benefits

? **Simple integration** - One endpoint  
? **Complete data** - All info included  
? **No authentication** - Public access  
? **Fast performance** - Optimized query  

---

**Now users can easily discover all venues where they can join sports activities!** ????
