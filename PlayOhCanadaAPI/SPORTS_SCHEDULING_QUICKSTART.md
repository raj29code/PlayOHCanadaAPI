# Sports Scheduling API - Quick Start Guide

## Prerequisites
- PostgreSQL database running
- Admin user credentials: `admin@playohcanada.com` / `Admin@123`

## Getting Started

### 1. Apply the Migration
The migration will be applied automatically when you run the application in development mode.

```bash
# Or manually apply it
cd PlayOhCanadaAPI
dotnet ef database update
```

### 2. Run the Application
```bash
cd PlayOhCanadaAPI
dotnet run
```

The application will:
- Auto-migrate the database
- Seed the admin user
- Seed 6 default sports (Tennis, Badminton, Basketball, Soccer, Volleyball, Pickleball)

### 3. Access the API Documentation
- **Scalar UI**: https://localhost:7186/scalar/v1
- **OpenAPI JSON**: https://localhost:7186/openapi/v1.json

## Quick Test

Run the PowerShell test script:
```powershell
.\test-sports-api.ps1
```

This will:
1. Login as admin
2. Create sports (if not already seeded)
3. Create schedules (single and recurring)
4. Create bookings (guest and registered user)
5. Display results

## Common API Workflows

### Workflow 1: Admin Creates a Weekly Tennis Session

```bash
# 1. Login as admin
POST /api/auth/login
{
  "email": "admin@playohcanada.com",
  "password": "Admin@123"
}
# Returns: { "token": "eyJhbG..." }

# 2. Create recurring schedule
POST /api/schedules
Authorization: Bearer {token}
{
  "sportId": 1,
  "venue": "Central Park Tennis Courts",
  "startTime": "2024-12-26T18:00:00Z",
  "endTime": "2024-12-26T20:00:00Z",
  "maxPlayers": 6,
  "equipmentDetails": "Rackets provided",
  "recurrence": {
    "isRecurring": true,
    "frequency": 7,
    "endDate": "2025-03-31T00:00:00Z"
  }
}
# Creates 14 weekly schedules
```

### Workflow 2: User Discovers and Joins a Game

```bash
# 1. Browse upcoming games (no auth required)
GET /api/schedules?sportId=1&venue=Central

# Response shows available slots with participant counts:
[
  {
    "id": 1,
    "sportName": "Tennis",
    "venue": "Central Park Tennis Courts",
    "startTime": "2024-12-26T18:00:00Z",
    "endTime": "2024-12-26T20:00:00Z",
    "maxPlayers": 6,
    "currentPlayers": 2,
    "spotsRemaining": 4,
    "equipmentDetails": "Rackets provided"
  }
]

# 2. View participants (social visibility)
GET /api/schedules/1

# Response includes participant list:
{
  "id": 1,
  ...
  "participants": [
    { "name": "John Doe", "bookingTime": "2024-12-20T10:00:00Z" },
    { "name": "Jane Smith", "bookingTime": "2024-12-20T11:30:00Z" }
  ]
}

# 3a. Join as registered user
POST /api/bookings/join
Authorization: Bearer {user_token}
{
  "scheduleId": 1
}

# OR

# 3b. Join as guest
POST /api/bookings/join
{
  "scheduleId": 1,
  "guestName": "Alex Johnson",
  "guestMobile": "+1234567890"
}
```

### Workflow 3: User Manages Their Bookings

```bash
# 1. View my bookings
GET /api/bookings/my-bookings
Authorization: Bearer {user_token}

# 2. Cancel a booking (must be >2 hours before start)
DELETE /api/bookings/123
Authorization: Bearer {user_token}
```

### Workflow 4: Admin Updates a Schedule

```bash
# 1. Update venue or increase capacity
PUT /api/schedules/1
Authorization: Bearer {admin_token}
{
  "venue": "New Location - Downtown Tennis Club",
  "maxPlayers": 8
}

# 2. Cancel a schedule
DELETE /api/schedules/1
Authorization: Bearer {admin_token}
# Note: Bookings are automatically deleted (cascade)
```

## API Endpoints Summary

### Public Endpoints (No Auth Required)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/sports` | GET | List all sports |
| `/api/sports/{id}` | GET | Get sport details |
| `/api/schedules` | GET | Browse schedules with filters |
| `/api/schedules/{id}` | GET | Get schedule with participants |
| `/api/bookings/join` | POST | Join as guest |
| `/api/bookings/{id}` | GET | Get booking details |

### User Endpoints (Auth Required)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/bookings/join` | POST | Join as registered user |
| `/api/bookings/my-bookings` | GET | Get user's bookings |
| `/api/bookings/{id}` | DELETE | Cancel own booking |

### Admin Endpoints (Admin Role Required)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/sports` | POST | Create a sport |
| `/api/sports/{id}` | DELETE | Delete a sport |
| `/api/schedules` | POST | Create schedule(s) |
| `/api/schedules/{id}` | PUT | Update schedule |
| `/api/schedules/{id}` | DELETE | Cancel schedule |
| `/api/bookings/schedule/{id}` | GET | View all bookings for a schedule |

## Query Parameters for GET /api/schedules

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `sportId` | int | Filter by sport | `?sportId=1` |
| `venue` | string | Search venue (contains) | `?venue=Central` |
| `startDate` | DateTime | Schedules starting after | `?startDate=2024-12-25` |
| `endDate` | DateTime | Schedules starting before | `?endDate=2024-12-31` |
| `includeParticipants` | bool | Include participant list | `?includeParticipants=true` |

**Examples:**
- Get all Tennis games: `/api/schedules?sportId=1`
- Get games at Central Park: `/api/schedules?venue=Central`
- Get this week's games: `/api/schedules?startDate=2024-12-20&endDate=2024-12-27`
- Combined filters: `/api/schedules?sportId=1&venue=Central&startDate=2024-12-20&includeParticipants=true`

## Recurrence Frequency Options

When creating recurring schedules:
```json
{
  "recurrence": {
    "isRecurring": true,
    "frequency": 7,  // Options: 1=Daily, 7=Weekly, 14=BiWeekly, 30=Monthly
    "endDate": "2025-03-31T00:00:00Z"
  }
}
```

| Frequency | Value | Description |
|-----------|-------|-------------|
| Daily | 1 | Every day |
| Weekly | 7 | Once per week |
| BiWeekly | 14 | Every 2 weeks |
| Monthly | 30 | Approximately monthly |

## Business Rules

### Booking Rules
- ? Registered users can only book once per schedule
- ? Cannot book schedules that have started or passed
- ? Cannot book full schedules (currentPlayers >= maxPlayers)
- ? Cancellation must be >2 hours before start time
- ? Guests can book but cannot cancel (admin intervention required)

### Schedule Management Rules
- ? Cannot reduce maxPlayers below current booking count
- ? Deleting schedule cascades to all bookings
- ? Cannot delete sport with existing schedules

### Data Validation
- ? EndTime must be after StartTime
- ? MaxPlayers: 1-100
- ? Venue: 3-200 characters
- ? Guest bookings require GuestName

## Error Responses

### 400 Bad Request
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "Bad Request",
  "status": 400,
  "errors": {
    "": ["This schedule is full. No spots remaining."]
  }
}
```

### 401 Unauthorized
```json
{
  "type": "https://tools.ietf.org/html/rfc7235#section-3.1",
  "title": "Unauthorized",
  "status": 401
}
```

### 403 Forbidden
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.3",
  "title": "Forbidden",
  "status": 403
}
```

### 404 Not Found
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.4",
  "title": "Not Found",
  "status": 404
}
```

## Database Schema

```
Sport
?? Id (PK)
?? Name (Unique)
?? IconUrl

Schedule
?? Id (PK)
?? SportId (FK ? Sport)
?? Venue
?? StartTime
?? EndTime
?? MaxPlayers
?? EquipmentDetails
?? CreatedByAdminId (FK ? User)
?? CreatedAt

Booking
?? Id (PK)
?? ScheduleId (FK ? Schedule, Cascade Delete)
?? UserId (FK ? User, Nullable)
?? GuestName (Required if UserId is null)
?? GuestMobile
?? BookingTime

User (existing)
?? Id (PK)
?? Name
?? Email (Unique)
?? Phone
?? PasswordHash
?? Role
?? CreatedAt
```

## Testing Checklist

- [ ] Admin can login
- [ ] Admin can create sports
- [ ] Admin can create single schedule
- [ ] Admin can create recurring schedule
- [ ] Public can view all schedules
- [ ] Public can filter schedules by sport
- [ ] Public can filter schedules by venue
- [ ] Public can view schedule with participants
- [ ] Guest can join a schedule
- [ ] User can register and login
- [ ] Registered user can join a schedule
- [ ] Registered user cannot join same schedule twice
- [ ] User cannot join full schedule
- [ ] User can view their bookings
- [ ] User can cancel their booking (>2 hours before)
- [ ] Admin can update schedule
- [ ] Admin can delete schedule
- [ ] Admin can view all bookings for a schedule

## Next Steps

1. **Run the application**: `dotnet run`
2. **Test with PowerShell**: `.\test-sports-api.ps1`
3. **Explore with Scalar UI**: https://localhost:7186/scalar/v1
4. **Create your first schedule** via API or Scalar UI
5. **Invite users to join** and test the booking flow

## Support

For issues or questions:
- Check `SPORTS_SCHEDULING_IMPLEMENTATION.md` for detailed documentation
- Review API endpoints in Scalar UI
- Check error responses for validation messages
