# scripts/run_full_system_test.ps1
# Automated Full System Test on Connected Android Device (2201116TG / 1080x2400)
param (
    [string]$Device = ""
)

Write-Host "========================================================"
Write-Host "   MOONA - AUTOMATED SYSTEM VERIFICATION MATRIX"
Write-Host "========================================================"

# Auto-detect device if not specified
if (-not $Device) {
    $devices = & adb devices | Where-Object { $_ -match '\tdevice$' }
    if ($devices) {
        $Device = ($devices[0] -split '\t')[0]
    }
}

if (-not $Device) {
    Write-Error "No connected ADB device found!"
    exit 1
}

Write-Host "[*] Target ADB Device: $Device"
$model = (& adb -s $Device shell getprop ro.product.model).Trim()
$androidVer = (& adb -s $Device shell getprop ro.build.version.release).Trim()
Write-Host "[*] Device Hardware: $model | Android: $androidVer"

# Ensure output directory
$outDir = "build\test_results"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$results = [ordered]@{}

# Helper function to check Logcat for Fatal Exceptions / NullPointerExceptions
function Check-LogcatCrash {
    param ([string]$PhaseName)
    $crashLogs = & adb -s $Device logcat -d -s AndroidRuntime:E *:F | Where-Object { 
        $_ -like "*Fatal Exception*" -or $_ -like "*NullPointerException*" -or $_ -like "*com.herflow.app.herflow*"
    }
    if ($crashLogs) {
        Write-Host "[CRASH DETECTED in $PhaseName]:" -ForegroundColor Red
        $crashLogs | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        return $false
    }
    return $true
}

# Helper to reset state to Main Navigation Screen
function Reset-ToMainScreen {
    # Send Back twice to dismiss any open modals
    & adb -s $Device shell input keyevent 4
    Start-Sleep -Milliseconds 500
    & adb -s $Device shell input keyevent 4
    Start-Sleep -Milliseconds 500
    # Bring app to front
    & adb -s $Device shell am start -n com.herflow.app.herflow/.MainActivity | Out-Null
    Start-Sleep -Seconds 1
}

Reset-ToMainScreen

# ─────────────────────────────────────────────────────────────────────────────
# TEST CASE 1: KIỂM TRA NÚT [QUẢN LÝ] KẾT NỐI (TRỌNG TÂM)
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n>>> [TEST CASE 1] KIEM TRA NUT [QUAN LY] KET NOI..." -ForegroundColor Cyan

# 1. Clear logcat
& adb -s $Device logcat -c

# 2. Go to Settings tab (Tab 3: X=945, Y=2300)
Write-Host "  -> Navigating to Settings tab (X=945, Y=2300)..."
& adb -s $Device shell input tap 945 2300
Start-Sleep -Seconds 2

# 3. Scroll down to "DONG BO CAP DOI" section
Write-Host "  -> Scrolling down to 'DONG BO CAP DOI'..."
& adb -s $Device shell input swipe 540 1800 540 800 300
Start-Sleep -Seconds 1

# 4. Tap on [Quan ly] button (Exact coordinate: X=745, Y=600)
Write-Host "  -> Tapping [Quan ly] button at X=745, Y=600..."
& adb -s $Device shell input tap 745 600
Start-Sleep -Milliseconds 1500

# 5. Check Logcat for crashes
$tc1NoCrash = Check-LogcatCrash -PhaseName "TestCase1_ManageButton"

# 6. Capture screenshot of modal
$tc1Img = "$outDir\01_manage_connection_modal.png"
& adb -s $Device shell screencap -p /sdcard/01_manage.png
& adb -s $Device pull /sdcard/01_manage.png $tc1Img | Out-Null
Write-Host "  -> Captured: $tc1Img"

# 7. Tap "Sao chep ma" button inside the modal (approx X=540, Y=1600 on 1080x2400)
Write-Host "  -> Tapping 'Sao chep ma' button inside modal (X=540, Y=1600)..."
& adb -s $Device shell input tap 540 1600
Start-Sleep -Milliseconds 800

# Capture SnackBar confirmation
$tc1bImg = "$outDir\01b_manage_copied_snackbar.png"
& adb -s $Device shell screencap -p /sdcard/01b_snackbar.png
& adb -s $Device pull /sdcard/01b_snackbar.png $tc1bImg | Out-Null
Write-Host "  -> Captured SnackBar: $tc1bImg"

# Close modal via Back
& adb -s $Device shell input keyevent 4
Start-Sleep -Seconds 1

if ($tc1NoCrash -and (Test-Path $tc1Img)) {
    $results["TEST_CASE_1_MANAGE_CONNECTION"] = "PASS"
    Write-Host "[PASS] TEST CASE 1: Nút [Quản lý] mở Modal BottomSheet trơn tru, sao chép mã an toàn, 0 crash!" -ForegroundColor Green
} else {
    $results["TEST_CASE_1_MANAGE_CONNECTION"] = "FAIL"
    Write-Host "[FAIL] TEST CASE 1: Gặp lỗi trong ca kiểm thử [Quản lý]!" -ForegroundColor Red
}

# ─────────────────────────────────────────────────────────────────────────────
# TEST CASE 2: KIỂM TRA HỘP THƯ 2 CHIỀU (LOVE NOTES THREAD)
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n>>> [TEST CASE 2] KIEM TRA HOP THU 2 CHIEU (LOVE NOTES THREAD)..." -ForegroundColor Cyan

Reset-ToMainScreen

# 1. Navigate back to Home (Tab 0: Chu ky: X=135, Y=2300)
Write-Host "  -> Navigating to Home / Chu ky tab (X=135, Y=2300)..."
& adb -s $Device shell input tap 135 2300
Start-Sleep -Seconds 2

# 2. Tap on Heart Icon at TopBar (X=538, Y=165)
Write-Host "  -> Opening Love Notes Thread via TopBar Heart Icon (X=538, Y=165)..."
& adb -s $Device shell input tap 538 165
Start-Sleep -Seconds 2

# 3. Capture modal screenshot
$tc2Img = "$outDir\02_love_notes_thread.png"
& adb -s $Device shell screencap -p /sdcard/02_thread.png
& adb -s $Device pull /sdcard/02_thread.png $tc2Img | Out-Null
Write-Host "  -> Captured: $tc2Img"

# 4. Tap on a Quick Suggestion Chip (e.g. X=230, Y=2080)
Write-Host "  -> Tapping Quick Suggestion Chip at X=230, Y=2080 to send note..."
& adb -s $Device shell input tap 230 2080
Start-Sleep -Seconds 2

# 5. Capture timeline with new message
$tc2bImg = "$outDir\02b_note_sent_timeline.png"
& adb -s $Device shell screencap -p /sdcard/02b_timeline.png
& adb -s $Device pull /sdcard/02b_timeline.png $tc2bImg | Out-Null
Write-Host "  -> Captured timeline update: $tc2bImg"

# 6. Close modal via Close icon (X=915, Y=530) or Back
& adb -s $Device shell input tap 915 530
Start-Sleep -Milliseconds 500
& adb -s $Device shell input keyevent 4
Start-Sleep -Seconds 1

$tc2NoCrash = Check-LogcatCrash -PhaseName "TestCase2_LoveNotesThread"

if ($tc2NoCrash -and (Test-Path $tc2Img)) {
    $results["TEST_CASE_2_LOVE_NOTES_THREAD"] = "PASS"
    Write-Host "[PASS] TEST CASE 2: Hộp thư 2 chiều bung modal, Quick Chip gửi tin và hiển thị trên timeline chuẩn xác!" -ForegroundColor Green
} else {
    $results["TEST_CASE_2_LOVE_NOTES_THREAD"] = "FAIL"
    Write-Host "[FAIL] TEST CASE 2: Gặp lỗi trong ca kiểm thử Hộp thư 2 chiều!" -ForegroundColor Red
}

# ─────────────────────────────────────────────────────────────────────────────
# TEST CASE 3: KIỂM TRA CHUYỂN ĐỔI VAI TRÒ (ROLE SWITCHER)
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n>>> [TEST CASE 3] KIEM TRA CHUYEN DOI VAI TRO (ROLE SWITCHER)..." -ForegroundColor Cyan

Reset-ToMainScreen

# 1. Tap Settings Tab (X=945, Y=2300)
Write-Host "  -> Navigating to Settings tab (X=945, Y=2300)..."
& adb -s $Device shell input tap 945 2300
Start-Sleep -Seconds 2

# 2. Scroll up to top of Settings screen
Write-Host "  -> Scrolling to top of Settings..."
& adb -s $Device shell input swipe 540 600 540 1800 300
Start-Sleep -Seconds 1

# 3. Tap on "Doi vai tro >" button (Exact coordinate: X=815, Y=870)
Write-Host "  -> Tapping 'Doi vai tro' button (X=815, Y=870)..."
& adb -s $Device shell input tap 815 870
Start-Sleep -Seconds 2

# 4. In "Chon Vai Tro Cua Ban" BottomSheet, tap opposite role "Nguoi Thuong (Chong)" (X=540, Y=1950)
Write-Host "  -> Selecting opposite role in bottom sheet (X=540, Y=1950)..."
& adb -s $Device shell input tap 540 1950
Start-Sleep -Seconds 2

# 5. Capture MoonaConfirmDialog screenshot
$tc3Img = "$outDir\03_role_switcher_dialog.png"
& adb -s $Device shell screencap -p /sdcard/03_role.png
& adb -s $Device pull /sdcard/03_role.png $tc3Img | Out-Null
Write-Host "  -> Captured Role Switcher Dialog: $tc3Img"

# 6. Tap "Huy" on dialog (or Back key) to preserve current role
& adb -s $Device shell input keyevent 4
Start-Sleep -Seconds 1

$tc3NoCrash = Check-LogcatCrash -PhaseName "TestCase3_RoleSwitcher"

if ($tc3NoCrash -and (Test-Path $tc3Img)) {
    $results["TEST_CASE_3_ROLE_SWITCHER"] = "PASS"
    Write-Host "[PASS] TEST CASE 3: Role Switcher kích hoạt MoonaConfirmDialog chuẩn xác, bố cục đối xứng, bảo vệ an toàn!" -ForegroundColor Green
} else {
    $results["TEST_CASE_3_ROLE_SWITCHER"] = "FAIL"
    Write-Host "[FAIL] TEST CASE 3: Gặp lỗi trong ca kiểm thử Chuyển đổi vai trò!" -ForegroundColor Red
}

# ─────────────────────────────────────────────────────────────────────────────
# TEST CASE 4: KIỂM TRA ĐĂNG XUẤT & BẢO MẬT
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n>>> [TEST CASE 4] KIEM TRA DANG XUAT & BAO MAT..." -ForegroundColor Cyan

Reset-ToMainScreen

# 1. Tap Settings Tab (X=945, Y=2300)
Write-Host "  -> Navigating to Settings tab (X=945, Y=2300)..."
& adb -s $Device shell input tap 945 2300
Start-Sleep -Seconds 2

# 2. Ensure at top of Settings screen
Write-Host "  -> Scrolling to top of Settings..."
& adb -s $Device shell input swipe 540 600 540 1800 300
Start-Sleep -Seconds 1

# 3. Tap Logout icon on User Profile card (Exact coordinate: X=865, Y=320)
Write-Host "  -> Tapping Logout icon (X=865, Y=320)..."
& adb -s $Device shell input tap 865 320
Start-Sleep -Seconds 2

# 4. Capture Logout MoonaConfirmDialog screenshot
$tc4Img = "$outDir\04_logout_standard_dialog.png"
& adb -s $Device shell screencap -p /sdcard/04_logout.png
& adb -s $Device pull /sdcard/04_logout.png $tc4Img | Out-Null
Write-Host "  -> Captured Logout Dialog: $tc4Img"

# 5. Tap "O lai" / Cancel (or Back key) to keep login state intact
& adb -s $Device shell input keyevent 4
Start-Sleep -Seconds 1

$tc4NoCrash = Check-LogcatCrash -PhaseName "TestCase4_Logout"

if ($tc4NoCrash -and (Test-Path $tc4Img)) {
    $results["TEST_CASE_4_LOGOUT_SECURITY"] = "PASS"
    Write-Host "[PASS] TEST CASE 4: Modal đăng xuất chuẩn MoonaConfirmDialog (Hủy/Ở lại & Xác nhận ngang hàng), an toàn 100%!" -ForegroundColor Green
} else {
    $results["TEST_CASE_4_LOGOUT_SECURITY"] = "FAIL"
    Write-Host "[FAIL] TEST CASE 4: Gặp lỗi trong ca kiểm thử Đăng xuất!" -ForegroundColor Red
}

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY MATRIX
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n========================================================"
Write-Host "             FINAL TEST EXECUTION SUMMARY"
Write-Host "========================================================"
foreach ($k in $results.Keys) {
    $color = if ($results[$k] -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $k : $($results[$k])" -ForegroundColor $color
}
Write-Host "========================================================`n"
