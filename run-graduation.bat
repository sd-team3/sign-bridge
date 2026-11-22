@echo off
setlocal
cd /d "%~dp0"
docker info --format "{{.ServerVersion}}" >nul 2>&1
if errorlevel 1 (
    echo Start Docker Desktop in Linux container mode, then try again.
    goto failed
)
if exist "images\signbridge-graduation-images.tar" (
    for %%I in (mysql:8.4.9 es-with-nori:8.15.0 signbridge-graduation-python:1 signbridge-graduation-spring:1) do (
        docker image inspect %%I >nul 2>&1
        if errorlevel 1 goto load_images
    )
    goto start_app
)
if not exist "spring-server\Dockerfile" (
    echo The offline image archive is missing from images.
    goto failed
)
docker compose -f docker-compose.graduation.yml pull db
if errorlevel 1 goto failed
docker compose -f docker-compose.graduation.yml build
if errorlevel 1 goto failed
goto start_app

:load_images
docker load --input "images\signbridge-graduation-images.tar"
if errorlevel 1 goto failed

:start_app
docker compose -f docker-compose.graduation.yml up -d --no-build --pull never --wait --wait-timeout 240
if errorlevel 1 goto failed
start "" "http://localhost:8080/"
exit /b 0

:failed
docker compose -f docker-compose.graduation.yml ps -a
echo Startup failed. Run docker compose -f docker-compose.graduation.yml logs --tail 80 for details.
pause
exit /b 1
