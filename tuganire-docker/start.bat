@echo off
REM Tuganire Docker Quick Start Script for Windows

echo Starting Tuganire with Docker...

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running. Please start Docker and try again.
    exit /b 1
)

REM Check if tuganire.env exists
if not exist "tuganire.env" (
    echo tuganire.env not found. Please create it first.
    exit /b 1
)

REM Build and start services
echo Building and starting services...
docker-compose up -d --build

echo.
echo Waiting for services to be healthy...
timeout /t 10 /nobreak >nul

echo.
echo Tuganire is starting!
echo.
echo Access points:
echo   - Application (via nginx): http://localhost
echo   - Application (direct):    http://localhost:8080
echo   - Database:                localhost:5432
echo.
echo Useful commands:
echo   - View logs:        docker-compose logs -f
echo   - Stop services:    docker-compose down
echo   - Restart:          docker-compose restart
echo.
echo Check logs with: docker-compose logs -f
