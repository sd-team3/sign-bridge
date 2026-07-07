@echo off
set CATALINA_HOME=C:\Program Files\Apache Software Foundation\Tomcat 9.0
set JAVA_HOME=C:\Program Files\Java\jdk-24

echo Building WAR...
call mvn clean package -q
if errorlevel 1 (
    echo BUILD FAILED - WAR was not created.
    exit /b 1
)

echo Stopping Tomcat...
taskkill /f /im tomcat9.exe 2>nul
timeout /t 3 /nobreak >nul

echo Killing port 8080...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do (
    echo PID %%a 종료 중...
    taskkill /f /pid %%a 2>nul
)
timeout /t 2 /nobreak >nul

echo Deploying...
del "%CATALINA_HOME%\webapps\ROOT.war" 2>nul
rd /s /q "%CATALINA_HOME%\webapps\ROOT" 2>nul
copy "target\spring-board.war" "%CATALINA_HOME%\webapps\ROOT.war"

echo Starting Tomcat...
start "" "%CATALINA_HOME%\bin\startup.bat"

echo Done! localhost:8080
