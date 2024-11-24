@echo off
setlocal enabledelayedexpansion

cd /d "C:\Windows\System32\Boot" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to C: drive.
)

for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo C:^|find "File System Name"') do (
    echo %%A | findstr /i /r "^FAT" >nul
    if not errorlevel 1 (
        echo The C: drive is FAT-based, repairing the MBR...
        call bootrec /fixmbr >nul 2>&1
    )
)

:: cd /d :\\EFI\\Microsoft\\Boot\\ after assigning drive letter to system? or reserve? partition (ONLY FOR SYSTEM I THINK)

echo Writing a new boot sector on the system partition...
call bootrec /fixboot >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to write a new boot sector on the system partition.
)

echo Scanning all disks for Windows installations...
call bootrec /scanos >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to scan all disks for Windows installations, trying again...
    call ren "C:\bootmgr" "bootmgrbackup" >nul 2>&1
    call bootrec /rebuildbcd >nul 2>&1
    call bootrec /scanos >nul 2>&1
    call bootrec /fixboot >nul 2>&1
)

echo Rebuilding the BCD store...
call bootrec /rebuildbcd >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to rebuild the BCD store, trying again...
    call bcdedit /export "C:\BCDBackup" >nul 2>&1
    call attrib bcd -s -h -r >nul 2>&1
    call ren "c:\boot\bcd" "bcd.old" >nul 2>&1
    call bootrec /rebuildbcd >nul 2>&1
    call bootrec /scanos >nul 2>&1
    call bootrec /fixboot >nul 2>&1
)

timeout /t 5 /nobreak

exit /b 0
