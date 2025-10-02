@echo off
title MySQL Password Test

echo ==============================================
echo MySQL Root Password Test
echo ==============================================
echo.

echo This script will help you find your MySQL root password.
echo.

set /p mysql_path="Enter MySQL bin directory path (e.g., C:\Program Files\MySQL\MySQL Server 8.0\bin): " 
echo.

if "%mysql_path%"=="" (
    set mysql_path=C:\Program Files\MySQL\MySQL Server 8.0\bin
)

echo Testing common MySQL root passwords...
echo.

cd /d "%mysql_path%" 2>nul
if %errorlevel% neq 0 (
    echo ❌ Could not find MySQL directory: %mysql_path%
    echo Please check your MySQL installation path
    goto end
)

echo 1. Testing connection without password...
mysql -u root -e "SELECT 'Connection successful without password' as result;" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ SUCCESS! Connected without password
    echo You can now create the Falcon Chat database user
    goto create_user
) else (
    echo ❌ Failed to connect without password
)

echo.
echo 2. Testing common passwords...
set passwords=root password admin mysql "" 123456

for %%p in (%passwords%) do (
    echo Testing password: [%%p]
    mysql -u root -p%%p -e "SELECT 'Connection successful' as result;" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ SUCCESS! Root password is: [%%p]
        echo You can now create the Falcon Chat database user
        goto create_user
    ) else (
        echo ❌ Failed with password: [%%p]
    )
    echo.
)

echo.
echo ❌ Could not determine MySQL root password
echo Please try the manual method in MYSQL_PASSWORD_RECOVERY.md
goto end

:create_user
echo.
echo Creating Falcon Chat database user...
mysql -u root -e "CREATE DATABASE IF NOT EXISTS falcon_chat CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; CREATE USER 'kt'@'localhost' IDENTIFIED BY 'Thekt@123'; GRANT ALL PRIVILEGES ON falcon_chat.* TO 'kt'@'localhost'; FLUSH PRIVILEGES;" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Falcon Chat database user created successfully!
    echo.
    echo Next steps:
    echo 1. Start backend server: cd backend ^&^& node index.js
    echo 2. Test API: curl http://localhost:3001/api/health
) else (
    echo ⚠️  Could not create database user automatically
    echo Please run these commands manually in MySQL:
    echo    CREATE DATABASE IF NOT EXISTS falcon_chat CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    echo    CREATE USER 'kt'@'localhost' IDENTIFIED BY 'Thekt@123';
    echo    GRANT ALL PRIVILEGES ON falcon_chat.* TO 'kt'@'localhost';
    echo    FLUSH PRIVILEGES;
)

:end
echo.
echo Press any key to exit...
pause >nul