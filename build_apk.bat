@echo off
echo ====================================
echo Falcon Chat - Production Build Script
echo ====================================
echo.

echo [1/6] Cleaning previous builds...
flutter clean
echo.

echo [2/6] Getting dependencies...
flutter pub get
echo.

echo [3/6] Running code analysis...
flutter analyze --no-fatal-infos
if %ERRORLEVEL% neq 0 (
    echo Warning: Analysis found issues. Continuing build...
    echo.
)

echo [4/6] Running tests...
flutter test
if %ERRORLEVEL% neq 0 (
    echo Warning: Tests failed. Continuing build...
    echo.
)

echo [5/6] Building debug APK...
flutter build apk --debug
echo.

echo [6/6] Building release APK...
flutter build apk --release
echo.

echo ====================================
echo Build Complete!
echo ====================================
echo.
echo Debug APK:   build\app\outputs\flutter-apk\app-debug.apk
echo Release APK: build\app\outputs\flutter-apk\app-release.apk
echo.
echo File sizes:
dir build\app\outputs\flutter-apk\*.apk /B
echo.
echo Ready for deployment! 🚀
echo.
pause