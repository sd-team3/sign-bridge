@echo off

docker run --rm -v "%~dp0spring-server:/app" -w /app maven:3.9-eclipse-temurin-17 mvn compile dependency:copy-dependencies -DoutputDirectory=target/dependency

if %errorlevel% neq 0 (
    pause
    exit /b %errorlevel%
)

cd /d "%~dp0"

docker compose -f docker-compose.dev.yml build python-server spring-compiler

if %errorlevel% neq 0 (
    pause
    exit /b %errorlevel%
)

pause
