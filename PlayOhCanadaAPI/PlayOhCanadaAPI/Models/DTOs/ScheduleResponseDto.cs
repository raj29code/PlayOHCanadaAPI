namespace PlayOhCanadaAPI.Models.DTOs;

public class ScheduleResponseDto
{
    public int Id { get; set; }
    public int SportId { get; set; }
    public string SportName { get; set; } = string.Empty;
    public string? SportIconUrl { get; set; }
    public string Venue { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int MaxPlayers { get; set; }
    public int CurrentPlayers { get; set; }
    public int SpotsRemaining { get; set; }
    public string? EquipmentDetails { get; set; }
    public List<ParticipantDto> Participants { get; set; } = new();
}

public class ParticipantDto
{
    public string Name { get; set; } = string.Empty;
    public DateTime BookingTime { get; set; }
}
