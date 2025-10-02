@echo off
echo Falcon Chat Server Startup Script
echo =================================

echo.
echo Adding firewall rule for Falcon Chat Server...
netsh advfirewall firewall add rule name="Falcon Chat Server" dir=in action=allow protocol=TCP localport=3001 >nul 2>&1

if %errorlevel% == 0 (
    echo [OK] Firewall rule added successfully
) else (
    echo [WARNING] Could not add firewall rule - you may need to run as administrator
    echo          Right-click on this file and select "Run as administrator"
)

echo.
echo Starting Falcon Chat Server...
echo Make sure your mobile devices are connected to the same network
echo Server IP: 172.20.10.2
echo Port: 3001
echo.

cd backend
node index.js

echo.
echo Press any key to exit...
pause >nul