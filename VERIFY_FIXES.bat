@echo off
title Falcon Chat - Fix Verification

echo ==============================================
echo Falcon Chat - Fix Verification Script
echo ==============================================
echo.

echo 1. Checking network configuration files...
echo ----------------------------------------
findstr /C:"13.126.123.252" lib\services\network_config_service.dart >nul
if %errorlevel% equ 0 (
    echo ✅ Network config service updated with new IP
) else (
    echo ❌ Network config service not updated
)

findstr /C:"13.126.123.252" lib\main.dart >nul
if %errorlevel% equ 0 (
    echo ✅ Main app updated with new IP
) else (
    echo ❌ Main app not updated
)

echo.
echo 2. Checking database configuration...
echo ----------------------------------
findstr /C:"Thekt@123" backend\.env >nul
if %errorlevel% equ 0 (
    echo ✅ .env file updated with correct password
) else (
    echo ❌ .env file not updated
)

findstr /C:"Thekt@123" backend\.env.production >nul
if %errorlevel% equ 0 (
    echo ✅ .env.production file updated with correct password
) else (
    echo ❌ .env.production file not updated
)

echo.
echo 3. Checking for new contacts feature...
echo ------------------------------------
if exist lib\screens\contacts_screen.dart (
    echo ✅ Contacts screen created
) else (
    echo ❌ Contacts screen missing
)

findstr /C:"contacts_screen.dart" lib\main.dart >nul
if %errorlevel% equ 0 (
    echo ✅ Contacts route added to main app
) else (
    echo ❌ Contacts route not added
)

echo.
echo 4. Checking build configuration...
echo -------------------------------
findstr /C:"isMinifyEnabled" android\app\build.gradle.kts >nul
if %errorlevel% equ 0 (
    echo ✅ Build.gradle.kts syntax fixed
) else (
    echo ❌ Build.gradle.kts may have syntax issues
)

echo.
echo 5. Checking documentation...
echo -------------------------
if exist FINAL_FIXES_FOR_PRODUCTION.md (
    echo ✅ Production fix documentation created
) else (
    echo ❌ Production fix documentation missing
)

if exist DEPLOYMENT_COMPLETE_GUIDE.md (
    echo ✅ Deployment guide created
) else (
    echo ❌ Deployment guide missing
)

if exist STARTUP_GUIDE.md (
    echo ✅ Startup guide created
) else (
    echo ❌ Startup guide missing
)

echo.
echo ==============================================
echo Verification complete!
echo ==============================================
echo.
echo Next steps:
echo 1. Create database user 'kt' with password 'Thekt@123'
echo 2. Grant privileges to falcon_chat database
echo 3. Start backend server: cd backend ^&^& node index.js
echo 4. Build mobile app: flutter build apk --release
echo.
pause