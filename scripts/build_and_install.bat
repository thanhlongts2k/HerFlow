@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo        MOONA - BUILD ^& INSTALL OPTIMIZED APK
echo ========================================================

cd /d "%~dp0\.."

rem 1. Cap nhat Icon chuan Trang dung & 2 Ngoi sao
echo [*] Buoc 1: Kiem tra va cap nhat Icon Moona...
python scripts\generate_app_icon.py 2>nul
if %ERRORLEVEL% equ 0 (
    echo [OK] Da tao xong app_icon.png va moona_logo.png - Trang dung va 2 ngoi sao.
    echo [*] Cap nhat bo Launcher Icons qua flutter_launcher_icons...
    call dart run flutter_launcher_icons
) else (
    echo [!] Python script hoac thu vien PIL chua san sang, giu nguyen asset icon.
)

rem 2. Chuan hoa Shared Debug Keystore trong project
echo.
echo [*] Buoc 2: Chuan hoa Shared Debug Keystore trong project...
if not exist "android\app\debug.keystore" (
    if exist "%USERPROFILE%\.android\debug.keystore" (
        echo [*] Sao chep debug.keystore tu may hien tai vao android\app\debug.keystore...
        copy "%USERPROFILE%\.android\debug.keystore" "android\app\debug.keystore" >nul
    ) else (
        echo [*] Khoi tao debug.keystore moi bang keytool...
        keytool -genkey -v -keystore android\app\debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
    )
)

echo.
echo ========================================================
echo [*] MA VAN TAY SHA-1 DUNG CHUNG CHO CA CONG TY VA O NHA:
keytool -list -v -keystore android\app\debug.keystore -alias androiddebugkey -storepass android -keypass android 2>nul | findstr /i "SHA1 SHA256"
echo ========================================================

rem 3. Xac dinh che do build - mac dinh la release
set "BUILD_MODE=release"
if /i "%~1"=="debug" set "BUILD_MODE=debug"

echo.
echo [*] Buoc 3: Kiem tra chat luong ma nguon: flutter analyze va flutter test...
call flutter analyze
if %ERRORLEVEL% neq 0 (
    echo [XX] flutter analyze phat hien loi, dung tien trinh build!
    exit /b %ERRORLEVEL%
)
call flutter test
if %ERRORLEVEL% neq 0 (
    echo [XX] flutter test co test that bai, dung tien trinh build!
    exit /b %ERRORLEVEL%
)
echo [OK] Quality Gate passed: 0 issues, 100 percent tests passed!

echo.
echo [*] Buoc 4: Khoi chay Flutter Build: %BUILD_MODE% split-per-abi...
echo.

if /i "%~1"=="analyze" (
    echo [*] Chay phan tich dung luong APK chuyen sau: analyze-size...
    call flutter build apk --release --target-platform android-arm64 --analyze-size
    echo.
    echo [*] Xuat bo split-per-abi release APK...
    call flutter build apk --release --split-per-abi
) else (
    call flutter build apk --%BUILD_MODE% --split-per-abi
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo [XX] Build FAILED with error code %ERRORLEVEL%!
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo [OK] Flutter Build Completed Successfully!
echo ========================================================
echo.

set "APK_DIR=build\app\outputs\flutter-apk"
echo [*] Danh sach APK xuat xuong:
dir "%APK_DIR%\*.apk" 2>nul | findstr /i ".apk"

rem 3. Kiem tra thiet bi Android ket noi qua ADB
set "CONNECTED_DEVICE="
for /f "tokens=1,2" %%A in ('adb devices 2^>nul') do (
    if "%%B"=="device" (
        if not defined CONNECTED_DEVICE set "CONNECTED_DEVICE=%%A"
    )
)

set "DEVICE_ABI="
if defined CONNECTED_DEVICE (
    echo.
    echo [*] Phat hien thiet bi ADB: !CONNECTED_DEVICE!
    for /f "usebackq delims=" %%i in (`adb -s !CONNECTED_DEVICE! shell getprop ro.product.cpu.abi 2^>nul`) do (
        set "DEVICE_ABI=%%i"
    )
    set "DEVICE_ABI=!DEVICE_ABI: =!"
    echo [*] Kien truc CPU thiet bi: !DEVICE_ABI!
) else (
    echo.
    echo [!] Chua co thiet bi Android nao ket noi qua ADB.
)

rem 4. Tu dong chon dung file APK phu hop
set "TARGET_APK="
if defined DEVICE_ABI (
    if exist "%APK_DIR%\app-!DEVICE_ABI!-%BUILD_MODE%.apk" (
        set "TARGET_APK=%APK_DIR%\app-!DEVICE_ABI!-%BUILD_MODE%.apk"
    )
)

if not defined TARGET_APK (
    if exist "%APK_DIR%\app-arm64-v8a-%BUILD_MODE%.apk" (
        set "TARGET_APK=%APK_DIR%\app-arm64-v8a-%BUILD_MODE%.apk"
    ) else if exist "%APK_DIR%\app-armeabi-v7a-%BUILD_MODE%.apk" (
        set "TARGET_APK=%APK_DIR%\app-armeabi-v7a-%BUILD_MODE%.apk"
    ) else if exist "%APK_DIR%\app-x86_64-%BUILD_MODE%.apk" (
        set "TARGET_APK=%APK_DIR%\app-x86_64-%BUILD_MODE%.apk"
    ) else if exist "%APK_DIR%\app-%BUILD_MODE%.apk" (
        set "TARGET_APK=%APK_DIR%\app-%BUILD_MODE%.apk"
    )
)

if not defined TARGET_APK (
    echo [XX] Loi: Khong tim thay file APK phu hop trong %APK_DIR%!
    exit /b 1
)

echo.
echo ========================================================
echo [*] File APK duoc lua chon: %TARGET_APK%
for %%F in ("%TARGET_APK%") do (
    set /a "SIZE_MB=%%~zF / 1048576"
    echo [*] Dung luong file: %%~zF bytes (~!SIZE_MB! MB)
)
echo.
echo [*] KIEM TOAN CHUNG CHI THUC TE TRONG TEP APK VUA BUILD:
keytool -printcert -jarfile "%TARGET_APK%" 2>nul | findstr /i "Owner SHA1 SHA256"
echo ========================================================

rem 5. Cai dat len thiet bi neu co ket noi
if defined CONNECTED_DEVICE (
    echo.
    echo [*] Don dep cache ung dung cu tren thiet bi !CONNECTED_DEVICE!...
    adb -s !CONNECTED_DEVICE! shell pm clear com.herflow.app.herflow 2>nul

    echo [*] Dang cai dat %TARGET_APK% len thiet bi !CONNECTED_DEVICE!...
    adb -s !CONNECTED_DEVICE! install -r -d -t "%TARGET_APK%"
    if !ERRORLEVEL! neq 0 (
        echo [!] Cai dat truc tiep chua thanh cong, thu go ban cu va cai moi sach...
        adb -s !CONNECTED_DEVICE! uninstall com.herflow.app.herflow
        adb -s !CONNECTED_DEVICE! install -t -d "%TARGET_APK%"
    )
    if !ERRORLEVEL! equ 0 (
        echo.
        echo [OK] Cai dat thanh cong len thiet bi !CONNECTED_DEVICE!!
        echo [*] Khoi dong ung dung Moona tren thiet bi...
        adb -s !CONNECTED_DEVICE! shell am start -n com.herflow.app.herflow/.MainActivity
    ) else (
        echo [XX] Cai dat len thiet bi that bai!
    )
) else (
    echo.
    echo [*] File APK da san sang de cai dat khi thiet bi duoc ket noi qua cap USB.
)

echo.
echo ========================================================
echo [DONE] Hoan tat quy trinh build va toi uu APK.
echo ========================================================
exit /b 0
