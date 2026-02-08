namespace PlayOhCanadaAPI.Models.DTOs
{
    /// <summary>
    /// DTO for updating an existing sport
    /// </summary>
    public class UpdateSportDto
    {
        /// <summary>
        /// Sport name (optional - only updated if provided)
        /// </summary>
        public string? Name { get; set; }

        /// <summary>
        /// Icon URL (optional - only updated if provided, use empty string to clear)
        /// </summary>
        public string? IconUrl { get; set; }
    }
}
