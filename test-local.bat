@echo off
echo Testing SG Farmers App on localhost...

REM Check if Docker Desktop is running
echo Checking Docker status...
docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Docker Desktop is not running!
    echo.
    echo Please follow these steps:
    echo 1. Open Docker Desktop application
    echo 2. Wait for it to start completely
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

echo Docker is running ✓

REM Build and start services
echo Building and starting services...
docker-compose up --build -d

REM Wait for services to be ready
echo Waiting for services to start...
timeout /t 15 /nobreak >nul

REM Test health endpoints
echo.
echo Testing service endpoints...

curl -s http://localhost/health >nul 2>&1
if errorlevel 1 (
    echo ✗ Main health check - FAILED
) else (
    echo ✓ Main health check - OK
)

curl -s http://localhost/api/farmers/health >nul 2>&1
if errorlevel 1 (
    echo ✗ Registration API - FAILED
) else (
    echo ✓ Registration API - OK
)

curl -s http://localhost/api/search/health >nul 2>&1
if errorlevel 1 (
    echo ✗ Search API - FAILED
) else (
    echo ✓ Search API - OK
)

curl -s http://localhost/api/chat/health >nul 2>&1
if errorlevel 1 (
    echo ✗ Chat API - FAILED
) else (
    echo ✓ Chat API - OK
)

echo.
echo Service Status:
docker-compose ps

echo.
echo ========================================
echo   SG FARMERS APP - LOCAL TESTING
echo ========================================
echo.
echo Frontend:        http://localhost
echo Registration:    http://localhost/api/farmers
echo Search:          http://localhost/api/search
echo Chat:            http://localhost/api/chat
echo Database:        localhost:5432
echo Redis:           localhost:6379
echo.
echo To view logs:     docker-compose logs -f [service-name]
echo To stop:          docker-compose down
echo.
pause