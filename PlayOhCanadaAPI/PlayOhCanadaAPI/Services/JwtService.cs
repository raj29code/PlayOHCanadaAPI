using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using PlayOhCanadaAPI.Models;

namespace PlayOhCanadaAPI.Services
{
    public interface IJwtService
    {
        string GenerateToken(User user);
        ClaimsPrincipal? ValidateToken(string token);
        DateTime GetTokenExpiration(string token);
    }

    public class JwtService : IJwtService
    {
        private readonly IConfiguration _configuration;
        private const int MinimumSecretKeyLength = 32;

        public JwtService(IConfiguration configuration)
        {
            _configuration = configuration;
            ValidateConfiguration();
        }

        private void ValidateConfiguration()
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var secretKey = jwtSettings["SecretKey"];

            if (string.IsNullOrWhiteSpace(secretKey))
            {
                throw new InvalidOperationException(
                    "JWT SecretKey is not configured. Please set JwtSettings:SecretKey in appsettings.json or user secrets.");
            }

            if (secretKey.Length < MinimumSecretKeyLength)
            {
                throw new InvalidOperationException(
                    $"JWT SecretKey must be at least {MinimumSecretKeyLength} characters long. " +
                    $"Current length: {secretKey.Length} characters. " +
                    "Please update JwtSettings:SecretKey in appsettings.json or user secrets.");
            }
        }

        public string GenerateToken(User user)
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var secretKey = jwtSettings["SecretKey"]!;
            var issuer = jwtSettings["Issuer"] ?? "PlayOhCanadaAPI";
            var audience = jwtSettings["Audience"] ?? "PlayOhCanadaAPI";
            var expiryMinutes = int.Parse(jwtSettings["ExpiryMinutes"] ?? "60");

            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Name),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(JwtRegisteredClaimNames.Iat, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public ClaimsPrincipal? ValidateToken(string token)
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var secretKey = jwtSettings["SecretKey"]!;
            var issuer = jwtSettings["Issuer"] ?? "PlayOhCanadaAPI";
            var audience = jwtSettings["Audience"] ?? "PlayOhCanadaAPI";

            var tokenHandler = new JwtSecurityTokenHandler();
            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
                ValidateIssuer = true,
                ValidIssuer = issuer,
                ValidateAudience = true,
                ValidAudience = audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            };

            try
            {
                var principal = tokenHandler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);
                return principal;
            }
            catch
            {
                return null;
            }
        }

        public DateTime GetTokenExpiration(string token)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var jwtToken = tokenHandler.ReadJwtToken(token);
            return jwtToken.ValidTo;
        }
    }
}
