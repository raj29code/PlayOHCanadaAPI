namespace PlayOhCanadaAPI.Models.DTOs
{
    /// <summary>
    /// Venue statistics
    /// </summary>
    public class VenueStatisticsDto
    {
        public string VenueName { get; set; } = string.Empty;
        public int TotalSchedules { get; set; }
        public int FutureSchedules { get; set; }
        public int PastSchedules { get; set; }
        public int TotalBookings { get; set; }
        public string MostPopularSport { get; set; } = string.Empty;
        public DateTime FirstScheduleDate { get; set; }
        public DateTime LastScheduleDate { get; set; }
        public double AverageBookingsPerSchedule { get; set; }
    }

    /// <summary>
    /// Request to rename a venue
    /// </summary>
    public class RenameVenueDto
    {
        public string OldName { get; set; } = string.Empty;
        public string NewName { get; set; } = string.Empty;
    }

    /// <summary>
    /// Result of venue rename operation
    /// </summary>
    public class VenueRenameResultDto
    {
        public string OldName { get; set; } = string.Empty;
        public string NewName { get; set; } = string.Empty;
        public int SchedulesUpdated { get; set; }
        public string Message { get; set; } = string.Empty;
    }

    /// <summary>
    /// Request to merge multiple venues
    /// </summary>
    public class MergeVenuesDto
    {
        public string TargetName { get; set; } = string.Empty;
        public List<string> VenuesToMerge { get; set; } = new List<string>();
    }

    /// <summary>
    /// Result of venue merge operation
    /// </summary>
    public class VenueMergeResultDto
    {
        public string TargetName { get; set; } = string.Empty;
        public List<string> MergedVenues { get; set; } = new List<string>();
        public int SchedulesUpdated { get; set; }
        public string Message { get; set; } = string.Empty;
    }

    /// <summary>
    /// Result of venue delete operation
    /// </summary>
    public class VenueDeleteResultDto
    {
        public string VenueName { get; set; } = string.Empty;
        public int SchedulesDeleted { get; set; }
        public int BookingsAffected { get; set; }
        public string Message { get; set; } = string.Empty;
    }

    /// <summary>
    /// Request to validate venue name
    /// </summary>
    public class ValidateVenueDto
    {
        public string VenueName { get; set; } = string.Empty;
    }

    /// <summary>
    /// Venue validation result
    /// </summary>
    public class VenueValidationDto
    {
        public string VenueName { get; set; } = string.Empty;
        public bool IsValid { get; set; }
        public List<string> Issues { get; set; } = new List<string>();
        public List<string> Suggestions { get; set; } = new List<string>();
    }
}
