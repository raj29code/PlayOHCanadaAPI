namespace PlayOhCanadaAPI.Models.DTOs
{
    /// <summary>
    /// Response DTO for booking operations
    /// </summary>
    public class BookingResponseDto
    {
        public int Id { get; set; }
        public int ScheduleId { get; set; }
        public DateTime BookingTime { get; set; }
        
        // Schedule details
        public string SportName { get; set; } = string.Empty;
        public string SportIconUrl { get; set; } = string.Empty;
        public string Venue { get; set; } = string.Empty;
        public DateTime ScheduleStartTime { get; set; }
        public DateTime ScheduleEndTime { get; set; }
        public int MaxPlayers { get; set; }
        public int CurrentPlayers { get; set; }
        public string? EquipmentDetails { get; set; }
        
        // Booking status
        public bool IsPast { get; set; }
        public bool CanCancel { get; set; }
    }
}
