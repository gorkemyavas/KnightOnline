# PowerShell script to start all OpenKO services with Docker
# This includes database and all game servers

$ErrorActionPreference = "Stop"

# Set Docker platform
$env:DOCKER_DEFAULT_PLATFORM = "linux/amd64"

# Get script directory and navigate to project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir
Set-Location ..

Write-Host "Working directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Building and starting all OpenKO services..." -ForegroundColor Green
Write-Host ""

try {
    # Start database first
    Write-Host "Starting SQL Server..." -ForegroundColor Yellow
    docker compose up --build -d sqlserver
    
    Write-Host "Waiting for SQL Server to be healthy..." -ForegroundColor Yellow
    docker compose up --build -d kodb-util
    
    # Initialize database
    Write-Host "Initializing database..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    docker exec knightonline-kodb-util-1 /usr/local/bin/cleanImport.sh
    
    # Start all game servers
    Write-Host "Starting game servers..." -ForegroundColor Yellow
    docker compose up --build -d aiserver aujard ebenezer itemmanager versionmanager
    
    Write-Host ""
    Write-Host "All services started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host "  - View logs: docker compose logs -f"
    Write-Host "  - Stop services: docker compose down"
    Write-Host "  - Stop and remove all data: docker compose down -v"
    Write-Host ""
}
catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    exit 1
}

# Wait for user input before closing
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
