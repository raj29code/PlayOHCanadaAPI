using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using PlayOhCanadaAPI.Data;
using PlayOhCanadaAPI.Middleware;
using PlayOhCanadaAPI.Models;
using PlayOhCanadaAPI.Services;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Add Database Context
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["SecretKey"];

// Validate JWT configuration at startup
if (string.IsNullOrWhiteSpace(secretKey))
{
    throw new InvalidOperationException(
        "JWT SecretKey is not configured. Please set JwtSettings:SecretKey in appsettings.json or user secrets.");
}

if (secretKey.Length < 32)
{
    throw new InvalidOperationException(
        $"JWT SecretKey must be at least 32 characters long. Current length: {secretKey.Length} characters. " +
        "Please update JwtSettings:SecretKey in appsettings.json or user secrets.");
}

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// Configure CORS
var corsOrigins = builder.Configuration.GetSection("CorsSettings:AllowedOrigins").Get<string[]>() 
    ?? new[] { "http://localhost:5173" };

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(corsOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

// Register Services
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ITokenBlacklistService, TokenBlacklistService>();

builder.Services.AddControllers();

// Configure OpenAPI - Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Auto-migrate database and seed data
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    if (app.Environment.IsDevelopment())
    {
        // Automatically apply migrations in development
        await dbContext.Database.MigrateAsync();
        
        // Seed admin user if it doesn't exist
        if (!await dbContext.Users.AnyAsync(u => u.Email == "admin@playohcanada.com"))
        {
            var adminUser = new User
            {
                Name = "Admin User",
                Email = "admin@playohcanada.com",
                Phone = null,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"),
                Role = UserRoles.Admin,
                CreatedAt = DateTime.UtcNow,
                IsEmailVerified = true
            };
            
            dbContext.Users.Add(adminUser);
            await dbContext.SaveChangesAsync();
        }
        
        // Seed sports if they don't exist
        if (!await dbContext.Sports.AnyAsync())
        {
            var sports = new[]
            {
                new Sport { Name = "Tennis", IconUrl = "https://cdn-icons-png.flaticon.com/512/889/889456.png" },
                new Sport { Name = "Badminton", IconUrl = "https://cdn-icons-png.flaticon.com/512/2913/2913133.png" },
                new Sport { Name = "Basketball", IconUrl = "https://cdn-icons-png.flaticon.com/512/889/889453.png" },
                new Sport { Name = "Soccer", IconUrl = "https://cdn-icons-png.flaticon.com/512/53/53283.png" },
                new Sport { Name = "Volleyball", IconUrl = "https://cdn-icons-png.flaticon.com/512/889/889502.png" },
                new Sport { Name = "Pickleball", IconUrl = "https://cdn-icons-png.flaticon.com/512/10529/10529471.png" }
            };
            dbContext.Sports.AddRange(sports);
            await dbContext.SaveChangesAsync();
        }
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    
    // Add Scalar UI for interactive API documentation
    app.MapScalarApiReference();
}

app.UseHttpsRedirection();

// Enable CORS - must be placed before Authentication and Authorization
app.UseCors("AllowFrontend");

app.UseAuthentication();

// Add token blacklist middleware after authentication
app.UseTokenBlacklist();

app.UseAuthorization();

app.MapControllers();

app.Run();
