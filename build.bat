@echo off
chcp 65001 > nul
echo [INFO] Docker를 이용해 Spring Server 빌드를 시작합니다...

:: %~dp0는 이 배치 파일이 위치한 경로를 의미합니다.
docker run --rm -v "%~dp0spring-server:/app" -w /app maven:3.9-eclipse-temurin-17 mvn compile dependency:copy-dependencies -DoutputDirectory=target/dependency

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 빌드 중 오류가 발생했습니다.
    pause
    exit /b %errorlevel%
)

echo.
echo [SUCCESS] 빌드가 성공적으로 마무리되었습니다!
pause