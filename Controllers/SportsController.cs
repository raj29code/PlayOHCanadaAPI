using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PlayOhCanadaAPI.Data;
using PlayOhCanadaAPI.Models;
using PlayOhCanadaAPI.Models.DTOs;

namespace PlayOhCanadaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SportsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public SportsController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get all sports
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Sport>>> GetSports()
    {
        return await _context.Sports.ToListAsync();
    }

    /// <summary>
    /// Get a specific sport by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<Sport>> GetSport(int id)
    {
        var sport = await _context.Sports.FindAsync(id);

        if (sport == null)
        {
            return NotFound();
        }

        return sport;
    }

    /// <summary>
    /// Create a new sport (Admin only)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<Sport>> CreateSport(CreateSportDto dto)
    {
        // Check if sport with same name already exists
        if (await _context.Sports.AnyAsync(s => s.Name == dto.Name))
        {
            return BadRequest("A sport with this name already exists");
        }

        var sport = new Sport
        {
            Name = dto.Name,
            IconUrl = dto.IconUrl
        };

        _context.Sports.Add(sport);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetSport), new { id = sport.Id }, sport);
    }

    /// <summary>
    /// Update an existing sport (Admin only)
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> UpdateSport(int id, UpdateSportDto dto)
    {
        var sport = await _context.Sports.FindAsync(id);
        if (sport == null)
        {
            return NotFound(new { message = "Sport not found" });
        }

        // Check if new name already exists (excluding current sport)
        if (!string.IsNullOrWhiteSpace(dto.Name) && dto.Name != sport.Name)
        {
            if (await _context.Sports.AnyAsync(s => s.Name == dto.Name && s.Id != id))
            {
                return BadRequest(new { message = "A sport with this name already exists" });
            }
            sport.Name = dto.Name;
        }

        // Update icon URL if provided
        if (dto.IconUrl != null)
        {
            sport.IconUrl = dto.IconUrl;
        }

        await _context.SaveChangesAsync();

        return Ok(sport);
    }

    /// <summary>
    /// Delete a sport (Admin only)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> DeleteSport(int id)
    {
        var sport = await _context.Sports.FindAsync(id);
        if (sport == null)
        {
            return NotFound();
        }

        // Check if there are any schedules associated with this sport
        if (await _context.Schedules.AnyAsync(s => s.SportId == id))
        {
            return BadRequest("Cannot delete sport with existing schedules");
        }

        _context.Sports.Remove(sport);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
