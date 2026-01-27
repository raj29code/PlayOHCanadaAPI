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

        var adminIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(adminIdStr, out int adminId))
        {
            return Unauthorized();
        }

        var schedules = new List<Schedule>();

        if (dto.Recurrence?.IsRecurring == true && dto.Recurrence.Frequency.HasValue && dto.Recurrence.EndDate.HasValue)
        {
            // Generate recurring schedules
            var currentDate = dto.StartTime;
            var endDate = dto.Recurrence.EndDate.Value;
            var dayInterval = (int)dto.Recurrence.Frequency.Value;

            while (currentDate <= endDate)
            {
                var schedule = CreateScheduleEntity(dto, adminId, currentDate);
                schedules.Add(schedule);
                currentDate = currentDate.AddDays(dayInterval);
            }
        }
        else
        {
            // Single schedule
            var schedule = CreateScheduleEntity(dto, adminId, dto.StartTime);
            schedules.Add(schedule);
        }

        _context.Schedules.AddRange(schedules);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetSchedule), new { id = schedules[0].Id }, schedules);
    }

    /// <summary>
    /// Get schedules with filtering options
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<ScheduleResponseDto>>> GetSchedules(
        [FromQuery] int? sportId,
        [FromQuery] string? venue,
        [FromQuery] DateTime? startDate,
        [FromQuery] DateTime? endDate,
        [FromQuery] bool includeParticipants = false)
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

        var response = schedules.Select(s => new ScheduleResponseDto
        {
            Id = s.Id,
            SportId = s.SportId,
            SportName = s.Sport.Name,
            SportIconUrl = s.Sport.IconUrl,
            Venue = s.Venue,
            StartTime = s.StartTime,
            EndTime = s.EndTime,
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

        return Ok(response);
    }

    /// <summary>
    /// Get a specific schedule by ID with participant list
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<ScheduleResponseDto>> GetSchedule(int id)
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
            StartTime = schedule.StartTime,
            EndTime = schedule.EndTime,
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

        if (dto.StartTime.HasValue)
        {
            schedule.StartTime = dto.StartTime.Value;
        }

        if (dto.EndTime.HasValue)
        {
            // Validate EndTime is after StartTime
            if (dto.EndTime.Value <= schedule.StartTime)
            {
                return BadRequest("EndTime must be after StartTime");
            }
            schedule.EndTime = dto.EndTime.Value;
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

    private Schedule CreateScheduleEntity(CreateScheduleDto dto, int adminId, DateTime startTime)
    {
        var duration = dto.EndTime - dto.StartTime;
        return new Schedule
        {
            SportId = dto.SportId,
            Venue = dto.Venue,
            StartTime = startTime,
            EndTime = startTime.Add(duration),
            MaxPlayers = dto.MaxPlayers,
            EquipmentDetails = dto.EquipmentDetails,
            CreatedByAdminId = adminId
        };
    }
}
