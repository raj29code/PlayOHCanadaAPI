using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PlayOhCanadaAPI.Data;
using PlayOhCanadaAPI.Models;
using PlayOhCanadaAPI.Models.DTOs;
using System.Security.Claims;

namespace PlayOhCanadaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SchedulesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public SchedulesController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Create a new schedule (single or recurring) - Admin only
    /// </summary>
    [HttpPost]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<List<Schedule>>> CreateSchedule(CreateScheduleDto dto)
    {
        // Validate sport exists
        if (!await _context.Sports.AnyAsync(s => s.Id == dto.SportId))
        {
            return BadRequest("Invalid SportId");
        }

        // Validate times
        if (dto.EndTime <= dto.StartTime)
        {
            return BadRequest("EndTime must be after StartTime");
        }

        // Validate recurrence settings
        if (dto.Recurrence?.IsRecurring == true)
        {
            if (!dto.Recurrence.Frequency.HasValue)
            {
                return BadRequest("Frequency is required for recurring schedules");
            }

            if (!dto.Recurrence.EndDate.HasValue)
            {
                return BadRequest("EndDate is required for recurring schedules");
            }

            if (dto.Recurrence.EndDate.Value < dto.StartDate)
            {
                return BadRequest("Recurrence EndDate must be on or after StartDate");
            }

            // Validate Weekly recurrence has days specified
            if ((dto.Recurrence.Frequency == RecurrenceFrequency.Weekly || 
                 dto.Recurrence.Frequency == RecurrenceFrequency.BiWeekly) && 
                (dto.Recurrence.DaysOfWeek == null || !dto.Recurrence.DaysOfWeek.Any()))
            {
                return BadRequest("DaysOfWeek is required for Weekly and BiWeekly recurrence");
            }
        }

        var adminIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(adminIdStr, out int adminId))
        {
            return Unauthorized();
        }

        var schedules = new List<Schedule>();

        if (dto.Recurrence?.IsRecurring == true && dto.Recurrence.Frequency.HasValue && dto.Recurrence.EndDate.HasValue)
        {
            // Generate recurring schedules
            schedules = GenerateRecurringSchedules(dto, adminId);
        }
        else
        {
            // Single schedule
            schedules.Add(CreateScheduleEntity(dto, adminId, dto.StartDate));
        }

        if (!schedules.Any())
        {
            return BadRequest("No schedules were generated. Please check your recurrence settings.");
        }

        _context.Schedules.AddRange(schedules);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetSchedule), new { id = schedules[0].Id }, schedules);
    }

    /// <summary>
    /// Get schedules with filtering options - Requires authentication to exclude already-joined schedules
    /// </summary>
    /// <remarks>
    /// This endpoint can be accessed by anyone, but authentication is required to use excludeJoined parameter.
    /// It shows all available schedules that users can join.
    /// Use filters to find specific schedules.
    /// </remarks>
    [HttpGet]
    public async Task<ActionResult<List<ScheduleResponseDto>>> GetSchedules(
        [FromQuery] int? sportId,
        [FromQuery] string? venue,
        [FromQuery] DateTime? startDate,
        [FromQuery] DateTime? endDate,
        [FromQuery] int? timezoneOffsetMinutes,
        [FromQuery] bool includeParticipants = false,
        [FromQuery] bool availableOnly = false,
        [FromQuery] bool excludeJoined = false)
    {
        var query = _context.Schedules
            .Include(s => s.Sport)
            .Include(s => s.Bookings)
                .ThenInclude(b => b.User)
            .AsQueryable();

        // Apply filters
        if (sportId.HasValue)
        {
            query = query.Where(s => s.SportId == sportId.Value);
        }

        if (!string.IsNullOrWhiteSpace(venue))
        {
            query = query.Where(s => s.Venue.Contains(venue));
        }

        if (startDate.HasValue)
        {
            query = query.Where(s => s.StartTime >= startDate.Value);
        }

        if (endDate.HasValue)
        {
            query = query.Where(s => s.StartTime <= endDate.Value);
        }

        // Get only future schedules by default
        query = query.Where(s => s.StartTime > DateTime.UtcNow);

        var schedules = await query
            .OrderBy(s => s.StartTime)
            .ToListAsync();

        // Filter out schedules user has already joined
        if (excludeJoined)
        {
            if (!User.Identity?.IsAuthenticated ?? true)
            {
                return Unauthorized(new { message = "Authentication required to use excludeJoined filter" });
            }

            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId))
            {
                return Unauthorized();
            }

            // Get all schedule IDs the user has already joined
            var joinedScheduleIds = await _context.Bookings
                .Where(b => b.UserId == userId)
                .Select(b => b.ScheduleId)
                .ToListAsync();

            // Filter out already-joined schedules
            schedules = schedules.Where(s => !joinedScheduleIds.Contains(s.Id)).ToList();
        }

        var response = schedules.Select(s => new ScheduleResponseDto
        {
            Id = s.Id,
            SportId = s.SportId,
            SportName = s.Sport.Name,
            SportIconUrl = s.Sport.IconUrl,
            Venue = s.Venue,
            // Convert UTC times to local timezone if offset provided
            StartTime = timezoneOffsetMinutes.HasValue 
                ? s.StartTime.AddMinutes(timezoneOffsetMinutes.Value) 
                : s.StartTime,
            EndTime = timezoneOffsetMinutes.HasValue 
                ? s.EndTime.AddMinutes(timezoneOffsetMinutes.Value) 
                : s.EndTime,
            MaxPlayers = s.MaxPlayers,
            CurrentPlayers = s.Bookings.Count,
            SpotsRemaining = s.MaxPlayers - s.Bookings.Count,
            EquipmentDetails = s.EquipmentDetails,
            Participants = includeParticipants ? s.Bookings.Select(b => new ParticipantDto
            {
                Name = b.User != null ? b.User.Name : b.GuestName ?? "Guest",
                BookingTime = b.BookingTime
            }).ToList() : new List<ParticipantDto>()
        }).ToList();

        // Filter for schedules with available spots if requested
        if (availableOnly)
        {
            response = response.Where(s => s.SpotsRemaining > 0).ToList();
        }

        return Ok(response);
    }

    /// <summary>
    /// Get a specific schedule by ID with participant list - Available to all users (no authentication required)
    /// </summary>
    /// <remarks>
    /// This endpoint is public and can be accessed by anyone.
    /// Shows complete schedule details including available spots and participant list.
    /// </remarks>
    [HttpGet("{id}")]
    public async Task<ActionResult<ScheduleResponseDto>> GetSchedule(
        int id,
        [FromQuery] int? timezoneOffsetMinutes)
    {
        var schedule = await _context.Schedules
            .Include(s => s.Sport)
            .Include(s => s.Bookings)
                .ThenInclude(b => b.User)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (schedule == null)
        {
            return NotFound();
        }

        var response = new ScheduleResponseDto
        {
            Id = schedule.Id,
            SportId = schedule.SportId,
            SportName = schedule.Sport.Name,
            SportIconUrl = schedule.Sport.IconUrl,
            Venue = schedule.Venue,
            // Convert UTC times to local timezone if offset provided
            StartTime = timezoneOffsetMinutes.HasValue 
                ? schedule.StartTime.AddMinutes(timezoneOffsetMinutes.Value) 
                : schedule.StartTime,
            EndTime = timezoneOffsetMinutes.HasValue 
                ? schedule.EndTime.AddMinutes(timezoneOffsetMinutes.Value) 
                : schedule.EndTime,
            MaxPlayers = schedule.MaxPlayers,
            CurrentPlayers = schedule.Bookings.Count,
            SpotsRemaining = schedule.MaxPlayers - schedule.Bookings.Count,
            EquipmentDetails = schedule.EquipmentDetails,
            Participants = schedule.Bookings.Select(b => new ParticipantDto
            {
                Name = b.User != null ? b.User.Name : b.GuestName ?? "Guest",
                BookingTime = b.BookingTime
            }).ToList()
        };

        return Ok(response);
    }

    /// <summary>
    /// Update a schedule - Admin only
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> UpdateSchedule(int id, UpdateScheduleDto dto)
    {
        var schedule = await _context.Schedules.FindAsync(id);
        if (schedule == null)
        {
            return NotFound();
        }

        // Update only provided fields
        if (!string.IsNullOrWhiteSpace(dto.Venue))
        {
            schedule.Venue = dto.Venue;
        }

        // Handle date update
        if (dto.Date.HasValue)
        {
            var currentTime = TimeOnly.FromDateTime(schedule.StartTime);
            var localDateTime = dto.Date.Value.ToDateTime(currentTime);
            schedule.StartTime = DateTime.SpecifyKind(localDateTime.AddMinutes(-dto.TimezoneOffsetMinutes), DateTimeKind.Utc);
            
            var currentEndTime = TimeOnly.FromDateTime(schedule.EndTime);
            var localEndTime = dto.Date.Value.ToDateTime(currentEndTime);
            schedule.EndTime = DateTime.SpecifyKind(localEndTime.AddMinutes(-dto.TimezoneOffsetMinutes), DateTimeKind.Utc);
        }

        // Handle start time update
        if (dto.StartTime.HasValue)
        {
            var currentDate = DateOnly.FromDateTime(schedule.StartTime);
            var localDateTime = currentDate.ToDateTime(dto.StartTime.Value);
            schedule.StartTime = DateTime.SpecifyKind(localDateTime.AddMinutes(-dto.TimezoneOffsetMinutes), DateTimeKind.Utc);
        }

        // Handle end time update
        if (dto.EndTime.HasValue)
        {
            var currentDate = DateOnly.FromDateTime(schedule.EndTime);
            var localDateTime = currentDate.ToDateTime(dto.EndTime.Value);
            schedule.EndTime = DateTime.SpecifyKind(localDateTime.AddMinutes(-dto.TimezoneOffsetMinutes), DateTimeKind.Utc);
            
            // Validate EndTime is after StartTime
            if (schedule.EndTime <= schedule.StartTime)
            {
                return BadRequest("EndTime must be after StartTime");
            }
        }

        if (dto.MaxPlayers.HasValue)
        {
            // Check if new max is less than current bookings
            var currentBookings = await _context.Bookings.CountAsync(b => b.ScheduleId == id);
            if (dto.MaxPlayers.Value < currentBookings)
            {
                return BadRequest($"Cannot reduce MaxPlayers below current bookings count ({currentBookings})");
            }
            schedule.MaxPlayers = dto.MaxPlayers.Value;
        }

        if (dto.EquipmentDetails != null)
        {
            schedule.EquipmentDetails = dto.EquipmentDetails;
        }

        await _context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Delete/Cancel a schedule - Admin only
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> DeleteSchedule(int id)
    {
        var schedule = await _context.Schedules
            .Include(s => s.Bookings)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (schedule == null)
        {
            return NotFound();
        }

        // Check if there are existing bookings
        if (schedule.Bookings.Any())
        {
            // TODO: Implement notification system to alert users
            // For now, just log the count
            var bookingCount = schedule.Bookings.Count;
            // In production, you would send notifications here
        }

        _context.Schedules.Remove(schedule);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Delete all schedules created by the currently authenticated admin - Admin only
    /// </summary>
    [HttpDelete("my-schedules")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> DeleteMySchedules()
    {
        var adminIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(adminIdStr, out int adminId))
        {
            return Unauthorized();
        }

        var schedules = await _context.Schedules
            .Include(s => s.Bookings)
            .Where(s => s.CreatedByAdminId == adminId)
            .ToListAsync();

        if (!schedules.Any())
        {
            return NotFound(new { message = "No schedules found for this admin" });
        }

        var totalSchedules = schedules.Count;
        var totalBookings = schedules.Sum(s => s.Bookings.Count);

        // TODO: Implement notification system to alert users
        // For now, just count the affected bookings
        // In production, you would send notifications to all affected users

        _context.Schedules.RemoveRange(schedules);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = "All schedules deleted successfully",
            deletedSchedules = totalSchedules,
            affectedBookings = totalBookings
        });
    }

    /// <summary>
    /// Delete all schedules created by a specific admin - Admin only (requires same admin or super admin)
    /// </summary>
    [HttpDelete("admin/{adminId}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> DeleteSchedulesByAdmin(int adminId)
    {
        var currentAdminIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(currentAdminIdStr, out int currentAdminId))
        {
            return Unauthorized();
        }

        // Only allow admins to delete their own schedules
        // In future, could add super admin role check here
        if (currentAdminId != adminId)
        {
            return Forbid("You can only delete your own schedules");
        }

        var schedules = await _context.Schedules
            .Include(s => s.Bookings)
            .Where(s => s.CreatedByAdminId == adminId)
            .ToListAsync();

        if (!schedules.Any())
        {
            return NotFound(new { message = $"No schedules found for admin ID {adminId}" });
        }

        var totalSchedules = schedules.Count;
        var totalBookings = schedules.Sum(s => s.Bookings.Count);

        // TODO: Implement notification system to alert users
        // In production, send notifications to all affected users

        _context.Schedules.RemoveRange(schedules);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = $"All schedules by admin {adminId} deleted successfully",
            deletedSchedules = totalSchedules,
            affectedBookings = totalBookings
        });
    }

    /// <summary>
    /// Get all available venues - Public endpoint
    /// </summary>
    /// <remarks>
    /// Returns a list of all unique venues where schedules are available.
    /// Useful for displaying venue options in filters or search.
    /// </remarks>
    [HttpGet("venues")]
    public async Task<ActionResult<List<VenueDto>>> GetVenues(
        [FromQuery] int? timezoneOffsetMinutes)
    {
        // Get all future schedules
        var schedules = await _context.Schedules
            .Include(s => s.Sport)
            .Include(s => s.Bookings)
            .Where(s => s.StartTime > DateTime.UtcNow)
            .ToListAsync();

        // Group by venue and calculate statistics
        var venues = schedules
            .GroupBy(s => s.Venue)
            .Select(g => new VenueDto
            {
                Name = g.Key,
                ScheduleCount = g.Count(),
                AvailableSchedules = g.Count(s => s.Bookings.Count < s.MaxPlayers),
                Sports = g.Select(s => s.Sport.Name).Distinct().ToList(),
                NextScheduleTime = timezoneOffsetMinutes.HasValue
                    ? g.Min(s => s.StartTime).AddMinutes(timezoneOffsetMinutes.Value)
                    : g.Min(s => s.StartTime)
            })
            .OrderBy(v => v.Name)
            .ToList();

        return Ok(venues);
    }

    /// <summary>
    /// Debug endpoint - Get all venues including past schedules (for troubleshooting)
    /// </summary>
    [HttpGet("venues/debug")]
    public async Task<ActionResult<object>> GetVenuesDebug(
        [FromQuery] int? timezoneOffsetMinutes)
    {
        var now = DateTime.UtcNow;
        
        // Get ALL schedules (including past)
        var allSchedules = await _context.Schedules
            .Include(s => s.Sport)
            .Include(s => s.Bookings)
            .ToListAsync();

        var futureSchedules = allSchedules.Where(s => s.StartTime > now).ToList();
        var pastSchedules = allSchedules.Where(s => s.StartTime <= now).ToList();

        // Group by venue (all schedules)
        var allVenues = allSchedules
            .GroupBy(s => s.Venue)
            .Select(g => new
            {
                Name = g.Key,
                TotalSchedules = g.Count(),
                FutureSchedules = g.Count(s => s.StartTime > now),
                PastSchedules = g.Count(s => s.StartTime <= now),
                OldestSchedule = g.Min(s => s.StartTime),
                NewestSchedule = g.Max(s => s.StartTime),
                Sports = g.Select(s => s.Sport.Name).Distinct().ToList()
            })
            .OrderBy(v => v.Name)
            .ToList();

        return Ok(new
        {
            currentTimeUtc = now,
            currentTimeLocal = timezoneOffsetMinutes.HasValue 
                ? now.AddMinutes(timezoneOffsetMinutes.Value) 
                : now,
            timezoneOffset = timezoneOffsetMinutes,
            totalSchedules = allSchedules.Count,
            futureSchedulesCount = futureSchedules.Count,
            pastSchedulesCount = pastSchedules.Count,
            venues = allVenues
        });
    }

    private Schedule CreateScheduleEntity(CreateScheduleDto dto, int adminId, DateOnly scheduleDate)
    {
        // Combine date and time
        var localDateTime = scheduleDate.ToDateTime(dto.StartTime);
        var localEndTime = scheduleDate.ToDateTime(dto.EndTime);
        
        // Convert to UTC by subtracting the timezone offset
        var utcStartTime = localDateTime.AddMinutes(-dto.TimezoneOffsetMinutes);
        var utcEndTime = localEndTime.AddMinutes(-dto.TimezoneOffsetMinutes);
        
        return new Schedule
        {
            SportId = dto.SportId,
            Venue = dto.Venue,
            StartTime = DateTime.SpecifyKind(utcStartTime, DateTimeKind.Utc),
            EndTime = DateTime.SpecifyKind(utcEndTime, DateTimeKind.Utc),
            MaxPlayers = dto.MaxPlayers,
            EquipmentDetails = dto.EquipmentDetails,
            CreatedByAdminId = adminId
        };
    }

    private List<Schedule> GenerateRecurringSchedules(CreateScheduleDto dto, int adminId)
    {
        var schedules = new List<Schedule>();
        var recurrence = dto.Recurrence!;
        
        switch (recurrence.Frequency!.Value)
        {
            case RecurrenceFrequency.Daily:
                schedules = GenerateDailySchedules(dto, adminId);
                break;
                
            case RecurrenceFrequency.Weekly:
                schedules = GenerateWeeklySchedules(dto, adminId);
                break;
                
            case RecurrenceFrequency.BiWeekly:
                schedules = GenerateBiWeeklySchedules(dto, adminId);
                break;
                
            case RecurrenceFrequency.Monthly:
                schedules = GenerateMonthlySchedules(dto, adminId);
                break;
        }
        
        return schedules;
    }

    private List<Schedule> GenerateDailySchedules(CreateScheduleDto dto, int adminId)
    {
        var schedules = new List<Schedule>();
        var currentDate = dto.StartDate;
        var endDate = dto.Recurrence!.EndDate!.Value;

        while (currentDate <= endDate)
        {
            schedules.Add(CreateScheduleEntity(dto, adminId, currentDate));
            currentDate = currentDate.AddDays(1);
        }

        return schedules;
    }

    private List<Schedule> GenerateWeeklySchedules(CreateScheduleDto dto, int adminId)
    {
        var schedules = new List<Schedule>();
        var daysOfWeek = dto.Recurrence!.DaysOfWeek!;
        var currentDate = dto.StartDate;
        var endDate = dto.Recurrence.EndDate!.Value;

        while (currentDate <= endDate)
        {
            // Check if current day is in the specified days of week
            if (daysOfWeek.Contains(currentDate.DayOfWeek))
            {
                schedules.Add(CreateScheduleEntity(dto, adminId, currentDate));
            }
            currentDate = currentDate.AddDays(1);
        }

        return schedules;
    }

    private List<Schedule> GenerateBiWeeklySchedules(CreateScheduleDto dto, int adminId)
    {
        var schedules = new List<Schedule>();
        var daysOfWeek = dto.Recurrence!.DaysOfWeek ?? new List<DayOfWeek>();
        var currentDate = dto.StartDate;
        var endDate = dto.Recurrence.EndDate!.Value;

        // If no specific days specified, use the start day
        if (!daysOfWeek.Any())
        {
            daysOfWeek.Add(currentDate.DayOfWeek);
        }

        int weekCount = 0;

        while (currentDate <= endDate)
        {
            // Only generate schedules on even weeks (0, 2, 4, etc.)
            if (weekCount % 2 == 0 && daysOfWeek.Contains(currentDate.DayOfWeek))
            {
                schedules.Add(CreateScheduleEntity(dto, adminId, currentDate));
            }

            currentDate = currentDate.AddDays(1);
            
            // Increment week count when we pass to Monday
            if (currentDate.DayOfWeek == DayOfWeek.Monday)
            {
                weekCount++;
            }
        }

        return schedules;
    }

    private List<Schedule> GenerateMonthlySchedules(CreateScheduleDto dto, int adminId)
    {
        var schedules = new List<Schedule>();
        var startDate = dto.StartDate;
        var endDate = dto.Recurrence!.EndDate!.Value;
        var dayOfMonth = dto.StartDate.Day;

        var currentYear = startDate.Year;
        var currentMonth = startDate.Month;

        while (true)
        {
            // Get the target day for the current month
            var daysInMonth = DateTime.DaysInMonth(currentYear, currentMonth);
            var targetDay = Math.Min(dayOfMonth, daysInMonth);
            var scheduleDate = new DateOnly(currentYear, currentMonth, targetDay);

            // Only add if within range
            if (scheduleDate < startDate)
            {
                // Skip this month, move to next
            }
            else if (scheduleDate > endDate)
            {
                break;
            }
            else
            {
                schedules.Add(CreateScheduleEntity(dto, adminId, scheduleDate));
            }

            // Move to next month
            currentMonth++;
            if (currentMonth > 12)
            {
                currentMonth = 1;
                currentYear++;
            }
        }

        return schedules;
    }
}
