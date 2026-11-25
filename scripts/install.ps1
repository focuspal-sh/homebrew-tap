<#
.SYNOPSIS
    Focus Pal - Windows PowerShell Installer & Service Manager
.DESCRIPTION
    Installs Focus Pal on Windows 10/11:
    - Verifies Python 3 is installed
    - Installs required 'uiautomation' library
    - Deploys CLI wrapper 'focuspal.cmd' to user PATH
    - Configures Windows Task Scheduler for 24/7 background protection
#>

[CmdletBinding()]
param (
    [switch]$Uninstall,
    [switch]$Start
)

$ErrorActionPreference = "Stop"

$AppName = "FocusPal"
$InstallDir = "$env:LOCALAPPDATA\FocusPal"
$BinDir = "$InstallDir\bin"
$ScriptsDir = "$InstallDir\scripts"
$ConfigDir = "$InstallDir\config"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🤝  Focus Pal - Windows Installer" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# --- UNINSTALL MODE ---
if ($Uninstall) {
    Write-Host "==> Uninstalling Focus Pal..." -ForegroundColor Yellow
    
    # 1. Stop running processes
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

    Write-Host "✅ Focus Pal uninstalled successfully." -ForegroundColor Green
    exit 0
}

# 1. Check Python
Write-Host "• Checking Python 3..." -NoNewline
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pythonPath) {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "Error: Python 3 was not found in your PATH." -ForegroundColor Red
    Write-Host "Please install Python 3 from https://www.python.org/downloads/ (ensure 'Add Python to PATH' is checked) or run: winget install Python.Python.3.12" -ForegroundColor Yellow
    exit 1
}
$pyVer = (python --version 2>&1)
Write-Host " OK ($pyVer)" -ForegroundColor Green

# 2. Check / Install uiautomation dependency
Write-Host "• Installing Windows UI Automation dependency (uiautomation)..." -NoNewline
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
    Write-Host "Please run this script from inside the cloned Focus Pal folder:" -ForegroundColor Yellow
    Write-Host "  cd focus-guardian" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1" -ForegroundColor Yellow
    exit 1
}

# 4. Copy files to %LOCALAPPDATA%\FocusPal
Write-Host "• Deploying to $InstallDir..." -NoNewline
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallDir\daemon" | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallDir\server" | Out-Null

Copy-Item -Recurse -Force "$SourceDir\daemon\*" "$InstallDir\daemon\"
Copy-Item -Recurse -Force "$SourceDir\server\*" "$InstallDir\server\"
Copy-Item -Recurse -Force "$SourceDir\config\*" "$InstallDir\config\"
Write-Host " OK" -ForegroundColor Green

# 5. Create 'focuspal.cmd' CLI wrapper
$CmdWrapper = @"
@echo off
set "FOCUSPAL_DIR=$InstallDir"
if "%~1"=="" goto help
if "%~1"=="status" goto status
if "%~1"=="start" goto start
if "%~1"=="stop" goto stop
if "%~1"=="test" goto test
if "%~1"=="reload" goto reload
goto help

:status
powershell -NoProfile -Command "try { `$r = Invoke-RestMethod -Uri http://127.0.0.1:8989/api/status -TimeoutSec 2; Write-Host '• Focus Pal: RUNNING (http://127.0.0.1:8989/blocked)' -ForegroundColor Green } catch { Write-Host '• Focus Pal: NOT RUNNING' -ForegroundColor Red }"
goto end

:start
powershell -NoProfile -Command "Start-Process pythonw.exe -ArgumentList '\"%FOCUSPAL_DIR%\daemon\guardian.py\"' -WindowStyle Hidden"
echo Focus Pal started in background.
goto end

:test
python "%FOCUSPAL_DIR%\daemon\guardian.py" --foreground
goto end

:stop
powershell -NoProfile -Command "`$p = (Get-NetTCPConnection -LocalPort 8989 -ErrorAction SilentlyContinue).OwningProcess; if (`$p) { Stop-Process -Id `$p -Force; Write-Host 'Focus Pal stopped.' -ForegroundColor Yellow } else { Write-Host 'Focus Pal is not currently running.' }"
goto end

:reload
powershell -NoProfile -Command "try { Invoke-RestMethod -Uri http://127.0.0.1:8989/api/reload -Method Post; Write-Host 'Reloaded rules successfully.' -ForegroundColor Green } catch { Write-Host 'Failed to reload.' -ForegroundColor Red }"
goto end

:help
echo Focus Pal CLI for Windows
echo Usage: focuspal [status ^| start ^| test ^| stop ^| reload]
goto end

:end
"@

Set-Content -Path "$BinDir\focuspal.cmd" -Value $CmdWrapper -Encoding ASCII

# 6. Ensure BinDir is in User PATH
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$BinDir*") {
    Write-Host "• Adding $BinDir to User PATH..." -NoNewline
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$BinDir", "User")
    $env:Path = "$env:Path;$BinDir"
    Write-Host " OK" -ForegroundColor Green
}

# 7. Configure Auto-Start on Login (Windows Task Scheduler)
Write-Host "• Configuring 24/7 background task (Task Scheduler)..." -NoNewline
$taskAction = "pythonw.exe `"$InstallDir\daemon\guardian.py`""
schtasks /create /tn "FocusPalDaemon" /tr "$taskAction" /sc onlogon /f 2>$null | Out-Null
Write-Host " OK" -ForegroundColor Green

# 8. Start Focus Pal now
Write-Host "• Starting Focus Pal background daemon..." -NoNewline
Start-Process pythonw.exe -ArgumentList "`"$InstallDir\daemon\guardian.py`"" -WindowStyle Hidden
Start-Sleep -Seconds 2

# 9. Verify Server
try {
    $res = Invoke-RestMethod -Uri "http://127.0.0.1:8989/api/status" -TimeoutSec 3
    Write-Host " RUNNING ✓" -ForegroundColor Green
} catch {
    Write-Host " STARTED (verifying on port 8989)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " ✅ Focus Pal Installed & Running on Windows!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "You can now use the 'focuspal' command from any PowerShell or Command Prompt:" -ForegroundColor Cyan
Write-Host "  focuspal status   - Check health and server status"
Write-Host "  focuspal test     - Run in interactive terminal console"
Write-Host "  focuspal stop     - Stop the background service"
Write-Host "  focuspal start    - Restart the background service"
Write-Host ""

