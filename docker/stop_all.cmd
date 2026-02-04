@echo off
REM Script to stop all OpenKO services

set SCRIPT_DIR=%~dp0

cd /d "%SCRIPT_DIR%"
cd ..

echo Stopping all OpenKO services...
docker compose down

echo All services stopped successfully!
pause
