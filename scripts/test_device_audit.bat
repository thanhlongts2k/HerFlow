@echo off
chcp 65001 >nul
echo ========================================================
echo   MOONA - AUTOMATED DEVICE AUDIT ^& STRESS TEST
echo ========================================================

echo [*] 1. Kiem tra thiet bi Android ket noi...
adb devices

echo [*] 2. Cai dat ban Release APK v0.6.2 len thiet bi...
adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

echo [*] 3. Don sach logcat cu...
adb logcat -c

echo [*] 4. Khoi chay ung dung Moona...
adb shell am start -n com.herflow.app.herflow/.MainActivity
ping 127.0.0.1 -n 4 >nul

echo [*] 5. Kich hoat cac kich ban kiem thu tren man hinh...
:: Tap mo giao dien / focus vao o nhap de bung ban phim ao
adb shell input tap 540 1200
ping 127.0.0.1 -n 2 >nul
adb shell input text "MoonaAudit"
ping 127.0.0.1 -n 2 >nul
:: An phim Back de dong ban phim ao
adb shell input keyevent 4
ping 127.0.0.1 -n 2 >nul

:: Kich ban 2: Mo phong spam click / multi-tap
echo [*] 6. Mo phong spam multi-tap vao nut bam...
adb shell input tap 540 1800
adb shell input tap 540 1800
adb shell input tap 540 1800
ping 127.0.0.1 -n 3 >nul

echo [*] 7. Trich xuat log loi thoi gian thuc...
if not exist "build" mkdir "build"
adb logcat -d | findstr /i "overflow exception fatal flutter herflow" > build\test_audit_log.txt

echo ========================================================
echo [DONE] Hoan tat kiem thu thiet bi. Log da luu tai build\test_audit_log.txt
echo ========================================================
