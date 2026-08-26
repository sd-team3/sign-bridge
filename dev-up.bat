@echo off

cd /d "%~dp0"

docker compose -f docker-compose.dev.yml up -d --build

if %errorlevel% neq 0 (
    pause
    exit /b %errorlevel%
)

timeout /t 5 /nobreak > nul
docker compose -f docker-compose.dev.yml ps

pause
