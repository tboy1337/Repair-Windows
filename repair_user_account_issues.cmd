@echo off
setlocal enabledelayedexpansion

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

echo ========================================
echo     User Account Issues Repair Script
echo ========================================
echo.

echo This script will automatically detect and fix user account issues.
echo.

echo Checking for disabled user accounts...
powershell -Command "Get-LocalUser | Where-Object { $_.Enabled -eq $false -and $_.Name -ne 'Guest' } | Enable-LocalUser" 2>nul

echo Checking for expired passwords...
net user | findstr /c:"password expires" >nul 2>&1
if !errorlevel! equ 0 (
    echo Password expiration issues found. Fixing...
    net accounts /maxpwage:unlimited >nul 2>&1
)

echo Checking user profile service...
sc query profsvc | findstr /c:"STOPPED" >nul 2>&1
if !errorlevel! equ 0 (
    echo User Profile service stopped. Starting service...
    net start profsvc >nul 2>&1
)

echo Checking for corrupted user profiles...
powershell -Command "Get-CimInstance -ClassName Win32_UserProfile | Where-Object { -not (Test-Path $_.LocalPath) } | Remove-CimInstance" 2>nul

echo Checking user account permissions...
powershell -Command "Get-LocalUser | Where-Object { $_.Name -ne 'Administrator' -and $_.Name -ne 'Guest' } | ForEach-Object { $userPath = \"$env:SystemDrive\Users\$($_.Name)\"; if (Test-Path $userPath) { icacls \"$userPath\" /reset /T /C >$null } }" 2>nul

echo Checking for missing user directories...
powershell -Command "Get-LocalUser | Where-Object { $_.Name -ne 'Administrator' -and $_.Name -ne 'Guest' } | ForEach-Object { $userPath = \"$env:SystemDrive\Users\$($_.Name)\"; if (-not (Test-Path $userPath)) { Write-Host \"Missing user directory for $($_.Name). Creating...\"; New-Item -ItemType Directory -Path $userPath -Force >$null; icacls \"$userPath\" /grant \"$($_.Name):(OI)(CI)F\" /T /C >$null } }" 2>nul

echo Checking user registry hives...
powershell -Command "Get-LocalUser | Where-Object { $_.Name -ne 'Administrator' -and $_.Name -ne 'Guest' } | ForEach-Object { $userPath = \"$env:SystemDrive\Users\$($_.Name)\"; $ntuser = Join-Path $userPath 'NTUSER.DAT'; if (-not (Test-Path $ntuser)) { Write-Host \"Missing NTUSER.DAT for $($_.Name). User profile may need recreation.\" } }" 2>nul

echo Checking for locked user accounts...
net user | findstr /c:"Account active" | findstr /c:"No" >nul 2>&1
if !errorlevel! equ 0 (
    echo Locked accounts found. Unlocking...
    powershell -Command "Get-LocalUser | Where-Object { $_.Enabled -eq $false -and $_.Name -ne 'Guest' } | Enable-LocalUser" 2>nul
)

echo Checking administrator group membership...
net localgroup administrators | findstr /c:"Administrator" >nul 2>&1
if !errorlevel! neq 0 (
    echo Administrator not in administrators group. Fixing...
    net localgroup administrators Administrator /add >nul 2>&1
)

echo Checking for missing default user profile...
if not exist "%SystemDrive%\Users\Default" (
    echo Default user profile missing. Creating...
    xcopy "%SystemDrive%\Users\Default.bak" "%SystemDrive%\Users\Default" /E /I /H /Y >nul 2>&1
)

echo Checking user environment variables...
powershell -Command "Get-LocalUser | Where-Object { $_.Name -ne 'Administrator' -and $_.Name -ne 'Guest' } | ForEach-Object { [Environment]::SetEnvironmentVariable('USERPROFILE', \"$env:SystemDrive\Users\$($_.Name)\", 'Process') }" 2>nul

echo Checking for orphaned user profiles...
powershell -Command "Get-CimInstance -ClassName Win32_UserProfile | Where-Object { -not (Get-LocalUser -Name (Split-Path $_.LocalPath -Leaf) -ErrorAction SilentlyContinue) } | Remove-CimInstance" 2>nul

echo Checking user SID consistency...
powershell -Command "Get-LocalUser | ForEach-Object { $userName = $_.Name; $userSID = $_.SID; $profile = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.SID -eq $userSID }; if (-not $profile) { Write-Host \"Profile missing for user $userName. Creating profile...\"; $null = New-Item -ItemType Directory -Path \"$env:SystemDrive\Users\$userName\" -Force; icacls \"$env:SystemDrive\Users\$userName\" /grant \"$userName:(OI)(CI)F\" /T /C >$null } }" 2>nul

echo User account repair completed.
echo.

timeout /t 10 /nobreak
endlocal
exit /b 0
