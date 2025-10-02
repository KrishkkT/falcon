@echo off
echo Falcon Chat - Final Verification
echo ================================

echo.
echo 1. Checking if server is running...
netstat -an | findstr :3001 >nul
if %errorlevel% == 0 (
    echo    [OK] Server is running on port 3001
) else (
    echo    [WARNING] Server may not be running on port 3001
)

echo.
echo 2. Checking firewall rule...
netsh advfirewall firewall show rule name="Falcon Chat Server" >nul 2>&1
if %errorlevel% == 0 (
    echo    [OK] Firewall rule exists
) else (
    echo    [ACTION REQUIRED] Run add_firewall_rule.bat as administrator
)

echo.
echo 3. Checking network configuration...
ipconfig | findstr "172.20.10.2" >nul
if %errorlevel% == 0 (
    echo    [OK] Laptop IP is 172.20.10.2
) else (
    echo    [INFO] Laptop IP may have changed - check with ipconfig
)

echo.
echo 4. Checking database connectivity...
cd backend
node -e "require('dotenv').config(); const mysql = require('mysql2'); const pool = mysql.createPool({host: process.env.DB_HOST || 'localhost', port: process.env.DB_PORT || 3306, user: process.env.DB_USER || 'kt', password: process.env.DB_PASSWORD || 'thekt', database: process.env.DB_NAME || 'falcon_chat'}); pool.getConnection((err, connection) => { if (err) { console.log('    [ERROR] Database connection failed'); } else { console.log('    [OK] Database connection successful'); connection.release(); } });" >nul 2>&1
if %errorlevel% == 0 (
    echo    [OK] Database connection test passed
) else (
    echo    [ERROR] Database connection test failed
)

echo.
echo 5. Checking mobile app configuration...
findstr "172.20.10.2" ..\lib\services\network_config_service.dart >nul 2>&1
if %errorlevel% == 0 (
    echo    [OK] Mobile app configured for 172.20.10.2
) else (
    echo    [WARNING] Mobile app may not be configured correctly
)

echo.
echo === Final Check Summary ===
echo.
echo If all checks show [OK]:
echo ✅ Your Falcon Chat setup is ready for testing!
echo.
echo If any checks show [ACTION REQUIRED]:
echo ❌ Please follow the troubleshooting steps in RESOLUTION_SUMMARY.md
echo.
echo To test with multiple phones:
echo 1. Ensure all devices are on the same network (phone hotspot)
echo 2. Run add_firewall_rule.bat as administrator
echo 3. Start the server with start_server_with_firewall.bat
echo 4. Install the app on your test phones
echo 5. Register users and test messaging
echo.
echo Press any key to exit...
pause >nul