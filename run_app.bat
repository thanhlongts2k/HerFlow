@echo off
:: ╔═══════════════════════════════════════════════╗
:: ║  MOONA — Quick Launch: Build Debug & Deploy    ║
:: ║  Nhấp đúp để build debug và cài lên thiết bị  ║
:: ╚═══════════════════════════════════════════════╝
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\deploy.ps1" -Mode debug
pause
