@echo off
echo Adding firewall rule for Falcon Chat Server...
echo This will allow connections on port 3001
echo.

netsh advfirewall firewall add rule name="Falcon Chat Server" dir=in action=allow protocol=TCP localport=3001

if %errorlevel% == 0 (
    echo.
    echo Firewall rule added successfully!
    echo Falcon Chat Server should now be accessible from other devices on the network.
) else (
    echo.
    echo Failed to add firewall rule. You may need to run this as administrator.
    echo Right-click on this file and select "Run as administrator"
)

echo.
echo Press any key to exit...
pause >nul