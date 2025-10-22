@echo off
echo Syncing farmers data to Elasticsearch...

REM Check if services are running
docker-compose ps | findstr "Up" >nul
if errorlevel 1 (
    echo Error: Services are not running. Please start them first with start-dev.bat
    pause
    exit /b 1
)

REM Wait for Elasticsearch to be ready
echo Waiting for Elasticsearch to be ready...
:wait_loop
curl -s http://localhost:9200/_cluster/health >nul 2>&1
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto wait_loop
)

echo Elasticsearch is ready. Starting sync...

REM Run the sync script
docker-compose exec search-api node elasticsearch-sync.js

echo Sync completed!

REM Test autocomplete
echo.
echo Testing autocomplete functionality...
curl -s "http://localhost/api/search/autocomplete?q=john" | findstr "suggestions"

echo.
echo Autocomplete endpoint: http://localhost/api/search/autocomplete?q=your_query
pause