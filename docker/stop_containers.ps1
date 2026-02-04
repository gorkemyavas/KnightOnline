# PowerShell script to stop OpenKO Docker containers
# Stops the sqlserver and kodb-util services

$ErrorActionPreference = "Stop"

# Get script directory and navigate to project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir
Set-Location ..

Write-Host "Working directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Stopping OpenKO containers..." -ForegroundColor Yellow
Write-Host ""

try {
    # Stop containers
    docker compose stop sqlserver kodb-util
    
    Write-Host ""
    Write-Host "Containers stopped successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To resume: .\resume_containers.ps1" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    exit 1
}

# Wait for user input before closing
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
