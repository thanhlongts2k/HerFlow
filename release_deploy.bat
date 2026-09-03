@echo off
:: ╔══════════════════════════════════════════════════╗
:: ║  MOONA — Quick Launch: Build Release & Deploy    ║
:: ║  Build APK tối ưu R8 + split-per-abi, cài thiết bị ║
:: ╚══════════════════════════════════════════════════╝
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\deploy.ps1" -Mode release
pause
