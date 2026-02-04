# PowerShell script for clean setup of OpenKO Docker environment
# Removes any existing sqlserver/kodb-util images/volumes,
# then creates/starts new versions of them.

$ErrorActionPreference = "Stop"

# Set Docker platform
$env:DOCKER_DEFAULT_PLATFORM = "linux/amd64"

# Get script directory and navigate to project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir
Set-Location ..

Write-Host "Working directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Performing clean setup of OpenKO Docker environment..." -ForegroundColor Green
Write-Host ""

try {
    # Removes any existing sqlserver/kodb-util images/volumes
    Write-Host "Removing existing containers, images, and volumes..." -ForegroundColor Yellow
    docker compose down --rmi all -v
    
    # Create and start new versions
    Write-Host "Building and starting SQL Server..." -ForegroundColor Yellow
    docker compose up --build sqlserver -d
    
    Write-Host "Building and starting kodb-util..." -ForegroundColor Yellow
    docker compose up --build kodb-util -d
    
    # Initialize database
    Write-Host "Initializing OpenKO database..." -ForegroundColor Yellow
    docker exec knightonline-kodb-util-1 /usr/local/bin/cleanImport.sh
    
    Write-Host ""
    Write-Host "Clean setup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  - Start game servers: .\start_all.ps1"
    Write-Host "  - View logs: docker compose logs -f"
    Write-Host ""
}
catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    exit 1
}

# Wait for user input before closing
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
