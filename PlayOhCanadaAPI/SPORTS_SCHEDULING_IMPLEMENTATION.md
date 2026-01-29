# Sports Scheduling System - Implementation Summary

## Overview
This implementation adds a complete sports scheduling and booking system to the PlayOhCanada API with three main modules:
1. Schedule Management (Admin)
2. Discovery & Socializing (All Users)
3. Booking System (Transactional)

## Entities Created

### 1. Sport (`Models\Sport.cs`)
- **Purpose**: Represents different types of sports (Tennis, Badminton, etc.)
- **Fields**:
  - `Id` (int, Primary Key)
  - `Name` (string, required, unique)
  - `IconUrl` (string, optional)
- **Relationships**: One-to-Many with Schedule

### 2. Schedule (`Models\Schedule.cs`)
- **Purpose**: Represents a specific time slot for a game
- **Fields**:
  - `Id` (int, Primary Key)
  - `SportId` (int, Foreign Key)
  - `Venue` (string, required)
  - `StartTime` (DateTime, required)
  - `EndTime` (DateTime, required)
  - `MaxPlayers` (int, required, 1-100)
  - `EquipmentDetails` (string, optional)
  - `CreatedByAdminId` (int, Foreign Key)
  - `CreatedAt` (DateTime, auto-generated)
- **Relationships**: 
  - Many-to-One with Sport
  - Many-to-One with User (Admin)
  - One-to-Many with Booking

### 3. Booking (`Models\Booking.cs`)
- **Purpose**: Represents a user or guest joining a schedule
- **Fields**:
  - `Id` (int, Primary Key)
  - `ScheduleId` (int, Foreign Key)
  - `BookingTime` (DateTime, auto-generated)
  - `UserId` (int?, Foreign Key, nullable for guests)
  - `GuestName` (string, optional, required if UserId is null)
  - `GuestMobile` (string, optional)
- **Constraints**:
  - A registered user cannot book the same schedule twice (unique index on ScheduleId + UserId)
  - Either UserId OR GuestName must be present (check constraint)
- **Relationships**:
  - Many-to-One with Schedule
  - Many-to-One with User (optional)

## DTOs Created

### Request DTOs
1. **CreateSportDto** - For creating sports
2. **CreateScheduleDto** - For creating single or recurring schedules
   - Includes `RecurrenceDto` for handling recurring events
3. **UpdateScheduleDto** - For updating schedule details
4. **JoinScheduleDto** - For booking a schedule (supports both registered and guest users)

### Response DTOs
1. **ScheduleResponseDto** - Rich schedule information with participant count
2. **ParticipantDto** - Participant information in schedule responses

### Supporting Types
- **RecurrenceDto** - Defines recurrence patterns
- **RecurrenceFrequency** (enum) - Daily, Weekly, BiWeekly, Monthly

## API Endpoints

### SportsController (`/api/sports`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/sports` | Public | Get all sports |
| GET | `/api/sports/{id}` | Public | Get a specific sport |
| POST | `/api/sports` | Admin | Create a new sport |
| DELETE | `/api/sports/{id}` | Admin | Delete a sport |

### SchedulesController (`/api/schedules`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/schedules` | Admin | Create single or recurring schedules |
| GET | `/api/schedules` | Public | Get schedules with filtering |
| GET | `/api/schedules/{id}` | Public | Get schedule details with participants |
| PUT | `/api/schedules/{id}` | Admin | Update schedule details |
| DELETE | `/api/schedules/{id}` | Admin | Cancel/delete a schedule |

**Query Parameters for GET /api/schedules:**
- `sportId` (int?) - Filter by sport
- `venue` (string?) - Filter by venue (contains search)
- `startDate` (DateTime?) - Filter schedules starting after this date
- `endDate` (DateTime?) - Filter schedules starting before this date
- `includeParticipants` (bool) - Include participant list in response

### BookingsController (`/api/bookings`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/bookings/join` | Optional | Join a schedule (registered or guest) |
| GET | `/api/bookings/{id}` | Public | Get a specific booking |
| GET | `/api/bookings/my-bookings` | User | Get all bookings for current user |
| DELETE | `/api/bookings/{id}` | User | Cancel a booking |
| GET | `/api/bookings/schedule/{scheduleId}` | Admin | Get all bookings for a schedule |

## Key Features Implemented

### 1. Recurring Schedule Creation
- Admin can create recurring schedules with frequency patterns (Daily, Weekly, BiWeekly, Monthly)
- System automatically generates individual schedule entries for each occurrence
- Duration between StartTime and EndTime is preserved for each occurrence

### 2. Advanced Filtering
- Filter schedules by sport, venue, and date range
- Only shows future schedules by default
- Includes CurrentPlayers count and SpotsRemaining in response

### 3. Capacity Management
- Validates that bookings don't exceed MaxPlayers
- Returns clear error messages when schedules are full
- Prevents duplicate bookings by registered users

### 4. Guest Booking Support
- Allows non-authenticated users to book schedules
- Requires GuestName for guest bookings
- Optional GuestMobile field for contact information

### 5. Social Visibility
- Participant lists show who has joined
- Displays registered user names or "Guest" for anonymous bookings
- Helps users decide if they want to join based on the group

### 6. Business Rules Enforced
- Cannot book schedules that have already started
- Cannot reduce MaxPlayers below current booking count
- Cannot cancel bookings within 2 hours of start time
- Admin schedules soft-delete consideration (with booking notification TODO)
- Cannot delete sports with existing schedules

## Database Configuration

### Indexes Created
- `Sport.Name` - Unique index for sport names
- `Schedule.(SportId, StartTime)` - Composite index for efficient filtering
- `Booking.(ScheduleId, UserId)` - Unique composite index (with filter for non-null UserId)

### Constraints
- Check constraint on Booking: Either UserId or GuestName must be present
- Cascade delete on Schedule deletion (bookings are deleted)
- Restrict delete on Sport and User references

## Next Steps

### 1. Create Migration
```bash
dotnet ef migrations add AddSportsSchedulingSystem
```

### 2. Apply Migration
```bash
dotnet ef database update
```
Or just run the application - it will auto-migrate in development mode.

### 3. Seed Sample Sports
Create some initial sports via the API or add seed data:
```csharp
// In Program.cs after admin user seeding
if (!await dbContext.Sports.AnyAsync())
{
    var sports = new[]
    {
        new Sport { Name = "Tennis", IconUrl = "https://example.com/icons/tennis.png" },
        new Sport { Name = "Badminton", IconUrl = "https://example.com/icons/badminton.png" },
        new Sport { Name = "Basketball", IconUrl = "https://example.com/icons/basketball.png" },
        new Sport { Name = "Soccer", IconUrl = "https://example.com/icons/soccer.png" }
    };
    dbContext.Sports.AddRange(sports);
    await dbContext.SaveChangesAsync();
}
```

## Testing the API

### 1. Create a Sport (Admin)
```bash
POST /api/sports
Authorization: Bearer {admin_token}
{
  "name": "Tennis",
  "iconUrl": "https://example.com/icons/tennis.png"
}
```

### 2. Create a Recurring Schedule (Admin)
```bash
POST /api/schedules
Authorization: Bearer {admin_token}
{
  "sportId": 1,
  "venue": "Central Park Tennis Courts",
  "startTime": "2024-12-26T18:00:00Z",
  "endTime": "2024-12-26T20:00:00Z",
  "maxPlayers": 6,
  "equipmentDetails": "Rackets provided",
  "recurrence": {
    "isRecurring": true,
    "frequency": 7,  // Weekly
    "endDate": "2025-03-31T00:00:00Z"
  }
}
```

### 3. Browse Schedules (Public)
```bash
GET /api/schedules?sportId=1&venue=Central
```

### 4. Join a Schedule (Registered User)
```bash
POST /api/bookings/join
Authorization: Bearer {user_token}
{
  "scheduleId": 1
}
```

### 5. Join a Schedule (Guest)
```bash
POST /api/bookings/join
{
  "scheduleId": 1,
  "guestName": "John Doe",
  "guestMobile": "+1234567890"
}
```

### 6. View Schedule Details with Participants
```bash
GET /api/schedules/1
```

## Additional Enhancements (Future)

1. **Notification System**: Implement email/SMS notifications when schedules are cancelled
2. **Waiting List**: Allow users to join a waiting list when schedule is full
3. **Rating System**: Let users rate games and other participants
4. **Payment Integration**: Add paid events support
5. **Weather Integration**: Show weather forecast for outdoor venues
6. **Map Integration**: Display venue locations on a map
7. **Calendar Export**: Allow users to export schedules to their calendars
8. **Reminder System**: Send reminders before scheduled games
9. **Chat Feature**: Enable participants to communicate before games
10. **Analytics Dashboard**: Show admin statistics on popular sports, venues, etc.

## Security Considerations

- All admin operations require authentication with Admin role
- Users can only cancel their own bookings
- Guest bookings have no ownership - cannot be cancelled without admin intervention
- Schedule modifications are logged via CreatedAt timestamps
- Consider adding audit logging for admin actions

## Performance Optimizations

- Indexes on frequently queried fields (SportId, StartTime, Venue)
- Efficient filtering with database-level query composition
- Pagination should be added for large result sets (future enhancement)
- Consider caching for sports list (rarely changes)
