@echo off
setlocal enabledelayedexpansion

echo Windows Recovery Environment Repair Script
echo =====================================
echo Version 2.0
echo.

:: Check if running in Windows RE
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE" >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run in Windows Recovery Environment.
    echo Please boot into Windows RE and try again.
    timeout /t 10 /nobreak
    exit /b 1
)

:: Find Windows installation using improved detection
set "WINDOWS_DRIVE="
set "windir="
echo Detecting Windows installation...
for %%d in (A B C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
    if "%%d" neq "X" if exist "%%d:\Windows\System32\config\SYSTEM" (
        set "WINDOWS_DRIVE=%%d:"
        set "windir=%%d:\Windows"
        echo Found Windows installation on %%d:
        goto found_windows
    )
)

:found_windows
if not defined WINDOWS_DRIVE (
    echo Could not find Windows installation.
    echo Please ensure Windows is installed and accessible.
    timeout /t 10 /nobreak
    exit /b 1
)

:: Detect system architecture and boot mode
call :detect_system_info

:menu
cls
echo =====================================
echo Windows installation: %WINDOWS_DRIVE%
echo Boot mode: %BOOT_MODE%
echo System type: %SYSTEM_ARCH%
echo =====================================
echo Choose repair operations to perform:
echo 1) Run CHKDSK Disk Repair
echo 2) Run SFC and DISM Health Check and Repair
echo 3) Run Startup Repair
echo 4) Run Memory Diagnostic
echo 5) Run ALL Repairs (Recommended)
echo 6) Advanced Boot Repair
echo 7) Exit
echo.
set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto chkdskscan
if "%choice%"=="2" goto sfcdism
if "%choice%"=="3" goto startup
if "%choice%"=="4" goto memory
if "%choice%"=="5" goto all
if "%choice%"=="6" goto advanced_boot
if "%choice%"=="7" goto end

echo Invalid choice. Please try again.
timeout /t 2 /nobreak
goto menu

:all
echo Running comprehensive repair sequence...
echo This may take 30-60 minutes depending on system size.
echo.
goto chkdskscan

:chkdskscan
echo.
echo ===== DISK REPAIR =====
echo Running CHKDSK on %WINDOWS_DRIVE%...
echo This may take a while...

:: Get file system type
for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo %WINDOWS_DRIVE%^|find "File System Name"') do (
    set "FS_TYPE=%%A"
)

echo File system: %FS_TYPE%
echo %%FS_TYPE%% | findstr /i /r "^FAT" >nul
if %errorlevel% neq 1 (
    echo Repairing FAT file system...
    chkdsk "%WINDOWS_DRIVE%" /r /x >nul 2>&1
    if %errorlevel% neq 0 echo Warning: CHKDSK reported errors.
) else (
    echo Repairing NTFS file system...
    chkdsk "%WINDOWS_DRIVE%" /r /x >nul 2>&1
    if %errorlevel% neq 0 echo Warning: CHKDSK reported errors.
    
    echo Cleaning up metadata and unallocated space...
    chkdsk "%WINDOWS_DRIVE%" /sdcleanup >nul 2>&1
)

echo Disk repair completed.
if "%choice%"=="5" goto sfcdism
goto menu

:sfcdism
echo.
echo ===== SYSTEM FILE REPAIR =====
echo Running SFC and DISM health check and repair...
echo This may take 20-40 minutes...

set "HAS_CORRUPTION=0"

:: Use Windows RE RAM drive (X:) for temp files
set "TEMP=X:"
set "TEMP_FILE_1=%TEMP%\dism_checkhealth_%RANDOM%_%RANDOM%.txt"
set "TEMP_FILE_2=%TEMP%\dism_scanhealth_%RANDOM%_%RANDOM%.txt"

echo.
echo Checking for corruption flags in the Windows image...
dism /image:%WINDOWS_DRIVE%\ /cleanup-image /checkhealth > "%TEMP_FILE_1%" 2>&1
set "DISM_ERROR=%errorlevel%"
if !DISM_ERROR! neq 0 (
    echo Failed to execute DISM checkhealth command. Error code: !DISM_ERROR!
    echo This may indicate access issues or missing files.
) else (
    findstr /c:"No component store corruption detected" "%TEMP_FILE_1%" >nul
    set "FIND_ERROR=%errorlevel%"
    if !FIND_ERROR! neq 0 (
        set HAS_CORRUPTION=1
        echo Corruption flags detected in Windows image.
    ) else (
        echo No corruption flags found in Windows image.
    )
)

echo Checking for corruption in the Windows image...
dism /image:%WINDOWS_DRIVE%\ /cleanup-image /scanhealth > "%TEMP_FILE_2%" 2>&1
set "DISM_ERROR=%errorlevel%"
if !DISM_ERROR! neq 0 (
    echo Failed to execute DISM scanhealth command. Error code: !DISM_ERROR!
    echo This may indicate access issues or missing files.
) else (
    findstr /c:"No component store corruption detected" "%TEMP_FILE_2%" >nul
    set "FIND_ERROR=%errorlevel%"
    if !FIND_ERROR! neq 0 (
        set HAS_CORRUPTION=1
        echo Corruption detected in Windows image.
    ) else (
        echo No corruption found in Windows image.
    )
)

del "%TEMP_FILE_1%" >nul 2>&1
del "%TEMP_FILE_2%" >nul 2>&1

if !HAS_CORRUPTION! equ 1 (
    echo Corruption detected, restoring health of the Windows image...
    dism /image:%WINDOWS_DRIVE%\ /cleanup-image /restorehealth >nul 2>&1
    if !errorlevel! neq 0 (
        echo Failed to restore the health of the Windows image. Error code: !errorlevel!
    ) else (
        echo DISM repair completed successfully.
    )
) else (
    echo Windows image is healthy.
)

echo.
echo Checking integrity of protected system files...
sfc /scannow /offbootdir=%WINDOWS_DRIVE%\ /offwindir=%windir% >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check integrity of all protected system files. Error code: %errorlevel%
    echo This may indicate access issues or missing files.
)

echo.
echo Cleaning up component store...
dism /image:%WINDOWS_DRIVE%\ /cleanup-image /analyzecomponentstore >nul 2>&1
dism /image:%WINDOWS_DRIVE%\ /cleanup-image /startcomponentcleanup /resetbase >nul 2>&1
dism /image:%WINDOWS_DRIVE%\ /cleanup-mountpoints >nul 2>&1

echo System file repair completed.
if "%choice%"=="5" goto startup
goto menu

:startup
echo.
echo ===== STARTUP REPAIR =====
echo Running comprehensive startup repair...

call :run_bootrec

echo Startup repair completed.
if "%choice%"=="5" goto memory
goto menu

:memory
echo.
echo ===== MEMORY DIAGNOSTIC =====
echo Scheduling memory diagnostic for next boot...

call :schedule_memdiag
if %errorlevel% neq 0 (
    echo Failed to schedule memory diagnostic.
    echo This may be due to BCD corruption or access issues.
    echo You can manually run memory test from Windows RE Advanced Options.
) else (
    echo Memory diagnostic scheduled successfully.
    echo System will test RAM on next boot before loading Windows.
    echo Test results will be available in Event Viewer after boot.
)

if "%choice%"=="5" goto end
goto menu

:advanced_boot
echo.
echo ===== ADVANCED BOOT REPAIR =====
echo This will perform aggressive boot repair operations.
echo WARNING: This may modify boot partitions!
echo.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

call :advanced_boot_repair
goto menu

:: ========================= SYSTEM DETECTION =========================
:detect_system_info
set "BOOT_MODE=Unknown"
set "SYSTEM_ARCH=Unknown"

:: Detect boot mode (UEFI vs Legacy)
if exist "%WINDOWS_DRIVE%\EFI" (
    set "BOOT_MODE=UEFI"
) else (
    set "BOOT_MODE=Legacy BIOS"
)

:: Detect system architecture
if exist "%windir%\SysWOW64" (
    set "SYSTEM_ARCH=64-bit"
) else (
    set "SYSTEM_ARCH=32-bit"
)

exit /b 0

:: ========================= MEMORY DIAGNOSTIC FUNCTION =========================
:schedule_memdiag
set "BCD_PATH="
set "NEED_CLEANUP=0"

:: Determine BCD location based on boot mode
if "%BOOT_MODE%"=="UEFI" (
    call :find_efi_partition
    if %errorlevel% neq 0 (
        echo Error: Could not locate EFI system partition.
        exit /b 1
    )
    set "BCD_PATH=%EFI_DRIVE%\EFI\Microsoft\Boot\BCD"
    set "NEED_CLEANUP=1"
) else (
    set "BCD_PATH=%WINDOWS_DRIVE%\Boot\BCD"
)

:: Verify BCD exists
if not exist "%BCD_PATH%" (
    echo Error: Boot configuration data not found at %BCD_PATH%
    if %NEED_CLEANUP%==1 call :cleanup_efi_drive
    exit /b 1
)

:: Verify memdiag entry exists (it should be predefined in Windows)
bcdedit /store "%BCD_PATH%" /enum {memdiag} >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Memory diagnostic entry not found in BCD.
    echo This may indicate BCD corruption or missing Windows components.
    if %NEED_CLEANUP%==1 call :cleanup_efi_drive
    exit /b 1
)

:: Set boot sequence to run memory diagnostic once
bcdedit /store "%BCD_PATH%" /bootsequence {memdiag} >nul 2>&1
set "CMD_ERROR=%errorlevel%"

:: Cleanup EFI drive letter if needed
if %NEED_CLEANUP%==1 call :cleanup_efi_drive

:: Return result
if %CMD_ERROR% neq 0 (
    echo Failed to set boot sequence for memory diagnostic.
    exit /b 1
)

exit /b 0

:: ========================= BOOT REPAIR FUNCTIONS =========================
:run_bootrec
echo Scanning for Windows installations...
bootrec /scanos >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to scan for Windows installations.
)

echo.
echo Attempting to rebuild BCD store...
bootrec /rebuildbcd >nul 2>&1
if %errorlevel% neq 0 (
    echo BCD rebuild failed. Trying advanced repair...
    call :repair_bcd_advanced
)

echo.
echo Fixing boot sector...
if "%BOOT_MODE%"=="UEFI" (
    echo UEFI system detected - repairing EFI boot...
    call :repair_efi_boot
) else (
    echo Legacy BIOS system - repairing MBR...
    bootrec /fixmbr >nul 2>&1
    bootrec /fixboot >nul 2>&1
    if %errorlevel% neq 0 (
        echo Boot sector repair failed. Trying alternative method...
        bootsect /nt60 %WINDOWS_DRIVE% /mbr /force >nul 2>&1
    )
)

exit /b 0

:repair_bcd_advanced
echo Backing up current BCD...
if exist "%WINDOWS_DRIVE%\Boot\BCD" (
    copy "%WINDOWS_DRIVE%\Boot\BCD" "%WINDOWS_DRIVE%\Boot\BCD.backup" >nul 2>&1
)

echo Creating new BCD store...
bcdedit /createstore "%WINDOWS_DRIVE%\Boot\BCD.new" >nul 2>&1
bcdedit /store "%WINDOWS_DRIVE%\Boot\BCD.new" /create {bootmgr} >nul 2>&1
bcdedit /store "%WINDOWS_DRIVE%\Boot\BCD.new" /set {bootmgr} device boot >nul 2>&1
bcdedit /store "%WINDOWS_DRIVE%\Boot\BCD.new" /set {bootmgr} path \bootmgr >nul 2>&1

:: Try rebuilding again
bootrec /rebuildbcd >nul 2>&1
exit /b %errorlevel%

:repair_efi_boot
echo Locating EFI system partition...
call :find_efi_partition
if %errorlevel% neq 0 (
    echo EFI partition not found or corrupted. Attempting recreation...
    call :recreate_efi_partition
    exit /b %errorlevel%
)

echo Repairing EFI boot files...
call :repair_efi_files
exit /b %errorlevel%

:find_efi_partition
:: Use Windows RE RAM drive (X:) for temp files
set "TEMP=X:"
set "tmpfile=%TEMP%\diskpart_%RANDOM%_%RANDOM%.txt"
set "EFI_DISK="
set "EFI_PARTITION="
set "EFI_DRIVE=S:"

:: List all disks and find EFI partition
echo list disk > "%tmpfile%"
for /f "skip=6 tokens=2" %%d in ('diskpart /s "%tmpfile%"') do (
    echo select disk %%d > "%tmpfile%"
    echo list partition >> "%tmpfile%"
    
    for /f "tokens=1,2,3,4* delims= " %%a in ('diskpart /s "%tmpfile%" ^| findstr /i "System"') do (
        if "%%e"=="System" (
            set "EFI_DISK=%%d"
            set "EFI_PARTITION=%%b"
            goto efi_found
        )
    )
)

:efi_found
if not defined EFI_PARTITION (
    if exist "%tmpfile%" del "%tmpfile%"
    exit /b 1
)

echo Found EFI partition: Disk %EFI_DISK%, Partition %EFI_PARTITION%

:: Assign drive letter temporarily
echo select disk %EFI_DISK% > "%tmpfile%"
echo select partition %EFI_PARTITION% >> "%tmpfile%"
echo assign letter=%EFI_DRIVE:~0,1% >> "%tmpfile%"
diskpart /s "%tmpfile%" >nul

if exist "%tmpfile%" del "%tmpfile%"
exit /b 0

:repair_efi_files
echo Checking EFI partition file system...
chkdsk "%EFI_DRIVE%" /r /x >nul 2>&1
if %errorlevel% neq 0 (
    echo EFI partition has file system errors.
)

echo Rebuilding EFI boot files...
bcdboot "%windir%" /s "%EFI_DRIVE%" /f UEFI >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to rebuild EFI boot files.
    call :cleanup_efi_drive
    exit /b 1
)

echo Creating additional boot entries if needed...
bcdedit /store "%EFI_DRIVE%\EFI\Microsoft\Boot\BCD" /set {default} recoveryenabled yes >nul 2>&1
bcdedit /store "%EFI_DRIVE%\EFI\Microsoft\Boot\BCD" /set {default} bootstatuspolicy IgnoreAllFailures >nul 2>&1

call :cleanup_efi_drive
exit /b 0

:cleanup_efi_drive
if defined EFI_DRIVE if defined EFI_DISK if defined EFI_PARTITION (
    :: Use Windows RE RAM drive (X:) for temp files
    set "TEMP=X:"
    set "tmpfile=%TEMP%\diskpart_%RANDOM%_%RANDOM%.txt"
    echo select disk %EFI_DISK% > "%tmpfile%"
    echo select partition %EFI_PARTITION% >> "%tmpfile%"
    echo remove letter=%EFI_DRIVE:~0,1% >> "%tmpfile%"
    diskpart /s "%tmpfile%" >nul
    if exist "%tmpfile%" del "%tmpfile%"
)
exit /b 0

:recreate_efi_partition
echo WARNING: This will delete and recreate the EFI partition!
echo All boot data will be lost and rebuilt.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" exit /b 1

if not defined EFI_DISK (
    echo Cannot determine target disk. Aborting.
    exit /b 1
)

:: Use Windows RE RAM drive (X:) for temp files
set "TEMP=X:"
set "tmpfile=%TEMP%\diskpart_%RANDOM%_%RANDOM%.txt"
set "NEW_EFI_DRIVE=T:"

echo Deleting corrupted EFI partition...
echo select disk %EFI_DISK% > "%tmpfile%"
if defined EFI_PARTITION (
    echo select partition %EFI_PARTITION% >> "%tmpfile%"
    echo delete partition override >> "%tmpfile%"
)

echo Creating new EFI partition (260MB)...
echo create partition efi size=260 >> "%tmpfile%"
echo format fs=fat32 quick label="System" >> "%tmpfile%"
echo assign letter=%NEW_EFI_DRIVE:~0,1% >> "%tmpfile%"
echo active >> "%tmpfile%"

diskpart /s "%tmpfile%"
if %errorlevel% neq 0 (
    echo Failed to create new EFI partition.
    if exist "%tmpfile%" del "%tmpfile%"
    exit /b 1
)

echo Rebuilding bootloader on new EFI partition...
bcdboot "%windir%" /s "%NEW_EFI_DRIVE%" /f UEFI >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to install bootloader on new EFI partition.
)

echo Removing temporary drive letter...
echo select disk %EFI_DISK% > "%tmpfile%"
echo list partition >> "%tmpfile%"
for /f "tokens=1,2,3,4* delims= " %%a in ('diskpart /s "%tmpfile%" ^| findstr /i "System"') do (
    if "%%e"=="System" (
        echo select partition %%b >> "%tmpfile%"
        echo remove letter=%NEW_EFI_DRIVE:~0,1% >> "%tmpfile%"
        diskpart /s "%tmpfile%" >nul
        goto efi_cleanup_done
    )
)

:efi_cleanup_done
if exist "%tmpfile%" del "%tmpfile%"
exit /b 0

:advanced_boot_repair
echo Performing advanced boot repair operations...

echo 1. Backing up current boot configuration...
if exist "%WINDOWS_DRIVE%\Boot\BCD" (
    copy "%WINDOWS_DRIVE%\Boot\BCD" "%WINDOWS_DRIVE%\Boot\BCD.backup.%DATE:/=-%_%TIME::=-%" >nul 2>&1
)

echo 2. Rebuilding master boot record...
bootrec /fixmbr >nul 2>&1
if %errorlevel% neq 0 echo MBR rebuild failed.

echo 3. Rebuilding boot sector...
bootrec /fixboot >nul 2>&1
if %errorlevel% neq 0 (
    echo Standard boot sector repair failed, trying alternative...
    bootsect /nt60 %WINDOWS_DRIVE% /mbr /force >nul 2>&1
)

echo 4. Scanning for all Windows installations...
bootrec /scanos >nul 2>&1

echo 5. Rebuilding BCD with all found installations...
bootrec /rebuildbcd >nul 2>&1

echo 6. Setting boot configuration policies...
bcdedit /set {default} recoveryenabled yes >nul 2>&1
bcdedit /set {default} bootstatuspolicy IgnoreAllFailures >nul 2>&1
bcdedit /set {bootmgr} timeout 10 >nul 2>&1

if "%BOOT_MODE%"=="UEFI" (
    echo 7. Repairing UEFI boot entries...
    call :repair_efi_boot
)

echo Advanced boot repair completed.
exit /b 0

:end
echo.
echo =====================================
echo Repair operations completed.
echo =====================================
echo.
echo Summary of actions taken:
if "%choice%"=="5" (
    echo - Disk integrity check and repair
    echo - System file integrity verification
    echo - Windows image health repair  
    echo - Boot configuration rebuild
    echo - Memory diagnostic scheduled
)
echo.
echo IMPORTANT: Please restart your computer now.
echo The system will complete any pending operations during boot.
echo.

timeout /t 10 /nobreak
endlocal
exit /b 0
