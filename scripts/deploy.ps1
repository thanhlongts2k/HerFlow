# scripts/deploy.ps1
# ╔══════════════════════════════════════════════════════════════════╗
# ║   MOONA — Automated Build & Deploy Script (Windows PowerShell)   ║
# ║   Sử dụng: .\scripts\deploy.ps1 [-Mode debug|release]           ║
# ╚══════════════════════════════════════════════════════════════════╝

param(
    [ValidateSet("debug", "release")]
    [string]$Mode = "debug"
)

# ── TIỆN ÍCH HIỂN THỊ MÀU ─────────────────────────────────────────
function Write-Step   { param($msg) Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Write-OK     { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Warn   { param($msg) Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Fail   { param($msg) Write-Host "  ❌ $msg" -ForegroundColor Red }
function Write-Info   { param($msg) Write-Host "  ℹ️  $msg" -ForegroundColor Gray }
function Write-Header {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║   🌙 MOONA — Auto Build & Deploy              ║" -ForegroundColor Magenta
    Write-Host "║   Mode: $($Mode.ToUpper().PadRight(37))║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

$startTime = Get-Date
Write-Header

# ════════════════════════════════════════════════════════════════════
# BƯỚC 1: KIỂM TRA THIẾT BỊ ADB
# ════════════════════════════════════════════════════════════════════
Write-Step "Bước 1/5 — Kiểm tra thiết bị Android (ADB)"

# Kiểm tra adb có trong PATH không
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Fail "Không tìm thấy lệnh 'adb'. Hãy cài Android Platform Tools và thêm vào PATH."
    exit 1
}

$adbOutput   = adb devices 2>&1
$deviceLines = $adbOutput | Where-Object { $_ -match "\t(device|offline|unauthorized)$" }

if ($deviceLines.Count -eq 0) {
    Write-Fail "Không tìm thấy thiết bị nào kết nối qua ADB!"
    Write-Warn "Kiểm tra:"
    Write-Warn "  1. Bật USB Debugging trong Tùy chọn dành cho nhà phát triển"
    Write-Warn "  2. Kết nối cáp USB và xác nhận trên điện thoại"
    Write-Warn "  3. Chạy 'adb devices' để kiểm tra thủ công"
    exit 1
}

# Lấy thiết bị đầu tiên ở trạng thái "device" (bỏ qua offline/unauthorized)
$activeDeviceLine = $deviceLines | Where-Object { $_ -match "\tdevice$" } | Select-Object -First 1

if (-not $activeDeviceLine) {
    $badLine = $deviceLines | Select-Object -First 1
    if ($badLine -match "unauthorized") {
        Write-Fail "Thiết bị chưa được uỷ quyền! Vui lòng xác nhận kết nối debug trên màn hình điện thoại."
    } elseif ($badLine -match "offline") {
        Write-Fail "Thiết bị đang offline! Thử rút/cắm lại cáp USB."
    } else {
        Write-Fail "Thiết bị không ở trạng thái sẵn sàng: $badLine"
    }
    exit 1
}

$deviceId = ($activeDeviceLine -split "\t")[0].Trim()

if ($deviceLines.Count -gt 1) {
    Write-Warn "Phát hiện $($deviceLines.Count) thiết bị — tự chọn thiết bị đầu tiên."
}
Write-OK "Thiết bị sẵn sàng: $deviceId"

# Lấy thông tin thiết bị để hiển thị
$deviceModel = (adb -s $deviceId shell getprop ro.product.model 2>$null).Trim()
$androidVer  = (adb -s $deviceId shell getprop ro.build.version.release 2>$null).Trim()
if ($deviceModel) { Write-Info "  Model: $deviceModel  |  Android: $androidVer" }


# ════════════════════════════════════════════════════════════════════
# BƯỚC 2: KIỂM TRA TĨNH (FLUTTER ANALYZE)
# ════════════════════════════════════════════════════════════════════
Write-Step "Bước 2/5 — Kiểm tra tĩnh mã nguồn (flutter analyze)"

$analyzeResult = flutter analyze 2>&1
$analyzeExitCode = $LASTEXITCODE

# Lọc và hiển thị chỉ các dòng có lỗi/warning
$errorLines = $analyzeResult | Where-Object { $_ -match "^\s+(error|warning)" }
if ($errorLines) {
    $errorLines | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
}

if ($analyzeExitCode -ne 0) {
    Write-Fail "flutter analyze phát hiện lỗi! Hãy sửa trước khi build."
    Write-Warn "Chạy 'flutter analyze' để xem chi tiết đầy đủ."
    exit 1
}

Write-OK "Không có lỗi phân tích tĩnh — mã nguồn sạch ✨"


# ════════════════════════════════════════════════════════════════════
# BƯỚC 3: TIẾN HÀNH BUILD
# ════════════════════════════════════════════════════════════════════
Write-Step "Bước 3/5 — Build APK (Mode: $($Mode.ToUpper()))"

$buildStart = Get-Date

if ($Mode -eq "debug") {
    Write-Info "Đang chạy: flutter build apk --debug"
    flutter build apk --debug
} else {
    Write-Info "Đang chạy: flutter build apk --release --split-per-abi"
    Write-Info "  (Chia nhỏ APK theo kiến trúc CPU — tối ưu kích thước)"
    flutter build apk --release --split-per-abi
}

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Build thất bại! Xem lỗi ở trên."
    exit 1
}

$buildDuration = [math]::Round(((Get-Date) - $buildStart).TotalSeconds, 1)
Write-OK "Build hoàn thành trong ${buildDuration}s"


# ════════════════════════════════════════════════════════════════════
# BƯỚC 4: XÁC ĐỊNH ĐƯỜNG DẪN FILE APK
# ════════════════════════════════════════════════════════════════════
Write-Step "Bước 4/5 — Xác định file APK cần cài đặt"

$apkBase = "build\app\outputs\flutter-apk"
$apkPath  = $null

if ($Mode -eq "debug") {
    $candidate = Join-Path $apkBase "app-debug.apk"
    if (Test-Path $candidate) { $apkPath = $candidate }
} else {
    # Release: ưu tiên arm64-v8a, fallback sang armeabi-v7a, rồi x86_64, rồi fat APK
    $candidates = @(
        (Join-Path $apkBase "app-arm64-v8a-release.apk"),
        (Join-Path $apkBase "app-armeabi-v7a-release.apk"),
        (Join-Path $apkBase "app-x86_64-release.apk"),
        (Join-Path $apkBase "app-release.apk")
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $apkPath = $c
            break
        }
    }
}

if (-not $apkPath) {
    Write-Fail "Không tìm thấy file APK sau khi build tại: $apkBase"
    Write-Warn "Nội dung thư mục:"
    Get-ChildItem $apkBase -Filter "*.apk" | ForEach-Object { Write-Info "  $($_.Name)" }
    exit 1
}

$apkSizeMB = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
Write-OK "File APK: $(Split-Path $apkPath -Leaf)  ($apkSizeMB MB)"
Write-Info "  Đường dẫn: $apkPath"


# ════════════════════════════════════════════════════════════════════
# BƯỚC 5: CÀI ĐẶT VÀ KHỞI CHẠY
# ════════════════════════════════════════════════════════════════════
Write-Step "Bước 5/5 — Cài đặt & Khởi chạy app"

# 5a. Cài đặt
Write-Info "Đang cài đặt lên $deviceId..."
$installOutput = adb -s $deviceId install -r $apkPath 2>&1

if ($LASTEXITCODE -ne 0 -or ($installOutput -match "FAILED|Exception")) {
    Write-Fail "Cài đặt thất bại!"
    $installOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    exit 1
}
Write-OK "Cài đặt thành công!"

# 5b. Khởi chạy app
Write-Info "Đang khởi chạy Moona..."
$launchCmd = "com.herflow.app.herflow/.MainActivity"
adb -s $deviceId shell am start -n $launchCmd | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-OK "App đã khởi chạy!"
} else {
    Write-Warn "Không thể tự động mở app. Hãy mở thủ công trên thiết bị."
    Write-Warn "  (Có thể package name đã thay đổi — kiểm tra AndroidManifest.xml)"
}


# ════════════════════════════════════════════════════════════════════
# TỔNG KẾT
# ════════════════════════════════════════════════════════════════════
$totalSeconds = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
$totalMinutes = [math]::Floor($totalSeconds / 60)
$remainSec    = $totalSeconds % 60

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   🎉 DEPLOY HOÀN THÀNH!                       ║" -ForegroundColor Green
Write-Host "║                                              ║" -ForegroundColor Green
Write-Host "║   Mode    : $($Mode.ToUpper().PadRight(34))║" -ForegroundColor Green
Write-Host "║   APK     : $("$apkSizeMB MB".PadRight(34))║" -ForegroundColor Green
Write-Host "║   Thời gian: ${totalMinutes}m ${remainSec}s$(" " * (31 - "$totalMinutes m $remainSec s".Length))║" -ForegroundColor Green
Write-Host "║   Thiết bị: $($deviceId.PadRight(34))║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
