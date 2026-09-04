# scripts/verify_couple_rules.ps1
# Script tu dong kiem tra va bao chung chat luong logic nghiep vu cap doi

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [HERFLOW] BAO CHUNG CHAT LUONG: COUPLE BUSINESS RULES" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Chay flutter analyze
Write-Host "`n[1/3] Dang phan tich ma nguon voi Flutter Analyze..." -ForegroundColor Yellow
flutter analyze

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[FAIL] Flutter Analyze phat hien loi!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n[PASS] Flutter Analyze: 0 issues found!" -ForegroundColor Green
}

# 2. Chay flutter test
Write-Host "`n[2/3] Dang chay toan bo Unit va Widget Tests..." -ForegroundColor Yellow
flutter test

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[FAIL] Co bai kiem thu that bai!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n[PASS] Tat ca bai kiem thu da PASS 100%!" -ForegroundColor Green
}

# 3. Kiem tra thiet bi ADB
Write-Host "`n[3/3] Dang kiem tra thiet bi ADB..." -ForegroundColor Yellow
adb devices

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] HOAN THANH KIEM TRA BAO CHUNG CHAT LUONG THANH CONG!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
