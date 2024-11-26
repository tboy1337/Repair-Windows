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
        call bootrec /fixmbr >nul 2>&1
        if %errorlevel% neq 0 (
            echo Failed to fix the MBR.
        )
    )
)

:: cd /d :\\EFI\\Microsoft\\Boot\\ after assigning drive letter to system? or reserve? partition (ONLY FOR SYSTEM I THINK)

echo Scanning all disks for Windows installations...
call bootrec /scanos >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to scan all disks for Windows installations, trying again...
    call ren "%WINDOWS_DRIVE%\bootmgr" "bootmgrbackup" >nul 2>&1
    call bootrec /scanos >nul 2>&1
    if %errorlevel% neq 0 (
    echo Failed to scan all disks for Windows installations again.
    )
)

echo Rebuilding the BCD store...
call bootrec /rebuildbcd >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to rebuild the BCD store, trying again...
    call bcdedit /export "%WINDOWS_DRIVE%\BCDBackup" >nul 2>&1
    call attrib bcd -s -h -r >nul 2>&1
    call ren "%WINDOWS_DRIVE%\boot\bcd" "bcd.old" >nul 2>&1
    call bootrec /rebuildbcd >nul 2>&1
)

echo Writing a new boot sector on the system partition...
call bootrec /fixboot >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to write a new boot sector on the system partition.
    call bootsect /nt60 SYS
    :: NOW DO bootrec_framework method to assign drive letters if above is error (probably).
    :: On UEFI systems, the bootrec /fixboot command is less relevant because the boot process relies on the EFI System Partition (ESP) and bootrec doesn't directly manage UEFI bootloader files.
)

timeout /t 5 /nobreak

exit /b 0
