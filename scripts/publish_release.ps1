$tempScripts = @(
    "scripts\check_build_dir.bat",
    "scripts\check_current_screen.ps1",
    "scripts\check_git_status.ps1",
    "scripts\check_lock.ps1",
    "scripts\check_settings_coords.ps1",
    "scripts\check_tools.bat",
    "scripts\copy_test_artifacts.ps1",
    "scripts\diagnose_device.ps1",
    "scripts\dismiss_and_check_logcat.ps1",
    "scripts\execute_logout.ps1",
    "scripts\find_cwd.ps1",
    "scripts\find_locking_process.ps1",
    "scripts\fix_google_fonts.bat",
    "scripts\get_devices.bat",
    "scripts\inspect_couple_sync_card.ps1",
    "scripts\inspect_new_account_settings.ps1",
    "scripts\select_google_account.ps1",
    "scripts\tap_google_sign_in.ps1",
    "scripts\tap_logout.ps1",
    "scripts\tap_role_card.ps1",
    "scripts\test_adb_devices.bat",
    "scripts\test_clean.ps1",
    "scripts\test_logout_flow.ps1",
    "scripts\test_nav_settings.ps1",
    "scripts\test_pairing_screen.ps1",
    "scripts\test_role_switch_flow.ps1",
    "scripts\test_role_switch_to_wife.ps1",
    "scripts\test_scroll_couple_sync.ps1",
    "scripts\test_wife_home_tab.ps1",
    "scripts\test_wife_love_notes.ps1",
    "scripts\unlock_and_test.ps1"
)

Write-Host "--- 1. Cleaning up temporary debug scripts ---"
foreach ($f in $tempScripts) {
    if (Test-Path $f) {
        Remove-Item -Path $f -Force
        Write-Host "Removed temporary script: $f"
    }
}

Write-Host "--- 2. Staging all changes (git add .) ---"
& git add .

Write-Host "--- 3. Creating Commit ---"
$commitMsg = "fix(sync): resolve connection management crash, refine google sign-out and verify device test flow"
& git commit -m "$commitMsg"

Write-Host "--- 4. Pushing to remote (git push origin HEAD) ---"
& git push origin HEAD

Write-Host "--- 5. Publishing Summary ---"
$commitSha = & git rev-parse HEAD
$branch = & git rev-parse --abbrev-ref HEAD
Write-Host "COMMIT_SHA: $commitSha"
Write-Host "BRANCH: $branch"
& git log -1 --stat
