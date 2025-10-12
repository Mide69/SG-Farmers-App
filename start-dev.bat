@echo off
echo Starting SG Farmers App in development mode...

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not running. Please start Docker Desktop and try again.
    pause
    exit /b 1
)

REM Start services with Docker Compose
echo Starting services...
docker-compose up --build -d

REM Wait for services to start
echo Waiting for services to start...
timeout /t 10 /nobreak >nul

REM Show service status
echo Service Status:
docker-compose ps

echo.
echo Services started successfully!
echo.
echo Service URLs:
echo Frontend: http://localhost
echo Registration API: http://localhost/api/farmers
echo Search API: http://localhost/api/search
echo Chat API: http://localhost/api/chat
echo Database: localhost:5432
echo Redis: localhost:6379
echo.
echo To view logs: docker-compose logs -f [service-name]
echo To stop services: stop-dev.bat