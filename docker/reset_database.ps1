# PowerShell script to reset the OpenKO database
# Performs a clean import of the OpenKO database

$ErrorActionPreference = "Stop"

# Set Docker platform
$env:DOCKER_DEFAULT_PLATFORM = "linux/amd64"

# Get script directory and navigate to project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir
Set-Location ..

Write-Host "Working directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Resetting OpenKO database..." -ForegroundColor Green
Write-Host ""

try {
    # Execute database reset
    Write-Host "Performing clean import of the database..." -ForegroundColor Yellow
    docker exec knightonline-kodb-util-1 /usr/local/bin/cleanImport.sh
    
    Write-Host ""
    Write-Host "Database reset completed successfully!" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    Write-Host "Make sure the kodb-util container is running." -ForegroundColor Yellow
    exit 1
}

# Wait for user input before closing
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
