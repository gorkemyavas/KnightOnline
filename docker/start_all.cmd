@echo off
REM Script to start all OpenKO services with Docker
REM This includes database and all game servers

set DOCKER_DEFAULT_PLATFORM=linux/amd64

REM Get script directory
set SCRIPT_DIR=%~dp0

cd /d "%SCRIPT_DIR%"
cd ..
echo Working directory: %CD%

echo Building and starting all OpenKO services...

REM Start database first
docker compose up --build -d sqlserver
echo Waiting for SQL Server to be healthy...
docker compose up --build -d kodb-util

REM Initialize database
echo Initializing database...
timeout /t 5 /nobreak > nul
docker exec knightonline-kodb-util-1 /usr/local/bin/cleanImport.sh

REM Start all game servers
echo Starting game servers...
docker compose up --build -d aiserver aujard ebenezer itemmanager versionmanager

echo.
echo All services started successfully!
echo.
echo To view logs: docker compose logs -f
echo To stop services: docker compose down
echo To stop and remove all data: docker compose down -v

pause
