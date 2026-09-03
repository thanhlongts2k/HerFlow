# scripts/deploy.ps1
# ╔══════════════════════════════════════════════════════════════════╗
# ║   MOONA -- Automated Build & Deploy Script (Windows PowerShell)  ║
# ║   Usage: .\scripts\deploy.ps1 [-Mode debug|release]             ║
# ╚══════════════════════════════════════════════════════════════════╝

param(
    [ValidateSet("debug", "release")]
    [string]$Mode = "debug"
)

# ── COLOR HELPERS ──────────────────────────────────────────────────
function Write-Step { param($msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "  [OK]  $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  [!!]  $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "  [XX]  $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "        $msg" -ForegroundColor Gray }

function Write-Banner {
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Magenta
    Write-Host "   MOONA -- Auto Build and Deploy Script" -ForegroundColor Magenta
    Write-Host "   Mode : $($Mode.ToUpper())" -ForegroundColor Magenta
    Write-Host "=================================================" -ForegroundColor Magenta
    Write-Host ""
}

$startTime = Get-Date
Write-Banner


# ═════════════════════════════════════════════════════════════════
# STEP 0: PRE-FLIGHT CHECK -- google-services.json
# ═════════════════════════════════════════════════════════════════
$googleServicesPath = "android\app\google-services.json"
$googleServicesExample = "android\app\google-services.json.example"

if (-not (Test-Path $googleServicesPath)) {
    Write-Warn "android\app\google-services.json not found!"

    if (Test-Path $googleServicesExample) {
        Write-Info "Auto-copying google-services.json.example as placeholder for local build..."
        Copy-Item $googleServicesExample $googleServicesPath
        Write-OK "Placeholder google-services.json created (Firebase features will use demo config)."
        Write-Warn "For full Firebase functionality, replace with your real google-services.json"
        Write-Info "  from: https://console.firebase.google.com/ -> Project Settings -> Android App"
    } else {
        Write-Fail "google-services.json.example also missing! Cannot proceed."
        Write-Info "  Download google-services.json from Firebase Console:"
        Write-Info "  https://console.firebase.google.com/ -> Project Settings -> Android App"
        exit 1
    }
}


# ═════════════════════════════════════════════════════════════════
# STEP 1: CHECK ADB DEVICE
# ═════════════════════════════════════════════════════════════════
Write-Step "Step 1/5 -- Check connected Android device (ADB)"

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Fail "Command 'adb' not found. Install Android Platform Tools and add to PATH."
    exit 1
}

$adbOutput   = adb devices 2>&1
$deviceLines = $adbOutput | Where-Object { $_ -match "`t(device|offline|unauthorized)$" }

if ($deviceLines.Count -eq 0) {
    Write-Fail "No Android device connected via ADB!"
    Write-Warn "Checklist:"
    Write-Warn "  1. Enable USB Debugging in Developer Options"
    Write-Warn "  2. Connect USB cable and confirm on phone screen"
    Write-Warn "  3. Run 'adb devices' manually to debug"
    exit 1
}

$activeDeviceLine = $deviceLines | Where-Object { $_ -match "`tdevice$" } | Select-Object -First 1

if (-not $activeDeviceLine) {
    $badLine = $deviceLines | Select-Object -First 1
    if ($badLine -match "unauthorized") {
        Write-Fail "Device not authorized! Please confirm the debug connection on your phone screen."
    } elseif ($badLine -match "offline") {
        Write-Fail "Device is offline! Try unplugging and re-plugging the USB cable."
    } else {
        Write-Fail "Device not ready: $badLine"
    }
    exit 1
}

$deviceId = ($activeDeviceLine -split "`t")[0].Trim()

if ($deviceLines.Count -gt 1) {
    Write-Warn "Found $($deviceLines.Count) devices -- auto-selecting first active device."
}

$deviceModel = (adb -s $deviceId shell getprop ro.product.model 2>$null).Trim()
$androidVer  = (adb -s $deviceId shell getprop ro.build.version.release 2>$null).Trim()
Write-OK "Device ready: $deviceId"
if ($deviceModel) {
    Write-Info "Model: $deviceModel  |  Android: $androidVer"
}


# ═════════════════════════════════════════════════════════════════
# STEP 2: STATIC ANALYSIS (FLUTTER ANALYZE)
# ═════════════════════════════════════════════════════════════════
Write-Step "Step 2/5 -- Static analysis (flutter analyze)"

$analyzeResult   = flutter analyze 2>&1
$analyzeExitCode = $LASTEXITCODE

$errorLines = $analyzeResult | Where-Object { $_ -match "^\s+(error|warning)" }
if ($errorLines) {
    $errorLines | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
}

if ($analyzeExitCode -ne 0) {
    Write-Fail "flutter analyze found errors! Fix them before building."
    exit 1
}

Write-OK "No static analysis issues found -- source code is clean."


# ═════════════════════════════════════════════════════════════════
# STEP 3: BUILD APK
# ═════════════════════════════════════════════════════════════════
Write-Step "Step 3/5 -- Build APK (Mode: $($Mode.ToUpper()))"

$buildStart = Get-Date

if ($Mode -eq "debug") {
    Write-Info "Running: flutter build apk --debug"
    flutter build apk --debug
} else {
    Write-Info "Running: flutter build apk --release --split-per-abi"
    Write-Info "(Split APK by CPU architecture -- optimized file size)"
    flutter build apk --release --split-per-abi
}

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Build failed! See errors above."
    exit 1
}

$buildSec = [math]::Round(((Get-Date) - $buildStart).TotalSeconds, 1)
Write-OK "Build completed in ${buildSec}s"


# ═════════════════════════════════════════════════════════════════
# STEP 4: RESOLVE APK PATH
# ═════════════════════════════════════════════════════════════════
Write-Step "Step 4/5 -- Resolve APK file path"

$apkBase = "build\app\outputs\flutter-apk"
$apkPath = $null

if ($Mode -eq "debug") {
    $candidate = Join-Path $apkBase "app-debug.apk"
    if (Test-Path $candidate) { $apkPath = $candidate }
} else {
    # Release: prefer arm64-v8a, then armeabi-v7a, then x86_64, then fat APK
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
    Write-Fail "APK file not found after build in: $apkBase"
    Write-Warn "Directory contents:"
    Get-ChildItem $apkBase -Filter "*.apk" -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Info "  $($_.Name)" }
    exit 1
}

$apkSizeMB = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
$apkName   = Split-Path $apkPath -Leaf
Write-OK "APK resolved: $apkName ($apkSizeMB MB)"
Write-Info "Path: $apkPath"


# ═════════════════════════════════════════════════════════════════
# STEP 5: INSTALL AND LAUNCH
# ═════════════════════════════════════════════════════════════════
Write-Step "Step 5/5 -- Install and launch on device"

# 5a. Install
Write-Info "Installing on $deviceId ..."
$installOutput = adb -s $deviceId install -r -d -t $apkPath 2>&1

if ($LASTEXITCODE -ne 0 -or ($installOutput -match "FAILED|Exception")) {
    if ($installOutput -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE|INSTALL_FAILED_SHARED_USER_INCOMPATIBLE") {
        Write-Warn "Signature incompatibility detected. Re-installing cleanly..."
        adb -s $deviceId uninstall com.herflow.app.herflow | Out-Null
        $installOutput = adb -s $deviceId install -t $apkPath 2>&1
    }
}

if ($LASTEXITCODE -ne 0 -or ($installOutput -match "FAILED|Exception")) {
    Write-Fail "Installation failed!"
    $installOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    exit 1
}
Write-OK "Installation successful!"

# 5b. Launch app
Write-Info "Launching Moona app..."
$packageActivity = "com.herflow.app.herflow/.MainActivity"
adb -s $deviceId shell am start -n $packageActivity | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-OK "App launched on device!"
} else {
    Write-Warn "Could not auto-launch app. Open it manually on the device."
    Write-Warn "(Check applicationId in android/app/build.gradle.kts if this keeps failing)"
}


# ═════════════════════════════════════════════════════════════════
# SUMMARY
# ═════════════════════════════════════════════════════════════════
$totalSec = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
$mins     = [math]::Floor($totalSec / 60)
$secs     = [math]::Round($totalSec % 60, 1)

Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "   DEPLOY COMPLETE!" -ForegroundColor Green
Write-Host "" -ForegroundColor Green
Write-Host "   Mode    : $($Mode.ToUpper())" -ForegroundColor Green
Write-Host "   APK     : $apkName" -ForegroundColor Green
Write-Host "   Size    : $apkSizeMB MB" -ForegroundColor Green
Write-Host "   Time    : ${mins}m ${secs}s" -ForegroundColor Green
Write-Host "   Device  : $deviceId" -ForegroundColor Green
if ($deviceModel) {
    Write-Host "   Model   : $deviceModel (Android $androidVer)" -ForegroundColor Green
}
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""
