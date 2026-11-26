param (
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Invoke-FocusPalInstaller {

# ----------------------------------------------------------
# 0. ENSURE ADMINISTRATOR PRIVILEGES
# ----------------------------------------------------------

function Test-IsAdmin {
    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host ""
    Write-Host "Administrator privileges are required to install/manage Focus Pal." -ForegroundColor Yellow
    Write-Host "Requesting elevation via UAC..." -ForegroundColor Cyan

    $ElevatedArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit")
    $ScriptPath = $MyInvocation.MyCommand.Path

    if ($ScriptPath -and (Test-Path $ScriptPath)) {
        $ElevatedArgs += "-File", "`"$ScriptPath`""
        if ($Uninstall) {
            $ElevatedArgs += "-Uninstall"
        }
    }
    else {
        # Running via web installer (irm ... | iex): persist to temp file so elevated PowerShell can run it
        $TempInstaller = Join-Path $env:TEMP "focuspal-install.ps1"
        try {
            Invoke-WebRequest `
                -Uri "https://raw.githubusercontent.com/focuspal-sh/homebrew-tap/main/scripts/install.ps1" `
                -OutFile $TempInstaller `
                -UseBasicParsing
        }
        catch {
            Write-Host "Failed to download installer for elevated execution: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Please open PowerShell as Administrator and run the command again." -ForegroundColor Yellow
            $script:InstallerExitCode = 1; return
        }
        $ElevatedArgs += "-File", "`"$TempInstaller`""
        if ($Uninstall) {
            $ElevatedArgs += "-Uninstall"
        }
    }

    try {
        $Proc = Start-Process -FilePath "powershell.exe" -ArgumentList $ElevatedArgs -Verb RunAs -Wait -PassThru
        $script:InstallerExitCode = $Proc.ExitCode; return
    }
    catch {
        Write-Host ""
        Write-Host "Elevation was cancelled or failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please right-click PowerShell, select 'Run as administrator', and run the installer again." -ForegroundColor Yellow
        $script:InstallerExitCode = 1; return
    }
}

$AppName = "FocusPal"
$InstallDir = "$env:LOCALAPPDATA\FocusPal"
$BinDir = "$InstallDir\bin"
$ScriptsDir = "$InstallDir\scripts"
$ConfigDir = "$InstallDir\config"
$TaskName = "FocusPalDaemon"
$StartupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\FocusPal.lnk"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "             Focus Pal - Windows Installer               " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------
# UNINSTALL MODE
# ----------------------------------------------------------

if ($Uninstall) {

    Write-Host "==> Uninstalling Focus Pal..." -ForegroundColor Yellow

    # Stop daemon using port 8989 or running guardian.py
    try {
        $Connections = Get-NetTCPConnection -LocalPort 8989 -State Listen -ErrorAction SilentlyContinue

        if ($Connections) {
            $Pids = $Connections.OwningProcess | Select-Object -Unique | Where-Object { $_ -gt 0 }

            foreach ($ProcessId in $Pids) {
                Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
            }
        }

        Get-CimInstance Win32_Process -Filter "Name='pythonw.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -like '*guardian.py*' } |
            ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    }
    catch {}

    # Remove scheduled task
    try {
        schtasks /delete /tn $TaskName /f 2>$null | Out-Null
    }
    catch {}

    # Remove startup shortcut
    if (Test-Path $StartupShortcut) {
        Remove-Item $StartupShortcut -Force
    }

    # Remove installation directory
    if (Test-Path $InstallDir) {
        Remove-Item $InstallDir -Recurse -Force
    }

    Write-Host ""
    Write-Host "Focus Pal uninstalled successfully." -ForegroundColor Green
    Write-Host ""

    $script:InstallerExitCode = 0; return
}

# ----------------------------------------------------------
# 1. CHECK PYTHON
# ----------------------------------------------------------

Write-Host "[1/8] Checking Python installation..." -NoNewline

$PythonCommand = Get-Command python -ErrorAction SilentlyContinue

if (-not $PythonCommand) {

    Write-Host " FAILED" -ForegroundColor Red

    Write-Host "Python 3 was not found in PATH." -ForegroundColor Red
    Write-Host "Install Python using:" -ForegroundColor Yellow
    Write-Host "winget install Python.Python.3.12" -ForegroundColor Cyan

    $script:InstallerExitCode = 1; return
}

$PythonExe = $PythonCommand.Source

try {
    $PythonVersion = & $PythonExe --version 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Python could not execute."
    }
}
catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $script:InstallerExitCode = 1; return
}

Write-Host " OK ($PythonVersion)" -ForegroundColor Green

# ----------------------------------------------------------
# 2. ADD PYTHON SCRIPTS TO USER PATH
# ----------------------------------------------------------

Write-Host "[2/8] Configuring Python PATH..." -NoNewline

$PythonDir = Split-Path $PythonExe -Parent
$PythonScripts = Join-Path $PythonDir "Scripts"

if (Test-Path $PythonScripts) {

    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

    $PathEntries = @()

    if ($UserPath) {
        $PathEntries = $UserPath -split ';'
    }

    if ($PathEntries -notcontains $PythonScripts) {

        $NewUserPath = if ([string]::IsNullOrWhiteSpace($UserPath)) {
            $PythonScripts
        }
        else {
            "$UserPath;$PythonScripts"
        }

        [Environment]::SetEnvironmentVariable(
            "Path",
            $NewUserPath,
            "User"
        )
    }

    if (($env:Path -split ';') -notcontains $PythonScripts) {
        $env:Path += ";$PythonScripts"
    }
}

Write-Host " OK" -ForegroundColor Green

# ----------------------------------------------------------
# 3. INSTALL UI AUTOMATION DEPENDENCY
# ----------------------------------------------------------

Write-Host "[3/8] Installing uiautomation dependency..." -NoNewline

try {

    & $PythonExe -m pip install --upgrade uiautomation --disable-pip-version-check

    if ($LASTEXITCODE -ne 0) {
        throw "pip installation failed with exit code $LASTEXITCODE"
    }

    # Verify package import
    & $PythonExe -c "import uiautomation"

    if ($LASTEXITCODE -ne 0) {
        throw "uiautomation import verification failed."
    }

    Write-Host " OK" -ForegroundColor Green
}
catch {

    Write-Host " FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $script:InstallerExitCode = 1; return
}

# ----------------------------------------------------------
# 4. DETERMINE SOURCE DIRECTORY
# ----------------------------------------------------------

Write-Host "[4/8] Locating FocusPal source files..." -NoNewline

$ScriptPath = $MyInvocation.MyCommand.Path

if ($ScriptPath) {

    $SourceDir = (Resolve-Path (
        Join-Path (Split-Path $ScriptPath -Parent) ".."
    )).Path

}
else {

    $SourceDir = (Get-Location).Path

}

# Download repository if source files are unavailable
if (-not (Test-Path "$SourceDir\daemon\guardian.py")) {

    Write-Host ""
    Write-Host "Source files not found. Downloading FocusPal..." -ForegroundColor Yellow

    $ZipPath = "$env:TEMP\focuspal-windows-runtime.zip"
    $ExtractDir = "$env:TEMP\focuspal-windows-runtime"

    try {

        if (Test-Path $ExtractDir) {
            Remove-Item $ExtractDir -Recurse -Force
        }

        Invoke-WebRequest `
            -Uri "https://github.com/focuspal-sh/homebrew-tap/releases/download/v1.0.6/focuspal-windows-runtime.zip" `
            -OutFile $ZipPath `
            -UseBasicParsing

        Expand-Archive `
            -Path $ZipPath `
            -DestinationPath $ExtractDir `
            -Force

        $SourceDir = "$ExtractDir"

    }
    catch {

        Write-Host " FAILED" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        $script:InstallerExitCode = 1; return
    }

    if (-not (Test-Path "$SourceDir\daemon\guardian.py")) {
        Write-Host "Repository structure is invalid." -ForegroundColor Red
        $script:InstallerExitCode = 1; return
    }
}

Write-Host " OK" -ForegroundColor Green

# ----------------------------------------------------------
# 5. DEPLOY FILES
# ----------------------------------------------------------

Write-Host "[5/8] Deploying FocusPal files..." -NoNewline

try {

    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
    New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
    New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    New-Item -ItemType Directory -Force -Path "$InstallDir\daemon" | Out-Null
    New-Item -ItemType Directory -Force -Path "$InstallDir\server" | Out-Null

    Copy-Item -Recurse -Force "$SourceDir\daemon\*" "$InstallDir\daemon\"
    Copy-Item -Recurse -Force "$SourceDir\server\*" "$InstallDir\server\"

    if (Test-Path "$SourceDir\config") {
        Copy-Item -Recurse -Force "$SourceDir\config\*" "$InstallDir\config\"
    }

    if (Test-Path "$SourceDir\bin\focuspal.cmd") {
        Copy-Item -Force "$SourceDir\bin\focuspal.cmd" "$BinDir\focuspal.cmd"
    }

}
catch {

    Write-Host " FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $script:InstallerExitCode = 1; return
}

Write-Host " OK" -ForegroundColor Green

# ----------------------------------------------------------
# 6. CONFIGURE FOCUSPAL PATH
# ----------------------------------------------------------

Write-Host "[6/8] Configuring FocusPal PATH..." -NoNewline

try {

    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

    $PathEntries = @()

    if ($UserPath) {
        $PathEntries = $UserPath -split ';'
    }

    if ($PathEntries -notcontains $BinDir) {

        $NewUserPath = if ([string]::IsNullOrWhiteSpace($UserPath)) {
            $BinDir
        }
        else {
            "$UserPath;$BinDir"
        }

        [Environment]::SetEnvironmentVariable(
            "Path",
            $NewUserPath,
            "User"
        )
    }

    if (($env:Path -split ';') -notcontains $BinDir) {
        $env:Path += ";$BinDir"
    }

}
catch {

    Write-Host " FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $script:InstallerExitCode = 1; return
}

Write-Host " OK" -ForegroundColor Green

# ----------------------------------------------------------
# 7. CONFIGURE WINDOWS BACKGROUND TASK
# ----------------------------------------------------------

Write-Host "[7/8] Configuring FocusPal background task..." -NoNewline

$PythonW = Join-Path $PythonDir "pythonw.exe"

if (-not (Test-Path $PythonW)) {

    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "pythonw.exe was not found at $PythonW" -ForegroundColor Red

    $script:InstallerExitCode = 1; return
}

$GuardianScript = "$InstallDir\daemon\guardian.py"

if (-not (Test-Path $GuardianScript)) {

    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "guardian.py was not found." -ForegroundColor Red

    $script:InstallerExitCode = 1; return
}

try {

    $TaskAction = "`"$PythonW`" `"$GuardianScript`""

    schtasks /create `
        /tn $TaskName `
        /tr $TaskAction `
        /sc onlogon `
        /f | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create scheduled task."
    }

}
catch {

    Write-Host " FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $script:InstallerExitCode = 1; return
}

Write-Host " OK" -ForegroundColor Green

# ----------------------------------------------------------
# 8. START AND VERIFY FOCUSPAL
# ----------------------------------------------------------

Write-Host "[8/8] Starting FocusPal background daemon..." -NoNewline

try {

    # Avoid starting another instance if the server is already running
    $AlreadyRunning = $false

    try {
        $null = Invoke-RestMethod `
            -Uri "http://127.0.0.1:8989/api/status" `
            -TimeoutSec 2

        $AlreadyRunning = $true
    }
    catch {}

    if (-not $AlreadyRunning) {

        Start-Process `
            -FilePath $PythonW `
            -ArgumentList "`"$GuardianScript`"" `
            -WorkingDirectory "$InstallDir\daemon" `
            -WindowStyle Hidden

    }

    Start-Sleep -Seconds 3

    try {

        $Response = Invoke-RestMethod `
            -Uri "http://127.0.0.1:8989/api/status" `
            -TimeoutSec 5

        Write-Host " RUNNING" -ForegroundColor Green

    }
    catch {

        Write-Host " STARTED (verification pending)" -ForegroundColor Yellow

    }

}
catch {

    Write-Host " FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

}

# ----------------------------------------------------------
# INSTALLATION COMPLETE
# ----------------------------------------------------------

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "          Focus Pal Installed on Windows!                 " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

Write-Host ""
Write-Host "Installation directory:" -ForegroundColor Cyan
Write-Host "  $InstallDir"

Write-Host ""
Write-Host "Python executable:" -ForegroundColor Cyan
Write-Host "  $PythonExe"

Write-Host ""
Write-Host "Background daemon:" -ForegroundColor Cyan
Write-Host "  $GuardianScript"

Write-Host ""
Write-Host "Available commands:" -ForegroundColor Cyan
Write-Host "  focuspal status   - Check health and server status"
Write-Host "  focuspal test     - Run interactive terminal console"
Write-Host "  focuspal stop     - Stop background service"
Write-Host "  focuspal start    - Restart background service"

Write-Host ""
Write-Host "To uninstall FocusPal:" -ForegroundColor Yellow
Write-Host "  .\install.ps1 -Uninstall"

Write-Host ""
Write-Host "NOTE: Open a NEW PowerShell window to use the updated PATH." -ForegroundColor Yellow

Write-Host ""
}

$script:InstallerExitCode = 0
Invoke-FocusPalInstaller
if ($MyInvocation.MyCommand.Path) {
    exit $script:InstallerExitCode
}
