using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace PlayOhCanadaAPI.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private static readonly string[] Summaries =
        [
            "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
        ];

        /// <summary>
        /// Gets the weather forecast for the next 5 days (requires authentication)
        /// </summary>
        /// <returns>A collection of weather forecasts</returns>
        /// <response code="200">Returns the weather forecast</response>
        /// <response code="401">If the user is not authenticated</response>
        [HttpGet(Name = "GetWeatherForecast")]
        [ProducesResponseType(typeof(IEnumerable<WeatherForecast>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public IEnumerable<WeatherForecast> Get()
        {
            return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            {
                Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                TemperatureC = Random.Shared.Next(-20, 55),
                Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            })
            .ToArray();
        }

        /// <summary>
        /// Gets a public weather forecast (no authentication required)
        /// </summary>
        /// <returns>A single weather forecast</returns>
        /// <response code="200">Returns the weather forecast</response>
        [HttpGet("public")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(WeatherForecast), StatusCodes.Status200OK)]
        public WeatherForecast GetPublic()
        {
            return new WeatherForecast
            {
                Date = DateOnly.FromDateTime(DateTime.Now.AddDays(1)),
                TemperatureC = Random.Shared.Next(-20, 55),
                Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            };
        }
    }
}
