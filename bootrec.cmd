@echo off
setlocal enabledelayedexpansion

for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control Panel\Windows" /v SystemRoot 2^>nul') do set "windir=%%b"
if "%windir%"=="" (
    echo Could not determine Windows installation location.
    timeout /t 5 /nobreak
    exit /b 1
)

set "WINDOWS_DRIVE=%windir:~0,2%"
echo Found Windows installation on drive: %WINDOWS_DRIVE%

cd /d "%WINDOWS_DRIVE%\Windows\System32\Boot" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %WINDOWS_DRIVE%\Windows\System32\Boot
)

for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo %WINDOWS_DRIVE%^|find "File System Name"') do (
    echo %%A | findstr /i /r "^FAT" >nul
    if not errorlevel 1 (
        echo The %WINDOWS_DRIVE% drive is FAT-based, repairing the MBR...
        bootrec /fixmbr >nul 2>&1
        if %errorlevel% neq 0 (
            echo Failed to fix the MBR.
        )
    )
)

echo Scanning all disks for Windows installations...
bootrec /scanos >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to scan all disks for Windows installations, trying again...
    ren "%WINDOWS_DRIVE%\bootmgr" "bootmgrbackup" >nul 2>&1
    bootrec /scanos >nul 2>&1
    if %errorlevel% neq 0 (
    echo Failed to scan all disks for Windows installations again.
    )
)

echo Rebuilding the BCD store...
bootrec /rebuildbcd >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to rebuild the BCD store, trying again...
    bcdedit /export "%WINDOWS_DRIVE%\BCDBackup" >nul 2>&1
    attrib bcd -s -h -r >nul 2>&1
    ren "%WINDOWS_DRIVE%\boot\bcd" "bcd.old" >nul 2>&1
    bootrec /rebuildbcd >nul 2>&1
    :: NOW DO repair_EFI.cmd method to assign drive letters and repair if above is error.
    :: NOW DO delete_remake_EFI.cmd method if the above is error.
)

echo Writing a new boot sector on the system partition...
bootrec /fixboot >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to write a new boot sector on the system partition.
    bootsect /nt60 SYS
    bootrec /fixboot
    :: NOW DO repair_EFI.cmd method to assign drive letters and repair if above is error.
    :: NOW DO delete_remake_EFI.cmd method if the above is error.
)

cd /d "X:\Windows\System32"
