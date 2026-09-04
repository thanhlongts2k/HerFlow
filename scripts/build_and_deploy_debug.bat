@echo off
chcp 65001 >nul
echo ========================================================
echo   MOONA - BUILD DEBUG APK & DEPLOY TO DEVICE
echo ========================================================

echo [*] 1. Building debug APK (android-arm64)...
call flutter build apk --debug --target-platform android-arm64
if %errorlevel% neq 0 (
    echo [ERROR] flutter build apk failed!
    exit /b %errorlevel%
)

echo [*] 2. Checking generated APK...
if not exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo [ERROR] APK not found at build\app\outputs\flutter-apk\app-debug.apk!
    exit /b 1
)

echo [*] 3. Installing APK to physical phone (2201116TG)...
adb -s "adb-BM6HKBHEHQKFEMLR-prj23i._adb-tls-connect._tcp" install -r -d build\app\outputs\flutter-apk\app-debug.apk

echo [*] 3b. Also installing to emulator (PHM110) as backup...
adb -s emulator-5554 install -r -d build\app\outputs\flutter-apk\app-debug.apk

echo [*] 4. Starting MainActivity on physical phone...
adb -s "adb-BM6HKBHEHQKFEMLR-prj23i._adb-tls-connect._tcp" shell am start -n com.herflow.app.herflow/.MainActivity

echo [*] 4b. Starting MainActivity on emulator...
adb -s emulator-5554 shell am start -n com.herflow.app.herflow/.MainActivity

echo [SUCCESS] Build and installation completed successfully!
exit /b 0
