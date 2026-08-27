@echo off

cd /d "%~dp0"

docker compose -f docker-compose.dev.yml up -d

if %errorlevel% neq 0 (
    pause
    exit /b %errorlevel%
)

pause
