# PowerShell script to completely remove OpenKO Docker environment
# Removes all sqlserver and kodb-util containers, images, and volumes

$ErrorActionPreference = "Stop"

# Get script directory and navigate to project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir
Set-Location ..

Write-Host "Working directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

Write-Host "WARNING: This will remove all OpenKO Docker containers, images, and volumes!" -ForegroundColor Red
Write-Host "All database data will be permanently deleted!" -ForegroundColor Red
Write-Host ""

$confirmation = Read-Host "Are you sure you want to continue? (yes/no)"

if ($confirmation -ne 'yes') {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Uninstalling OpenKO Docker environment..." -ForegroundColor Yellow
Write-Host ""

try {
    # Remove all containers, images, and volumes
    docker compose down --rmi all -v
    
    Write-Host ""
    Write-Host "Uninstall completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To reinstall, run: .\clean_setup.ps1" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    exit 1
}

# Wait for user input before closing
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
