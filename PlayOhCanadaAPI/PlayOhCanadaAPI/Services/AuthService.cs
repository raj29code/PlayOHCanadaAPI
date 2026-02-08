using Microsoft.EntityFrameworkCore;
using PlayOhCanadaAPI.Data;
using PlayOhCanadaAPI.Models;
using PlayOhCanadaAPI.Models.DTOs;

namespace PlayOhCanadaAPI.Services
{
    public interface IAuthService
    {
        Task<AuthResponse?> RegisterAsync(RegisterRequest request);
        Task<AuthResponse?> LoginAsync(LoginRequest request);
        Task<User?> GetUserByIdAsync(int userId);
        Task<User?> GetUserByEmailAsync(string email);
        Task<bool> LogoutAsync(string token, int userId);
    }

    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly IJwtService _jwtService;
        private readonly ITokenBlacklistService _tokenBlacklistService;
        private readonly ILogger<AuthService> _logger;

        public AuthService(
            ApplicationDbContext context,
            IJwtService jwtService,
            ITokenBlacklistService tokenBlacklistService,
            ILogger<AuthService> logger)
        {
            _context = context;
            _jwtService = jwtService;
            _tokenBlacklistService = tokenBlacklistService;
            _logger = logger;
        }

        public async Task<AuthResponse?> RegisterAsync(RegisterRequest request)
        {
            // Check if user already exists
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                _logger.LogWarning("Registration attempt with existing email: {Email}", request.Email);
                return null;
            }

            if (!string.IsNullOrEmpty(request.Phone) && 
                await _context.Users.AnyAsync(u => u.Phone == request.Phone))
            {
                _logger.LogWarning("Registration attempt with existing phone: {Phone}", request.Phone);
                return null;
            }

            // Always create regular users during anonymous registration
            // Admin creation must be done through a separate admin-only endpoint or server-side process
            var role = UserRoles.User;

            // Create new user
            var user = new User
            {
                Name = request.Name,
                Email = request.Email.ToLowerInvariant(),
                Phone = request.Phone,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Role = role,
                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            _logger.LogInformation("New {Role} registered: {Email}", role, user.Email);

            // Generate token
            var token = _jwtService.GenerateToken(user);
            var expiresAt = DateTime.UtcNow.AddMinutes(60); // Should match JWT settings

            return new AuthResponse
            {
                UserId = user.Id,
                Name = user.Name,
                Email = user.Email,
                Phone = user.Phone,
                Role = user.Role,
                IsAdmin = user.Role == UserRoles.Admin,
                Token = token,
                ExpiresAt = expiresAt
            };
        }

        public async Task<AuthResponse?> LoginAsync(LoginRequest request)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == request.Email.ToLowerInvariant());

            if (user == null)
            {
                _logger.LogWarning("Login attempt with non-existent email: {Email}", request.Email);
                return null;
            }

            // Verify password
            if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            {
                _logger.LogWarning("Failed login attempt for user: {Email}", request.Email);
                return null;
            }

            // Update last login
            user.LastLoginAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _logger.LogInformation("User logged in: {Email}", user.Email);

            // Generate token
            var token = _jwtService.GenerateToken(user);
            var expiresAt = DateTime.UtcNow.AddMinutes(60); // Should match JWT settings

            return new AuthResponse
            {
                UserId = user.Id,
                Name = user.Name,
                Email = user.Email,
                Phone = user.Phone,
                Role = user.Role,
                IsAdmin = user.Role == UserRoles.Admin,
                Token = token,
                ExpiresAt = expiresAt
            };
        }

        public async Task<bool> LogoutAsync(string token, int userId)
        {
            try
            {
                var expiresAt = _jwtService.GetTokenExpiration(token);
                await _tokenBlacklistService.RevokeTokenAsync(token, userId, expiresAt);
                
                _logger.LogInformation("User {UserId} logged out successfully", userId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during logout for user {UserId}", userId);
                return false;
            }
        }

        public async Task<User?> GetUserByIdAsync(int userId)
        {
            return await _context.Users.FindAsync(userId);
        }

        public async Task<User?> GetUserByEmailAsync(string email)
        {
            return await _context.Users
                .FirstOrDefaultAsync(u => u.Email == email.ToLowerInvariant());
        }
    }
}
