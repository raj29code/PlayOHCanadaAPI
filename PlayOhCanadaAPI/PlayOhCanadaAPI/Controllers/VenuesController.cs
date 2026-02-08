using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PlayOhCanadaAPI.Data;
using PlayOhCanadaAPI.Models;
using PlayOhCanadaAPI.Models.DTOs;

namespace PlayOhCanadaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VenuesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<VenuesController> _logger;

    public VenuesController(ApplicationDbContext context, ILogger<VenuesController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Get all unique venue names (for autocomplete/suggestions)
    /// </summary>
    /// <remarks>
    /// Returns a list of all unique venue names currently used in schedules.
    /// Useful for autocomplete when creating new schedules.
    /// </remarks>
    [HttpGet("suggestions")]
    public async Task<ActionResult<List<string>>> GetVenueSuggestions()
    {
        var venues = await _context.Schedules
            .Select(s => s.Venue)
            .Distinct()
            .OrderBy(v => v)
            .ToListAsync();

        return Ok(venues);
    }

    /// <summary>
    /// Get venue statistics - Admin only
    /// </summary>
    /// <remarks>
    /// Returns detailed statistics about each venue including schedule counts,
    /// booking information, and usage patterns.
    /// </remarks>
    [HttpGet("statistics")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<List<VenueStatisticsDto>>> GetVenueStatistics()
    {
        var now = DateTime.UtcNow;
        
        // Perform aggregation in the database for better performance
        var statistics = await _context.Schedules
            .GroupBy(s => s.Venue)
            .Select(g => new VenueStatisticsDto
            {
                VenueName = g.Key,
                TotalSchedules = g.Count(),
                FutureSchedules = g.Count(s => s.StartTime > now),
                PastSchedules = g.Count(s => s.StartTime <= now),
                TotalBookings = g.Sum(s => s.Bookings.Count),
                MostPopularSport = g
                    .GroupBy(s => s.Sport.Name)
                    .OrderByDescending(sg => sg.Count())
                    .Select(sg => sg.Key)
                    .FirstOrDefault() ?? "N/A",
                FirstScheduleDate = g.Min(s => s.StartTime),
                LastScheduleDate = g.Max(s => s.StartTime),
                AverageBookingsPerSchedule = g.Average(s => s.Bookings.Count)
            })
            .OrderBy(v => v.VenueName)
            .ToListAsync();

        return Ok(statistics);
    }

    /// <summary>
    /// Rename a venue across all schedules - Admin only
    /// </summary>
    /// <remarks>
    /// Updates the venue name for all schedules that match the old name.
    /// Use this to standardize venue names or fix typos.
    /// </remarks>
    [HttpPut("rename")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<VenueRenameResultDto>> RenameVenue(RenameVenueDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.OldName))
        {
            return BadRequest(new { message = "OldName is required" });
        }

        if (string.IsNullOrWhiteSpace(dto.NewName))
        {
            return BadRequest(new { message = "NewName is required" });
        }

        if (dto.OldName.Equals(dto.NewName, StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "New name must be different from old name" });
        }

        // Find all schedules with the old venue name
        var schedulesToUpdate = await _context.Schedules
            .Where(s => s.Venue == dto.OldName)
            .ToListAsync();

        if (!schedulesToUpdate.Any())
        {
            return NotFound(new { message = $"No schedules found with venue name '{dto.OldName}'" });
        }

        // Update venue name
        foreach (var schedule in schedulesToUpdate)
        {
            schedule.Venue = dto.NewName;
        }

        await _context.SaveChangesAsync();

        _logger.LogInformation(
            "Venue renamed from '{OldName}' to '{NewName}'. {Count} schedules updated.",
            dto.OldName, dto.NewName, schedulesToUpdate.Count);

        return Ok(new VenueRenameResultDto
        {
            OldName = dto.OldName,
            NewName = dto.NewName,
            SchedulesUpdated = schedulesToUpdate.Count,
            Message = $"Successfully renamed venue. {schedulesToUpdate.Count} schedule(s) updated."
        });
    }

    /// <summary>
    /// Merge multiple venues into one - Admin only
    /// </summary>
    /// <remarks>
    /// Consolidates multiple venue names into a single standardized name.
    /// Useful for fixing inconsistent naming (e.g., "Tennis Court A" vs "Tennis Court - A").
    /// </remarks>
    [HttpPost("merge")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<VenueMergeResultDto>> MergeVenues(MergeVenuesDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.TargetName))
        {
            return BadRequest(new { message = "TargetName is required" });
        }

        if (dto.VenuesToMerge == null || !dto.VenuesToMerge.Any())
        {
            return BadRequest(new { message = "At least one venue to merge is required" });
        }

        // Remove target name from merge list if present
        var venuesToMerge = dto.VenuesToMerge
            .Where(v => !v.Equals(dto.TargetName, StringComparison.OrdinalIgnoreCase))
            .ToList();

        if (!venuesToMerge.Any())
        {
            return BadRequest(new { message = "No venues to merge (target name matches merge list)" });
        }

        // Find all schedules with any of the venue names to merge
        var schedulesToUpdate = await _context.Schedules
            .Where(s => venuesToMerge.Contains(s.Venue))
            .ToListAsync();

        if (!schedulesToUpdate.Any())
        {
            return NotFound(new { message = "No schedules found with the specified venue names" });
        }

        // Update all to target name
        foreach (var schedule in schedulesToUpdate)
        {
            schedule.Venue = dto.TargetName;
        }

        await _context.SaveChangesAsync();

        _logger.LogInformation(
            "Merged {MergeCount} venues into '{TargetName}'. {ScheduleCount} schedules updated.",
            venuesToMerge.Count, dto.TargetName, schedulesToUpdate.Count);

        return Ok(new VenueMergeResultDto
        {
            TargetName = dto.TargetName,
            MergedVenues = venuesToMerge,
            SchedulesUpdated = schedulesToUpdate.Count,
            Message = $"Successfully merged {venuesToMerge.Count} venue(s) into '{dto.TargetName}'. {schedulesToUpdate.Count} schedule(s) updated."
        });
    }

    /// <summary>
    /// Delete a venue (removes all schedules at that venue) - Admin only
    /// </summary>
    /// <remarks>
    /// WARNING: This will permanently delete all schedules at the specified venue.
    /// Use with caution. Consider using rename instead if you want to consolidate venues.
    /// </remarks>
    [HttpDelete("{venueName}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<VenueDeleteResultDto>> DeleteVenue(string venueName)
    {
        if (string.IsNullOrWhiteSpace(venueName))
        {
            return BadRequest(new { message = "Venue name is required" });
        }

        var schedulesToDelete = await _context.Schedules
            .Include(s => s.Bookings)
            .Where(s => s.Venue == venueName)
            .ToListAsync();

        if (!schedulesToDelete.Any())
        {
            return NotFound(new { message = $"No schedules found with venue name '{venueName}'" });
        }

        var totalBookings = schedulesToDelete.Sum(s => s.Bookings.Count);

        _context.Schedules.RemoveRange(schedulesToDelete);
        await _context.SaveChangesAsync();

        _logger.LogWarning(
            "Venue '{VenueName}' deleted. {ScheduleCount} schedules and {BookingCount} bookings removed.",
            venueName, schedulesToDelete.Count, totalBookings);

        return Ok(new VenueDeleteResultDto
        {
            VenueName = venueName,
            SchedulesDeleted = schedulesToDelete.Count,
            BookingsAffected = totalBookings,
            Message = $"Venue '{venueName}' deleted. {schedulesToDelete.Count} schedule(s) and {totalBookings} booking(s) removed."
        });
    }

    /// <summary>
    /// Validate venue name format - Admin only
    /// </summary>
    /// <remarks>
    /// Checks if a venue name meets naming standards and provides suggestions for improvement.
    /// </remarks>
    [HttpPost("validate")]
    [Authorize(Roles = UserRoles.Admin)]
    public ActionResult<VenueValidationDto> ValidateVenueName(ValidateVenueDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.VenueName))
        {
            return BadRequest(new { message = "Venue name is required" });
        }

        var validation = new VenueValidationDto
        {
            VenueName = dto.VenueName,
            IsValid = true,
            Issues = new List<string>(),
            Suggestions = new List<string>()
        };

        // Check length
        if (dto.VenueName.Length < 3)
        {
            validation.IsValid = false;
            validation.Issues.Add("Venue name is too short (minimum 3 characters)");
        }

        if (dto.VenueName.Length > 200)
        {
            validation.IsValid = false;
            validation.Issues.Add("Venue name is too long (maximum 200 characters)");
        }

        // Check for leading/trailing whitespace
        if (dto.VenueName != dto.VenueName.Trim())
        {
            validation.Issues.Add("Venue name has leading or trailing whitespace");
            validation.Suggestions.Add($"Use: '{dto.VenueName.Trim()}'");
        }

        // Check for multiple consecutive spaces
        if (dto.VenueName.Contains("  "))
        {
            validation.Issues.Add("Venue name contains multiple consecutive spaces");
            var cleaned = System.Text.RegularExpressions.Regex.Replace(dto.VenueName, @"\s+", " ");
            validation.Suggestions.Add($"Use: '{cleaned}'");
        }

        // Check for common inconsistencies
        if (dto.VenueName.Contains("court") && !dto.VenueName.Contains("Court"))
        {
            validation.Suggestions.Add("Consider capitalizing 'Court' for consistency");
        }

        return Ok(validation);
    }
}
