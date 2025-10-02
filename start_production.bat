@echo off
echo Starting Falcon Chat Production Server...
echo.

echo Checking Node.js...
node --version
if errorlevel 1 (
    echo ERROR: Node.js not found! Please install Node.js
    pause
    exit /b 1
)

echo Checking MySQL connection...
echo Please ensure MySQL is running and accessible

echo.
echo Starting backend server...
cd backend
npm start

pause