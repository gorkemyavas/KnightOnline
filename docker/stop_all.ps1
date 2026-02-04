# PowerShell script to stop all OpenKO services

$ErrorActionPreference = "Stop"

# Get script directory and navigate to project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir
Set-Location ..

Write-Host "Stopping all OpenKO services..." -ForegroundColor Yellow

try {
    docker compose down
    
    Write-Host ""
    Write-Host "All services stopped successfully!" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    exit 1
}

# Wait for user input before closing
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
