# Stop LDPlayer holding the apk lock
Write-Host "Stopping LDPlayer (PID 5664)..."
Stop-Process -Name "dnplayer" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Remove the locked build folder
Write-Host "Cleaning locked build folder..."
Remove-Item -Path "D:\Sources\HerFlow\build\app\outputs\apk\debug" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "D:\Sources\HerFlow\build\app\outputs" -Recurse -Force -ErrorAction SilentlyContinue

# Relaunch LDPlayer cleanly without apk parameter
Write-Host "Restarting LDPlayer cleanly..."
Start-Process -FilePath "C:\LDPlayer\LDPlayer9\dnplayer.exe" -ArgumentList "index=0"

Write-Host "Waiting 10s for LDPlayer to initialize..."
Start-Sleep -Seconds 10
& adb devices -l
