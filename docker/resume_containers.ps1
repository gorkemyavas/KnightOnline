# PowerShell script to resume OpenKO Docker containers
# Resumes the sqlserver and kodb-util services

$ErrorActionPreference = "Stop"

# Set Docker platform
$env:DOCKER_DEFAULT_PLATFORM = "linux/amd64"

# Get script directory and navigate to project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir
Set-Location ..

Write-Host "Working directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Resuming OpenKO containers..." -ForegroundColor Green
Write-Host ""

try {
    # Resume containers
    Write-Host "Starting sqlserver and kodb-util containers..." -ForegroundColor Yellow
    docker compose up -d sqlserver kodb-util
    
    Write-Host ""
    Write-Host "Containers resumed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Check status with: docker compose ps" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    exit 1
}

# Wait for user input before closing
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
