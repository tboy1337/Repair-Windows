@echo off

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 10 /nobreak
    exit /b 1
)

echo Repairing System Volumes...
powershell -NoProfile -Command "$ProgressPreference = 'SilentlyContinue'; $failed = 0; Get-Volume | Where-Object { $_.DriveLetter -or $_.FileSystemLabel } | ForEach-Object { try { if ($_.DriveLetter) { Repair-Volume -DriveLetter $_.DriveLetter -OfflineScanAndFix -ErrorAction Stop } else { Repair-Volume -FileSystemLabel $_.FileSystemLabel -OfflineScanAndFix -ErrorAction Stop } } catch { $failed++ } }; exit $failed"
if %errorlevel% neq 0 (
    echo One or more volume repairs failed.  Error code: %errorlevel%
    timeout /t 10 /nobreak
    exit /b 1
)

timeout /t 10 /nobreak
exit /b 0
