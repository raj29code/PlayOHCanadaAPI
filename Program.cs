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

// Configure forwarded headers for Railway proxy
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedFor 
        | Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

// Add Database Context
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// Railway provides DATABASE_URL in PostgreSQL format, convert it to Npgsql format
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
if (!string.IsNullOrEmpty(databaseUrl))
{
    try
    {
        // Parse Railway's DATABASE_URL (postgresql://user:pass@host:port/db)
        // Convert to Npgsql format
        var uri = new Uri(databaseUrl);
        var userInfo = uri.UserInfo.Split(':');
        
        if (userInfo.Length != 2)
        {
            throw new InvalidOperationException("DATABASE_URL is missing username or password");
        }
        
        connectionString = $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.TrimStart('/')};Username={userInfo[0]};Password={userInfo[1]};SSL Mode=Require;Trust Server Certificate=true";
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Failed to parse DATABASE_URL: {ex.Message}");
        
        // Fallback: Try to construct from individual Railway variables
        var pgHost = Environment.GetEnvironmentVariable("PGHOST");
        var pgPort = Environment.GetEnvironmentVariable("PGPORT");
        var pgDatabase = Environment.GetEnvironmentVariable("PGDATABASE");
        var pgUser = Environment.GetEnvironmentVariable("PGUSER");
        var pgPassword = Environment.GetEnvironmentVariable("PGPASSWORD");
        
        if (!string.IsNullOrEmpty(pgHost) && !string.IsNullOrEmpty(pgUser) && !string.IsNullOrEmpty(pgPassword))
        {
            Console.WriteLine("Using individual PostgreSQL environment variables");
            connectionString = $"Host={pgHost};Port={pgPort ?? "5432"};Database={pgDatabase ?? "railway"};Username={pgUser};Password={pgPassword};SSL Mode=Require;Trust Server Certificate=true";
        }
        else
        {
            throw new InvalidOperationException(
                "Database connection not configured. Please set DATABASE_URL or PGHOST, PGUSER, and PGPASSWORD environment variables in Railway.");
        }
    }
}

if (string.IsNullOrEmpty(connectionString))
{
    throw new InvalidOperationException(
        "Database connection string is not configured. Please check Railway environment variables.");
}

Console.WriteLine($"Using database connection: Host={new Npgsql.NpgsqlConnectionStringBuilder(connectionString).Host}");

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(connectionString));

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

// Register Background Services
// TODO: FUTURE - Remove this when migrating to Azure Function/Lambda
// This background service should be replaced with a serverless function for:
// - Better separation of concerns
// - Independent scaling
// - Cost optimization (pay per execution)
// - No impact on API performance
builder.Services.AddHostedService<ScheduleCleanupService>();

builder.Services.AddControllers();

// Configure OpenAPI - Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Auto-migrate database and seed data
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    
    try
    {
        // Apply migrations in all environments (including Production)
        // Railway will run this on startup, ensuring database is always up-to-date
        logger.LogInformation("Starting database migration...");
        await dbContext.Database.MigrateAsync();
        logger.LogInformation("Database migration completed successfully");
        
        // Seed admin user if it doesn't exist
        if (!await dbContext.Users.AnyAsync(u => u.Email == "admin@playohcanada.com"))
        {
            logger.LogInformation("Seeding admin user...");
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
            logger.LogInformation("Admin user created successfully");
        }
        else
        {
            logger.LogInformation("Admin user already exists, skipping seeding");
        }
        
        // Seed sports if they don't exist
        if (!await dbContext.Sports.AnyAsync())
        {
            logger.LogInformation("Seeding default sports...");
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
            logger.LogInformation("Seeded {Count} sports successfully", sports.Length);
        }
        else
        {
            logger.LogInformation("Sports already exist, skipping seeding");
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred while migrating or seeding the database");
        throw; // Re-throw to prevent app from starting with broken database
    }
}

// Configure the HTTP request pipeline.
// Enable OpenAPI and Scalar UI in all environments for API documentation
app.MapOpenApi();
app.MapScalarApiReference();

// Use forwarded headers for Railway proxy
app.UseForwardedHeaders();

// Only use HTTPS redirection in development (Railway handles HTTPS at the edge)
if (app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

// Enable CORS - must be placed before Authentication and Authorization
app.UseCors("AllowFrontend");

app.UseAuthentication();

// Add token blacklist middleware after authentication
app.UseTokenBlacklist();

app.UseAuthorization();

app.MapControllers();

app.Run();
