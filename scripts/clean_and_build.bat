@echo off
chcp 65001 >nul
echo [*] Stopping gradle daemon to release file locks...
cd android
call gradlew.bat --stop
cd ..

echo [*] Removing locked build directory if present...
rmdir /s /q "build\app\outputs\apk\debug" 2>nul

echo [*] Running flutter build apk --debug --target-platform android-arm64...
call flutter build apk --debug --target-platform android-arm64
if %errorlevel% neq 0 (
    echo [ERROR] flutter build apk failed!
    exit /b %errorlevel%
)

echo [*] Installing on physical phone (2201116TG)...
adb -s "adb-BM6HKBHEHQKFEMLR-prj23i._adb-tls-connect._tcp" install -r -d build\app\outputs\flutter-apk\app-debug.apk

echo [*] Installing on emulator (emulator-5554)...
adb -s emulator-5554 install -r -d build\app\outputs\flutter-apk\app-debug.apk

echo [*] Starting MainActivity on physical phone...
adb -s "adb-BM6HKBHEHQKFEMLR-prj23i._adb-tls-connect._tcp" shell am start -n com.herflow.app.herflow/.MainActivity

echo [*] Starting MainActivity on emulator...
adb -s emulator-5554 shell am start -n com.herflow.app.herflow/.MainActivity

echo [SUCCESS] App built, deployed, and launched successfully on both devices!
exit /b 0
