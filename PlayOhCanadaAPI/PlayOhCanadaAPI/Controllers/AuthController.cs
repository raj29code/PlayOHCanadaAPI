using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PlayOhCanadaAPI.Models.DTOs;
using PlayOhCanadaAPI.Services;
using System.Security.Claims;

namespace PlayOhCanadaAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, ILogger<AuthController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        /// <summary>
        /// Register a new user account
        /// </summary>
        /// <param name="request">Registration details including name, email, and password</param>
        /// <returns>Authentication token and user details</returns>
        /// <response code="200">Registration successful</response>
        /// <response code="400">Invalid request or user already exists</response>
        [HttpPost("register")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _authService.RegisterAsync(request);
            
            if (result == null)
            {
                return BadRequest(new { message = "User with this email or phone already exists" });
            }

            return Ok(result);
        }

        /// <summary>
        /// Login with email and password
        /// </summary>
        /// <param name="request">Login credentials (email and password)</param>
        /// <returns>Authentication token and user details</returns>
        /// <response code="200">Login successful</response>
        /// <response code="401">Invalid credentials</response>
        [HttpPost("login")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _authService.LoginAsync(request);
            
            if (result == null)
            {
                return Unauthorized(new { message = "Invalid email or password" });
            }

            return Ok(result);
        }

        /// <summary>
        /// Get current logged in user profile
        /// </summary>
        /// <returns>Current user details</returns>
        /// <response code="200">User profile retrieved</response>
        /// <response code="401">Not authenticated</response>
        /// <response code="404">User not found</response>
        [HttpGet("me")]
        [Authorize]
        [ProducesResponseType(typeof(UserResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetCurrentUser()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            var user = await _authService.GetUserByIdAsync(userId);
            
            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            var response = new UserResponse
            {
                Id = user.Id,
                Name = user.Name,
                Email = user.Email,
                Phone = user.Phone,
                Role = user.Role,
                CreatedAt = user.CreatedAt,
                LastLoginAt = user.LastLoginAt
            };

            return Ok(response);
        }

        // Phase 2: Phone Login Endpoint (placeholder)
        /// <summary>
        /// Login with phone number and verification code (Phase 2 - Coming Soon)
        /// </summary>
        [HttpPost("login/phone")]
        [AllowAnonymous]
        [ProducesResponseType(StatusCodes.Status501NotImplemented)]
        public IActionResult LoginWithPhone([FromBody] PhoneLoginRequest request)
        {
            return StatusCode(501, new { message = "Phone login will be available in Phase 2" });
        }

        // Phase 2: SSO Login Endpoint (placeholder)
        /// <summary>
        /// Login with SSO provider (Google, Microsoft, Apple) (Phase 2 - Coming Soon)
        /// </summary>
        [HttpPost("login/sso")]
        [AllowAnonymous]
        [ProducesResponseType(StatusCodes.Status501NotImplemented)]
        public IActionResult LoginWithSso([FromBody] SsoLoginRequest request)
        {
            return StatusCode(501, new { message = "SSO login will be available in Phase 2" });
        }
    }
}
