@echo off
REM Build script for Lighty SDNR application
REM
REM Prerequisites:
REM   - JDK 17 or 21
REM   - Maven 3.8+
REM   - NETCONF model artifacts (6.0.6-SNAPSHOT) already in Maven repo
REM
REM Usage:
REM   build-app.bat              # Build app only
REM   build-app.bat --docker     # Build app + Docker image

setlocal enabledelayedexpansion

echo ========================================
echo   Lighty SDNR App Build Script
echo ========================================
echo.

set SETTINGS=%~dp0build-settings.xml
set SSL_OPTS=-Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true

set BUILD_DOCKER=false
if "%1"=="--docker" set BUILD_DOCKER=true

echo [1/4] Checking prerequisites...
where java >nul 2>&1
if %errorlevel% neq 0 (
    echo   ERROR: Java not found.
    exit /b 1
)
echo   Java: OK

where mvn >nul 2>&1
if %errorlevel% neq 0 (
    echo   ERROR: Maven not found.
    exit /b 1
)
echo   Maven: OK
echo.

echo [2/4] Building Lighty modules...
cd /d %~dp0
call mvn clean install -f modules/pom.xml -s "%SETTINGS%" -DskipTests %SSL_OPTS%
if %errorlevel% neq 0 (
    echo   ERROR: Modules build failed
    exit /b 1
)
echo     Modules OK
echo.

echo [3/4] Building Lighty SDNR application...
call mvn clean install -f applications/pom.xml -s "%SETTINGS%" -DskipTests %SSL_OPTS%
if %errorlevel% neq 0 (
    echo   ERROR: Application build failed
    exit /b 1
)
echo     Application OK
echo.

if "%BUILD_DOCKER%"=="true" (
    echo [4/4] Building Docker image...
    cd /d %~dp0applications\lighty-sdnr-lite\lighty-sdnr-lite-docker
    call mvn package docker:build -s "%SETTINGS%" -DskipTests %SSL_OPTS%
    if %errorlevel% neq 0 (
        echo   ERROR: Docker build failed
        exit /b 1
    )
    echo     Docker OK
    cd /d %~dp0
) else (
    echo [4/4] Skipping Docker build (use --docker flag to include)
)
echo.

echo ========================================
echo   Build Complete!
echo ========================================
echo.
echo Artifacts:
echo   - Lighty app JAR: applications\lighty-sdnr-lite\lighty-sdnr-lite-app\target\
echo.
