# Railway Dockerfile for Play Oh Canada API (.NET 10)
# This provides explicit build instructions for Railway deployment

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY PlayOhCanadaAPI/PlayOhCanadaAPI.csproj PlayOhCanadaAPI/
RUN dotnet restore PlayOhCanadaAPI/PlayOhCanadaAPI.csproj

# Copy everything else and build
COPY PlayOhCanadaAPI/ PlayOhCanadaAPI/
WORKDIR /src/PlayOhCanadaAPI
RUN dotnet publish -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Copy published app from build stage
COPY --from=build /app/publish .

# Expose port (Railway will set the PORT environment variable)
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Start the application
ENTRYPOINT ["dotnet", "PlayOhCanadaAPI.dll"]
