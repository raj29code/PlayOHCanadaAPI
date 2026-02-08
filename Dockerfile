# Railway Dockerfile for Play Oh Canada API (.NET 10)
# This provides explicit build instructions for Railway deployment

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY *.csproj ./
RUN dotnet restore PlayOhCanadaAPI.csproj

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Copy published app from build stage
COPY --from=build /app/publish .

# Railway provides PORT environment variable, default to 8080
ENV ASPNETCORE_URLS=http://0.0.0.0:${PORT:-8080}
EXPOSE ${PORT:-8080}

# Start the application
ENTRYPOINT ["dotnet", "PlayOhCanadaAPI.dll"]
