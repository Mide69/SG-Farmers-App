@echo off
echo Setting up development environment...

REM Copy environment files
if not exist .env (
    copy .env.example .env
    echo Created .env file - please edit with your configuration
) else (
    echo .env file already exists
)

REM Install dependencies for all services
echo Installing dependencies...

cd services\registration-api
if exist package.json (
    npm install
    echo Registration API dependencies installed
)
cd ..\..

cd services\search-api
if exist package.json (
    npm install
    echo Search API dependencies installed
)
cd ..\..

cd services\chat-api
if exist package.json (
    npm install
    echo Chat API dependencies installed
)
cd ..\..

cd services\frontend
if exist package.json (
    npm install
    echo Frontend dependencies installed
)
cd ..\..

REM Build Docker images
echo Building Docker images...
docker-compose build

echo Development environment setup complete!
echo Run 'start-dev.bat' to start all services