@echo off
chcp 65001 >nul
echo [1/2] Running flutter analyze...
call flutter analyze
if %errorlevel% neq 0 (
    echo [ERROR] flutter analyze failed!
    exit /b %errorlevel%
)

echo [2/2] Running flutter test...
call flutter test
if %errorlevel% neq 0 (
    echo [ERROR] flutter test failed!
    exit /b %errorlevel%
)

echo [SUCCESS] Static code analysis and unit tests passed 100%!
exit /b 0
