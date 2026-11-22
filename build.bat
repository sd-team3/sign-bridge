@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-SignBridge.ps1" -BuildOnly %*
if errorlevel 1 (
    pause
    exit /b 1
)
