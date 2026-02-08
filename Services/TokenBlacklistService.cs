using Microsoft.EntityFrameworkCore;
using PlayOhCanadaAPI.Data;
using PlayOhCanadaAPI.Models;

namespace PlayOhCanadaAPI.Services
{
    public interface ITokenBlacklistService
    {
        Task RevokeTokenAsync(string token, int userId, DateTime expiresAt);
        Task<bool> IsTokenRevokedAsync(string token);
        Task CleanupExpiredTokensAsync();
    }

    public class TokenBlacklistService : ITokenBlacklistService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<TokenBlacklistService> _logger;

        public TokenBlacklistService(
            ApplicationDbContext context,
            ILogger<TokenBlacklistService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task RevokeTokenAsync(string token, int userId, DateTime expiresAt)
        {
            var revokedToken = new RevokedToken
            {
                Token = token,
                UserId = userId,
                RevokedAt = DateTime.UtcNow,
                ExpiresAt = expiresAt
            };

            _context.RevokedTokens.Add(revokedToken);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Token revoked for user {UserId}", userId);
        }

        public async Task<bool> IsTokenRevokedAsync(string token)
        {
            return await _context.RevokedTokens
                .AnyAsync(rt => rt.Token == token && rt.ExpiresAt > DateTime.UtcNow);
        }

        public async Task CleanupExpiredTokensAsync()
        {
            var expiredTokens = await _context.RevokedTokens
                .Where(rt => rt.ExpiresAt <= DateTime.UtcNow)
                .ToListAsync();

            if (expiredTokens.Any())
            {
                _context.RevokedTokens.RemoveRange(expiredTokens);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Cleaned up {Count} expired tokens", expiredTokens.Count);
            }
        }
    }
}
