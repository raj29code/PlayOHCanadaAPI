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
public class BookingsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public BookingsController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Join a schedule (for both registered and guest users)
    /// </summary>
    [HttpPost("join")]
    public async Task<ActionResult<BookingResponseDto>> JoinSchedule(JoinScheduleDto dto)
    {
        // Validate schedule exists
        var schedule = await _context.Schedules
            .Include(s => s.Bookings)
            .Include(s => s.Sport)
            .FirstOrDefaultAsync(s => s.Id == dto.ScheduleId);

        if (schedule == null)
        {
            return NotFound(new { message = "Schedule not found" });
        }

        // Check if schedule is in the past
        if (schedule.StartTime <= DateTime.UtcNow)
        {
            return BadRequest(new { message = "Cannot book a schedule that has already started or passed" });
        }

        // Capacity check - validate current bookings < max players
        if (schedule.Bookings.Count >= schedule.MaxPlayers)
        {
            return BadRequest(new { message = "This schedule is full. No spots remaining." });
        }

        Booking booking;

        // Check if user is authenticated
        if (User.Identity?.IsAuthenticated == true)
        {
            // Registered user booking
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId))
            {
                return Unauthorized();
            }

            // Check if user already booked this schedule
            if (await _context.Bookings.AnyAsync(b => b.ScheduleId == dto.ScheduleId && b.UserId == userId))
            {
                return BadRequest(new { message = "You have already booked this schedule" });
            }

            booking = new Booking
            {
                ScheduleId = dto.ScheduleId,
                UserId = userId,
                BookingTime = DateTime.UtcNow
            };
        }
        else
        {
            // Guest user booking
            if (string.IsNullOrWhiteSpace(dto.GuestName))
            {
                return BadRequest(new { message = "GuestName is required for guest bookings" });
            }

            booking = new Booking
            {
                ScheduleId = dto.ScheduleId,
                GuestName = dto.GuestName,
                GuestMobile = dto.GuestMobile,
                BookingTime = DateTime.UtcNow
            };
        }

        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();

        // Reload bookings count for current players
        var currentBookings = await _context.Bookings.CountAsync(b => b.ScheduleId == dto.ScheduleId);

        // Create response
        var response = new BookingResponseDto
        {
            Id = booking.Id,
            ScheduleId = schedule.Id,
            BookingTime = booking.BookingTime,
            SportName = schedule.Sport.Name,
            SportIconUrl = schedule.Sport.IconUrl,
            Venue = schedule.Venue,
            ScheduleStartTime = schedule.StartTime,
            ScheduleEndTime = schedule.EndTime,
            MaxPlayers = schedule.MaxPlayers,
            CurrentPlayers = currentBookings,
            EquipmentDetails = schedule.EquipmentDetails,
            IsPast = schedule.StartTime <= DateTime.UtcNow,
            CanCancel = (schedule.StartTime - DateTime.UtcNow).TotalHours >= 2
        };

        return CreatedAtAction(nameof(GetBooking), new { id = booking.Id }, response);
    }

    /// <summary>
    /// Get a specific booking by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<Booking>> GetBooking(int id)
    {
        var booking = await _context.Bookings
            .Include(b => b.Schedule)
                .ThenInclude(s => s.Sport)
            .Include(b => b.User)
            .FirstOrDefaultAsync(b => b.Id == id);

        if (booking == null)
        {
            return NotFound();
        }

        return booking;
    }

    /// <summary>
    /// Get all bookings for the authenticated user with timezone support
    /// </summary>
    [HttpGet("my-bookings")]
    [Authorize]
    public async Task<ActionResult<List<BookingResponseDto>>> GetMyBookings(
        [FromQuery] int? timezoneOffsetMinutes,
        [FromQuery] bool includeAll = false)
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdStr, out int userId))
        {
            return Unauthorized();
        }

        var query = _context.Bookings
            .Include(b => b.Schedule)
                .ThenInclude(s => s.Sport)
            .Include(b => b.Schedule.Bookings)
            .Where(b => b.UserId == userId);

        // Filter to only future bookings by default
        if (!includeAll)
        {
            query = query.Where(b => b.Schedule.StartTime > DateTime.UtcNow);
        }

        var bookings = await query
            .OrderBy(b => b.Schedule.StartTime)
            .ToListAsync();

        var response = bookings.Select(b => new BookingResponseDto
        {
            Id = b.Id,
            ScheduleId = b.ScheduleId,
            BookingTime = b.BookingTime,
            SportName = b.Schedule.Sport.Name,
            SportIconUrl = b.Schedule.Sport.IconUrl,
            Venue = b.Schedule.Venue,
            ScheduleStartTime = timezoneOffsetMinutes.HasValue
                ? b.Schedule.StartTime.AddMinutes(timezoneOffsetMinutes.Value)
                : b.Schedule.StartTime,
            ScheduleEndTime = timezoneOffsetMinutes.HasValue
                ? b.Schedule.EndTime.AddMinutes(timezoneOffsetMinutes.Value)
                : b.Schedule.EndTime,
            MaxPlayers = b.Schedule.MaxPlayers,
            CurrentPlayers = b.Schedule.Bookings.Count,
            EquipmentDetails = b.Schedule.EquipmentDetails,
            IsPast = b.Schedule.StartTime <= DateTime.UtcNow,
            CanCancel = (b.Schedule.StartTime - DateTime.UtcNow).TotalHours >= 2
        }).ToList();

        return Ok(response);
    }

    /// <summary>
    /// Cancel a booking (for registered users only)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> CancelBooking(int id)
    {
        var booking = await _context.Bookings
            .Include(b => b.Schedule)
            .FirstOrDefaultAsync(b => b.Id == id);

        if (booking == null)
        {
            return NotFound(new { message = "Booking not found" });
        }

        // Verify the user owns this booking
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdStr, out int userId))
        {
            return Unauthorized();
        }

        if (booking.UserId != userId)
        {
            return Forbid();
        }

        // Check if schedule has already started or passed
        if (booking.Schedule.StartTime <= DateTime.UtcNow)
        {
            return BadRequest(new { message = "Cannot cancel a booking for a schedule that has already started or passed" });
        }

        // Prevent cancellation too close to start time (2 hours)
        var hoursUntilStart = (booking.Schedule.StartTime - DateTime.UtcNow).TotalHours;
        if (hoursUntilStart < 2)
        {
            return BadRequest(new { message = "Cannot cancel booking less than 2 hours before start time" });
        }

        _context.Bookings.Remove(booking);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Get all bookings for a specific schedule (Admin only)
    /// </summary>
    [HttpGet("schedule/{scheduleId}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<List<Booking>>> GetScheduleBookings(int scheduleId)
    {
        var bookings = await _context.Bookings
            .Include(b => b.User)
            .Where(b => b.ScheduleId == scheduleId)
            .OrderBy(b => b.BookingTime)
            .ToListAsync();

        return Ok(bookings);
    }
}
