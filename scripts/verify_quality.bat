@echo off
chcp 65001 >nul
echo ========================================================
echo   MOONA - QUALITY AUDIT ^& RELEASE BUILD ENGINE
echo ========================================================

echo [*] 1. Dang chay flutter pub get...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] flutter pub get that bai!
    exit /b %errorlevel%
)

echo [*] 2. Dang chay flutter test...
call flutter test
if %errorlevel% neq 0 (
    echo [ERROR] flutter test that bai!
    exit /b %errorlevel%
)

echo [*] 3. Dang chay flutter analyze...
call flutter analyze
if %errorlevel% neq 0 (
    echo [ERROR] flutter analyze phat hien loi!
    exit /b %errorlevel%
)

echo [*] 4. Dang bien dich thuc te: flutter build apk --release --split-per-abi...
call flutter build apk --release --split-per-abi
if %errorlevel% neq 0 (
    echo [ERROR] flutter build apk that bai!
    exit /b %errorlevel%
)

echo ========================================================
echo [SUCCESS] TAT CA QUALITY GATES ^& RELEASE APK XUAT XUONG HOAN HAO!
echo ========================================================
