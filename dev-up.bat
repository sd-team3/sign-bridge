@echo off
chcp 65001 > nul
echo [INFO] 개발 환경 컨테이너를 실행합니다 (docker-compose.dev.yml)...

:: 배치 파일이 위치한 경로로 이동
cd /d "%~dp0"

docker compose -f docker-compose.dev.yml up -d

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Docker Compose 실행 중 오류가 발생했습니다.
    pause
    exit /b %errorlevel%
)

echo.
echo [SUCCESS] 컨테이너가 백그라운드(-d)에서 정상적으로 시작되었습니다!
pause