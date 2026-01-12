# backup.ps1
# Run this script to export Paperless data and backup to Z: drive.

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$exportDir = "D:\paperlessNgxFolder\export"
$backupDir = "Z:\paperlessNgx\backup\export_mirror"

# --- Z Drive Check & Mount ---
# Load .env variables if present
if (Test-Path "$scriptDir\.env") {
    Get-Content "$scriptDir\.env" | ForEach-Object {
        if ($_ -match "^\s*([^#=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

if (-not (Test-Path "Z:\")) {
    Write-Host "Z: drive is not accessible."
    if ($env:Z_UNC_PATH -and $env:Z_USER -and $env:Z_PASS) {
        Write-Host "Attempting to mount Z: from $env:Z_UNC_PATH..."
        net use Z: $env:Z_UNC_PATH /user:$env:Z_USER $env:Z_PASS
        if (-not (Test-Path "Z:\")) {
            Write-Error "Failed to mount Z: drive. Check credentials and path."
            exit 1
        }
        Write-Host "Successfully mounted Z:."
    } else {
        Write-Warning "Z: drive is missing and Z_UNC_PATH/Z_USER/Z_PASS are not set."
    }
}

# --- Ensure Directories ---
if (-not (Test-Path $backupDir)) {
    Write-Host "Creating backup directory: $backupDir"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# --- Paperless Export ---
Write-Host "Starting Paperless document export..."
Set-Location -Path $scriptDir
# Using -T to disable pseudo-tty allocation for automation
docker compose exec -T webserver document_exporter ../export
if ($LASTEXITCODE -ne 0) {
    Write-Error "Paperless export failed."
    exit 1
}

# --- Mirror to Backup ---
Write-Host "Mirroring export to backup location..."
$robocopyOptions = @("/MIR", "/R:2", "/W:5", "/NFL", "/NDL") 
robocopy $exportDir $backupDir $robocopyOptions
if ($LASTEXITCODE -ge 8) {
    Write-Error "Robocopy failed with exit code $LASTEXITCODE"
    exit 1
}

Write-Host "Backup completed successfully."
