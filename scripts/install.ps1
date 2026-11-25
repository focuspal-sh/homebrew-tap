# Focus Pal Windows Installer
param (
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

$AppName = "FocusPal"
$InstallDir = "$env:LOCALAPPDATA\FocusPal"
$BinDir = "$InstallDir\bin"
$ScriptsDir = "$InstallDir\scripts"
$ConfigDir = "$InstallDir\config"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Focus Pal - Windows Installer" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# --- UNINSTALL MODE ---
if ($Uninstall) {
    Write-Host "==> Uninstalling Focus Pal..." -ForegroundColor Yellow
    
    # 1. Stop running processes on port 8989
    try {
        $pids = (Get-NetTCPConnection -LocalPort 8989 -ErrorAction SilentlyContinue).OwningProcess
        if ($pids) {
            foreach ($p in $pids) {
                Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}

    # 2. Remove Scheduled Task
    schtasks /delete /tn "FocusPalDaemon" /f 2>$null | Out-Null
    
    # 3. Remove Startup shortcut if exists
    $StartupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\FocusPal.lnk"
    if (Test-Path $StartupShortcut) { Remove-Item $StartupShortcut -Force }

    Write-Host "Focus Pal uninstalled successfully." -ForegroundColor Green
    exit 0
}

# 1. Check Python
Write-Host "Checking Python 3..." -NoNewline
$pythonCmd = (Get-Command python -ErrorAction SilentlyContinue)
if (-not $pythonCmd) {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "Error: Python 3 was not found in your PATH." -ForegroundColor Red
    Write-Host "Please install Python 3 (check 'Add Python to PATH' during install):" -ForegroundColor Yellow
    Write-Host "  winget install Python.Python.3.12" -ForegroundColor Yellow
    exit 1
}
$pyVer = (python --version)
Write-Host " OK ($pyVer)" -ForegroundColor Green

# 2. Install uiautomation dependency
Write-Host "Installing Windows UI Automation dependency (uiautomation)..." -NoNewline
python -m pip install --quiet --upgrade uiautomation 2>$null
if ($LASTEXITCODE -ne 0) {
    python -m pip install --upgrade uiautomation
}
Write-Host " OK" -ForegroundColor Green

# 3. Determine Source Directory
$ScriptPath = $MyInvocation.MyCommand.Path
if ($ScriptPath) {
    $SourceDir = (Resolve-Path (Join-Path (Split-Path $ScriptPath -Parent) "..")).Path
} else {
    $SourceDir = (Get-Location).Path
}

if (-not (Test-Path "$SourceDir\daemon\guardian.py")) {
    Write-Host "Error: Focus Pal source files not found in $SourceDir." -ForegroundColor Red
    Write-Host "Please run this script from inside your Focus Pal directory:" -ForegroundColor Yellow
    Write-Host "  cd focus-guardian" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1" -ForegroundColor Yellow
    exit 1
}

# 4. Copy files to %LOCALAPPDATA%\FocusPal
Write-Host "Deploying files to $InstallDir..." -NoNewline
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallDir\daemon" | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallDir\server" | Out-Null

Copy-Item -Recurse -Force "$SourceDir\daemon\*" "$InstallDir\daemon\"
Copy-Item -Recurse -Force "$SourceDir\server\*" "$InstallDir\server\"
Copy-Item -Recurse -Force "$SourceDir\config\*" "$InstallDir\config\"
if (Test-Path "$SourceDir\bin\focuspal.cmd") {
    Copy-Item -Force "$SourceDir\bin\focuspal.cmd" "$BinDir\focuspal.cmd"
}
Write-Host " OK" -ForegroundColor Green

# 5. Ensure BinDir is in User PATH
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$BinDir*") {
    Write-Host "Adding $BinDir to User PATH..." -NoNewline
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$BinDir", "User")
    $env:Path = "$env:Path;$BinDir"
    Write-Host " OK" -ForegroundColor Green
}

# 6. Configure Auto-Start on Login (Windows Task Scheduler)
Write-Host "Configuring 24/7 background task (Task Scheduler)..." -NoNewline
$taskAction = "pythonw.exe `"$InstallDir\daemon\guardian.py`""
schtasks /create /tn "FocusPalDaemon" /tr "$taskAction" /sc onlogon /f 2>$null | Out-Null
Write-Host " OK" -ForegroundColor Green

# 7. Start Focus Pal now
Write-Host "Starting Focus Pal background daemon..." -NoNewline
Start-Process pythonw.exe -ArgumentList "`"$InstallDir\daemon\guardian.py`"" -WindowStyle Hidden
Start-Sleep -Seconds 2

# 8. Verify Server
try {
    $res = Invoke-RestMethod -Uri "http://127.0.0.1:8989/api/status" -TimeoutSec 3
    Write-Host " RUNNING" -ForegroundColor Green
} catch {
    Write-Host " STARTED" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Focus Pal Installed and Running on Windows!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "You can now run 'focuspal' from any PowerShell or Command Prompt:" -ForegroundColor Cyan
Write-Host "  focuspal status   - Check health and server status"
Write-Host "  focuspal test     - Run in interactive terminal console"
Write-Host "  focuspal stop     - Stop the background service"
Write-Host "  focuspal start    - Restart the background service"
Write-Host ""
