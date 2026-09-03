# scripts/visual_audit.ps1
# Visual & UX Automated Audit - Moona App
# Chay bang: powershell -ExecutionPolicy Bypass -File .\scripts\visual_audit.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$OUTPUT_DIR = "build\audit_screenshots"
$PACKAGE    = "com.herflow.app.herflow"
$ACTIVITY   = ".MainActivity"
$DUMP_FILE  = "$OUTPUT_DIR\view_dump.xml"

# 0. Chuan bi
New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null
Write-Host ""
Write-Host "========================================"
Write-Host "  Moona Visual Audit Pipeline"
Write-Host "========================================"
Write-Host ""

# Kiem tra thiet bi
$devState = (adb get-state 2>&1)
if ($devState -ne "device") {
    Write-Host "[ERROR] Khong tim thay thiet bi ADB. Ket noi truoc khi chay."
    exit 1
}
Write-Host "[OK] Thiet bi ket noi."

# Helper: Chup man hinh
function Capture-Screen([string]$FileName) {
    adb shell screencap -p /sdcard/moona_audit.png 2>&1 | Out-Null
    adb pull /sdcard/moona_audit.png "$OUTPUT_DIR\$FileName.png" 2>&1 | Out-Null
    $size = (Get-Item "$OUTPUT_DIR\$FileName.png" -ErrorAction SilentlyContinue).Length
    $kb = if ($size) { [math]::Round($size/1024) } else { 0 }
    Write-Host "  [SNAP] $FileName.png  (${kb}KB)"
}

# Helper: Delay
function Wait-UI([int]$Ms = 1500) { Start-Sleep -Milliseconds $Ms }

# 1. Khoi dong app
Write-Host ""
Write-Host "[1/8] Khoi dong app..."
adb shell am force-stop $PACKAGE 2>&1 | Out-Null
Start-Sleep -Milliseconds 800
adb shell am start -n "${PACKAGE}/${ACTIVITY}" 2>&1 | Out-Null
Wait-UI 6000
Capture-Screen "01_app_launch"

# Lay resolution man hinh
$sizeOutput = adb shell wm size 2>&1
$physLine = $sizeOutput | Where-Object { $_ -match "Physical size:" }
$screenH = 2400
if ($physLine -match "(\d+)x(\d+)") {
    $screenH = [int]$Matches[2]
}
$navY   = [int]($screenH * 0.955)   # ~96% chieu cao = vung BottomNav
$tab0X  = [int](1080 * 0.11)        # Tab 0: ~120px
$tab1X  = [int](1080 * 0.37)        # Tab 1: ~400px
$tab2X  = [int](1080 * 0.63)        # Tab 2: ~680px
$tab3X  = [int](1080 * 0.89)        # Tab 3: ~960px

Write-Host "  [INFO] Screen: 1080x${screenH}, BottomNav Y=${navY}"

# 2. Tab Trang chu / Chu ky (index 0 - mac dinh)
Write-Host "[2/8] Tab Chu ky..."
adb shell input tap $tab0X $navY 2>&1 | Out-Null
Wait-UI 1500
Capture-Screen "02_tab_cycle"

# 3. Tab Cam xuc (index 1)
Write-Host "[3/8] Tab Cam xuc..."
adb shell input tap $tab1X $navY 2>&1 | Out-Null
Wait-UI 1500
Capture-Screen "03_tab_mood"

# 4. Tab Dinh duong (index 2)
Write-Host "[4/8] Tab Dinh duong..."
adb shell input tap $tab2X $navY 2>&1 | Out-Null
Wait-UI 1500
Capture-Screen "04_tab_nutrition"

# 5. Tab Cai dat (index 3)
Write-Host "[5/8] Tab Cai dat..."
adb shell input tap $tab3X $navY 2>&1 | Out-Null
Wait-UI 1800
Capture-Screen "05_tab_settings"

# 6. Mo dialog Dang xuat (sau khi dang o Settings, scroll xuong va tap)
Write-Host "[6/8] Mo dialog Dang xuat..."
adb shell input swipe 540 1800 540 600 500 2>&1 | Out-Null
Wait-UI 800
adb shell input swipe 540 1800 540 600 500 2>&1 | Out-Null
Wait-UI 800
adb shell input tap 540 1900 2>&1 | Out-Null
Wait-UI 1500
Capture-Screen "06_dialog_logout"
adb shell input keyevent KEYCODE_BACK 2>&1 | Out-Null
Wait-UI 600

# 7. Pairing Screen
Write-Host "[7/8] Man hinh Ghep doi..."
adb shell am start -n "${PACKAGE}/${ACTIVITY}" 2>&1 | Out-Null
Wait-UI 2000
Capture-Screen "07_pairing_or_home"
adb shell input keyevent KEYCODE_BACK 2>&1 | Out-Null
Wait-UI 600

# 8. UI Hierarchy Dump
Write-Host "[8/8] Dump UI hierarchy..."
adb shell input tap 1080 1900 2>&1 | Out-Null
Wait-UI 1200
adb shell uiautomator dump /sdcard/view_dump.xml 2>&1 | Out-Null
adb pull /sdcard/view_dump.xml $DUMP_FILE 2>&1 | Out-Null
Write-Host "  [DUMP] view_dump.xml saved"

# Copy artifacts vao brain directory de phan tich
$ARTIFACTS_DIR = "C:\Users\LongLouis\.gemini\antigravity-ide\brain\f5473972-923c-480b-a054-36f3e6c1191a"
Write-Host "[+] Copy screenshots va dump vao artifacts..."
Get-ChildItem "$OUTPUT_DIR\*.png" -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item $_.FullName "$ARTIFACTS_DIR\$($_.Name)" -Force
}
if (Test-Path $DUMP_FILE) {
    Copy-Item $DUMP_FILE "$ARTIFACTS_DIR\view_dump.xml" -Force
}
Write-Host "  [OK] Artifacts copied to: $ARTIFACTS_DIR"

# Summary
$screenshots = Get-ChildItem "$OUTPUT_DIR\*.png" -ErrorAction SilentlyContinue | Measure-Object
Write-Host ""
Write-Host "========================================"
Write-Host "  AUDIT COMPLETE"
Write-Host "  Screenshots : $($screenshots.Count) files"
Write-Host "  Output dir  : $OUTPUT_DIR"
Write-Host "  Artifacts   : $ARTIFACTS_DIR"
Write-Host "========================================"
Write-Host ""
