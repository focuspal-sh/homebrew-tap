@echo off
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."

if "%~1"=="" goto help
if "%~1"=="status" goto status
if "%~1"=="start" goto start
if "%~1"=="stop" goto stop
if "%~1"=="test" goto test
if "%~1"=="reload" goto reload
goto help

:status
powershell -NoProfile -Command "try { $r = Invoke-RestMethod -Uri http://127.0.0.1:8989/api/status -TimeoutSec 2; Write-Host '• Focus Pal: RUNNING (http://127.0.0.1:8989/blocked)' -ForegroundColor Green } catch { Write-Host '• Focus Pal: NOT RUNNING' -ForegroundColor Red }"
goto end

:start
powershell -NoProfile -Command "Start-Process pythonw.exe -ArgumentList '\"%PROJECT_DIR%\daemon\guardian.py\"' -WindowStyle Hidden"
echo Focus Pal started in background.
goto end

:test
python "%PROJECT_DIR%\daemon\guardian.py" --foreground
goto end

:stop
powershell -NoProfile -Command "$p = (Get-NetTCPConnection -LocalPort 8989 -ErrorAction SilentlyContinue).OwningProcess; if ($p) { Stop-Process -Id $p -Force; Write-Host 'Focus Pal stopped.' -ForegroundColor Yellow } else { Write-Host 'Focus Pal is not currently running.' }"
goto end

:reload
powershell -NoProfile -Command "try { Invoke-RestMethod -Uri http://127.0.0.1:8989/api/reload -Method Post; Write-Host 'Reloaded rules successfully.' -ForegroundColor Green } catch { Write-Host 'Failed to reload.' -ForegroundColor Red }"
goto end

:help
echo Focus Pal CLI for Windows
echo Usage: focuspal [status ^| start ^| test ^| stop ^| reload]
goto end

:end

