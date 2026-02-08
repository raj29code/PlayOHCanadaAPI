namespace PlayOhCanadaAPI.Models.DTOs
{
    /// <summary>
    /// Venue information with schedule statistics
    /// </summary>
    public class VenueDto
    {
        /// <summary>
        /// Venue name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// Total number of schedules at this venue
        /// </summary>
        public int ScheduleCount { get; set; }

        /// <summary>
        /// Number of schedules with available spots
        /// </summary>
        public int AvailableSchedules { get; set; }

        /// <summary>
        /// List of sports available at this venue
        /// </summary>
        public List<string> Sports { get; set; } = new List<string>();

        /// <summary>
        /// Next scheduled event time at this venue (converted to user's timezone if offset provided)
        /// </summary>
        public DateTime NextScheduleTime { get; set; }
    }
}
