# scripts/deploy.ps1
# ╔══════════════════════════════════════════════════════════════════╗
# ║   MOONA -- Automated Build & Deploy Script (Windows PowerShell)  ║
# ║   Usage: .\scripts\deploy.ps1 [-Mode debug|release]             ║
# ║                               [-Target all|first|<deviceId>]    ║
# ╚══════════════════════════════════════════════════════════════════╝

param(
    [ValidateSet("debug", "release")]
    [string]$Mode = "debug",
    [string]$Target = "first",
    [string]$DeviceId = ""
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
    Write-Host "   Mode   : $($Mode.ToUpper())" -ForegroundColor Magenta
    Write-Host "   Target : $($Target.ToUpper())" -ForegroundColor Magenta
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
# STEP 1: CHECK ADB DEVICE(S)
# ═════════════════════════════════════════════════════════════════
Write-Step "Step 1/5 -- Check connected Android device(s) (ADB)"

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

$readyLines = $deviceLines | Where-Object { $_ -match "`tdevice$" }
if (-not $readyLines -or $readyLines.Count -eq 0) {
    Write-Fail "No ready devices found (devices might be offline or unauthorized)."
    exit 1
}

$targetDevices = @()
if ($DeviceId -ne "") {
    $targetDevices = @($DeviceId)
} elseif ($Target -eq "all") {
    $targetDevices = @($readyLines | ForEach-Object { ($_ -split "`t")[0].Trim() })
} elseif ($Target -ne "first") {
    $targetDevices = @($Target)
} else {
    $targetDevices = @(($readyLines[0] -split "`t")[0].Trim())
}

Write-OK "Target device(s) selected: $($targetDevices.Count) device(s)"
foreach ($dev in $targetDevices) {
    $rawM = adb -s $dev shell getprop ro.product.model 2>$null
    $rawV = adb -s $dev shell getprop ro.build.version.release 2>$null
    $m = if ($rawM) { $rawM.Trim() } else { "Device" }
    $v = if ($rawV) { $rawV.Trim() } else { "?" }
    Write-Info "  -> $dev ($m | Android $v)"
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

if ($Mode -eq "release") {
    # Check if primary target device ABI can be resolved
    $deviceAbi = (adb -s $targetDevices[0] shell getprop ro.product.cpu.abi 2>$null).Trim()
    Write-Info "Primary target device ABI: $deviceAbi"
    Write-Info "Running: flutter build apk --release --split-per-abi"
    $buildOutput = flutter build apk --release --split-per-abi 2>&1
} else {
    Write-Info "Running: flutter build apk --debug"
    $buildOutput = flutter build apk --debug 2>&1
}

$buildExitCode = $LASTEXITCODE

if ($buildExitCode -ne 0) {
    Write-Fail "Build failed! Output:"
    $buildOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    exit 1
}

$buildElapsed = [math]::Round(((Get-Date) - $buildStart).TotalSeconds, 1)
Write-OK "Build completed in ${buildElapsed}s"


# ═════════════════════════════════════════════════════════════════
# STEP 4: RESOLVE APK FILE PATH
# ═════════════════════════════════════════════════════════════════
Write-Step "Step 4/5 -- Resolve APK file path"

$apkPath = $null

if ($Mode -eq "release") {
    $apkDir = "build\app\outputs\flutter-apk"
    $abiMap = @{
        "arm64-v8a"   = "$apkDir\app-arm64-v8a-release.apk"
        "armeabi-v7a" = "$apkDir\app-armeabi-v7a-release.apk"
        "x86_64"      = "$apkDir\app-x86_64-release.apk"
    }

    if ($deviceAbi -and $abiMap.ContainsKey($deviceAbi) -and (Test-Path $abiMap[$deviceAbi])) {
        $apkPath = $abiMap[$deviceAbi]
        Write-Info "Selected ABI-specific APK for $deviceAbi"
    } else {
        $fallback = Get-ChildItem -Path $apkDir -Filter "*.apk" |
                    Where-Object { $_.Name -notmatch "debug" } |
                    Sort-Object Length |
                    Select-Object -First 1
        if ($fallback) {
            $apkPath = $fallback.FullName
            Write-Warn "Using fallback APK: $($fallback.Name)"
        }
    }
} else {
    $debugApk = "build\app\outputs\flutter-apk\app-debug.apk"
    if (Test-Path $debugApk) {
        $apkPath = $debugApk
    }
}

if (-not $apkPath -or -not (Test-Path $apkPath)) {
    Write-Fail "Cannot find built APK file!"
    exit 1
}

$apkFile   = Get-Item $apkPath
$apkSizeMB = [math]::Round($apkFile.Length / 1MB, 2)
$apkName   = $apkFile.Name
Write-OK "APK resolved: $apkName ($apkSizeMB MB)"
Write-Info "Path: $apkPath"


# ═════════════════════════════════════════════════════════════════
# STEP 5: INSTALL AND LAUNCH
# ═════════════════════════════════════════════════════════════════
Write-Step "Step 5/5 -- Install and launch on device(s)"

$packageActivity = "com.herflow.app.herflow/.MainActivity"
foreach ($dev in $targetDevices) {
    Write-Info "Installing on $dev ..."
    $installOutput = adb -s $dev install -r -d -t $apkPath 2>&1

    if ($LASTEXITCODE -ne 0 -or ($installOutput -match "FAILED|Exception")) {
        if ($installOutput -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE|INSTALL_FAILED_SHARED_USER_INCOMPATIBLE") {
            Write-Warn "Signature incompatibility detected on $dev. Re-installing cleanly..."
            adb -s $dev uninstall com.herflow.app.herflow | Out-Null
            $installOutput = adb -s $dev install -t $apkPath 2>&1
        }
    }

    if ($LASTEXITCODE -ne 0 -or ($installOutput -match "FAILED|Exception")) {
        Write-Fail "Installation failed on $dev!"
        $installOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    } else {
        Write-OK "Installation successful on $dev!"
        Write-Info "Launching Moona app on $dev..."
        adb -s $dev shell am start -n $packageActivity | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-OK "App launched on $dev!"
        } else {
            Write-Warn "Could not auto-launch app on $dev."
        }
    }
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
Write-Host "   Devices : $($targetDevices -join ', ')" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""
