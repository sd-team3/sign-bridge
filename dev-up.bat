@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-SignBridge.ps1" %*
if errorlevel 1 (
    pause
    exit /b 1
)
start "" "http://localhost:8080/"
