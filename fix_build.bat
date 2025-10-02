@echo off
echo ========================================
echo Falcon Chat - Build Issue Fixer
echo ========================================

echo.
echo Stopping any running Java/Gradle processes...
taskkill /f /im java.exe 2>nul
taskkill /f /im adb.exe 2>nul
echo Processes stopped.

echo.
echo Stopping Gradle daemons...
cd /d "%~dp0android"
call gradlew --stop
echo Gradle daemons stopped.

echo.
echo Cleaning Flutter build...
cd /d "%~dp0"
call flutter clean
echo Flutter clean completed.

echo.
echo Getting Flutter packages...
call flutter pub get
echo Packages updated.

echo.
echo ========================================
echo Build fix completed!
echo.
echo Now you can run:
echo flutter build apk --release
echo ========================================
echo.
echo Press any key to exit...
pause >nul