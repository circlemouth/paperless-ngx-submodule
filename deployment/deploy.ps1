# deploy.ps1
# Sets up the data directories on D: and cleans up any external configuration folders.

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
# 1. Load .env variables
if (Test-Path "$scriptDir\.env") {
    Get-Content "$scriptDir\.env" | ForEach-Object {
        if ($_ -match "^\s*([^#=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$dataBaseDir = $env:PAPERLESS_ROOT_DIR
if (-not $dataBaseDir) {
    $dataBaseDir = "D:\paperlessNgxFolder" # Default fallback
    Write-Warning "PAPERLESS_ROOT_DIR not found in .env, using default: $dataBaseDir"
}

$subDirs = @(
    "consume\inbox",
    "consume\hard",
    "data",
    "media",
    "pgdata",
    "redisdata",
    "export"
)

# 2. Create Data Directories
Write-Host "Creating data directory structure in $dataBaseDir..."
if (-not (Test-Path $dataBaseDir)) {
    New-Item -ItemType Directory -Path $dataBaseDir -Force | Out-Null
}

foreach ($dir in $subDirs) {
    $fullPath = Join-Path $dataBaseDir $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "Created: $fullPath"
    }
}

# 2. Cleanup External Compose Folder
# We are running from the repo now, so we don't need D:\paperlessNgxFolder\compose
$externalComposeDir = Join-Path $dataBaseDir "compose"
if (Test-Path $externalComposeDir) {
    Write-Host "Removing external configuration folder: $externalComposeDir"
    Remove-Item -Path $externalComposeDir -Recurse -Force
    Write-Host "Cleanup complete."
}

# 3. Create .env file in the repo if missing
$envDest = Join-Path $scriptDir ".env"
if (-not (Test-Path $envDest)) {
    $envContent = @"
PAPERLESS_API_TOKEN=<<<PASTE_YOUR_TOKEN_HERE>>>
PAPERLESS_SECRET_KEY=$( -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | % {[char]$_}) )
Z_UNC_PATH=\\Server\Share
Z_USER=username
Z_PASS=password
"@
    Set-Content -Path $envDest -Value $envContent
    Write-Host "Created .env file at $envDest"
} else {
    Write-Host ".env file already exists, skipping creation."
}

Write-Host "Deployment setup complete."
Write-Host "Next steps:"
Write-Host "1. Edit $envDest to set PAPERLESS_API_TOKEN and Z drive creds."
Write-Host "2. Run 'docker compose up -d' in $scriptDir"
