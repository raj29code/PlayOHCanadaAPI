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
    public async Task<ActionResult<Booking>> JoinSchedule(JoinScheduleDto dto)
    {
        // Validate schedule exists
        var schedule = await _context.Schedules
            .Include(s => s.Bookings)
            .FirstOrDefaultAsync(s => s.Id == dto.ScheduleId);

        if (schedule == null)
        {
            return NotFound("Schedule not found");
        }

        // Check if schedule is in the past
        if (schedule.StartTime <= DateTime.UtcNow)
        {
            return BadRequest("Cannot book a schedule that has already started or passed");
        }

        // Capacity check - validate current bookings < max players
        if (schedule.Bookings.Count >= schedule.MaxPlayers)
        {
            return BadRequest("This schedule is full. No spots remaining.");
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
                return BadRequest("You have already booked this schedule");
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
                return BadRequest("GuestName is required for guest bookings");
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

        // Load navigation properties for response
        await _context.Entry(booking).Reference(b => b.Schedule).LoadAsync();
        await _context.Entry(booking.Schedule).Reference(s => s.Sport).LoadAsync();

        return CreatedAtAction(nameof(GetBooking), new { id = booking.Id }, booking);
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
    /// Get all bookings for the authenticated user
    /// </summary>
    [HttpGet("my-bookings")]
    [Authorize]
    public async Task<ActionResult<List<Booking>>> GetMyBookings()
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdStr, out int userId))
        {
            return Unauthorized();
        }

        var bookings = await _context.Bookings
            .Include(b => b.Schedule)
                .ThenInclude(s => s.Sport)
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.BookingTime)
            .ToListAsync();

        return Ok(bookings);
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
            return NotFound();
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

        // Optional: Prevent cancellation too close to start time
        var hoursUntilStart = (booking.Schedule.StartTime - DateTime.UtcNow).TotalHours;
        if (hoursUntilStart < 2)
        {
            return BadRequest("Cannot cancel booking less than 2 hours before start time");
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
