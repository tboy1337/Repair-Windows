@echo off
setlocal enabledelayedexpansion

echo Windows Recovery Environment Repair Script
echo =====================================
echo.

set SFC_SUCCESS=0

:: Check if running in Windows RE
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE" >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run in Windows Recovery Environment.
    echo Please boot into Windows RE and try again.
    timeout /t 5 /nobreak
    exit /b 1
)

:: Find Windows directory
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control Panel\Windows" /v SystemRoot 2^>nul') do set "windir=%%b"
if "%windir%"=="" (
    echo Could not determine Windows installation location.
    timeout /t 5 /nobreak
    exit /b 1
)

:: Extract drive letter from Windows directory
set "WINDOWS_DRIVE=%windir:~0,2%"

:menu
cls
echo Windows installation detected on: %WINDOWS_DRIVE%
echo Choose repair operations to perform:
echo 1) Run CHKDSK Disk Repair
echo 2) Run SFC & DISM Health Check & Repair
echo 3) Run Startup Repair
echo 4) Run Memory Diagnostic
echo 5) Run ALL Repairs
echo 6) Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto chkdskscan
if "%choice%"=="2" goto sfcdism
if "%choice%"=="3" goto startup
if "%choice%"=="4" goto memory
if "%choice%"=="5" goto all
if "%choice%"=="6" goto end

echo Invalid choice. Please try again.
timeout /t 3 /nobreak
goto menu

:all
echo Running all repair operations...
goto chkdskscan

:chkdskscan
echo.
echo Running CHKDSK on %WINDOWS_DRIVE%...
echo This may take a while...
for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo %WINDOWS_DRIVE%^|find "File System Name"') do (
    echo %%A | findstr /i /r "^FAT" >nul
    if not errorlevel 1 (
        echo %WINDOWS_DRIVE% drive is FAT-based.
        echo Repairing %WINDOWS_DRIVE% file system...
        chkdsk "%WINDOWS_DRIVE%" /R /X >nul 2>&1
    ) else (
        echo %WINDOWS_DRIVE% drive is NTFS-based.
        echo Repairing %WINDOWS_DRIVE% file system...
        chkdsk "%WINDOWS_DRIVE%" /R /X >nul 2>&1
        echo Cleaning up unnecessary data structures and unallocated metadata files...
        chkdsk "%WINDOWS_DRIVE%" /sdcleanup >nul 2>&1
    )
)

if "%choice%"=="5" goto sfcdism
goto menu

:sfcdism
echo.
echo Running SFC & DISM health check & repair on %WINDOWS_DRIVE%...
echo This may take a while...

echo Checking integrity of all protected system files...
sfc /scannow /offbootdir=%WINDOWS_DRIVE% /offwindir=%windir% >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check integrity of all protected system files.
    SFC_SUCCESS=1
)

echo Checking for corruption flags in the local Windows image...
dism /image:%WINDOWS_DRIVE% /cleanup-image /checkhealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Corruption flags found in the local Windows image, attempting repair...
    dism /image:%WINDOWS_DRIVE% /cleanup-image /restorehealth >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to repair corruption in the local Windows image.
    )
)

echo Checking for corruption in the local Windows image...
dism /image:%WINDOWS_DRIVE% /cleanup-image /scanhealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Corruption found in the local Windows image, attempting repair...
    dism /image:%WINDOWS_DRIVE% /cleanup-image /restorehealth >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to repair corruption in the local Windows image.
    )
)

if %SFC_SUCCESS% neq 0 (
    echo Checking integrity of all protected system files...
    sfc /scannow /offbootdir=%WINDOWS_DRIVE% /offwindir=%windir% >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to check integrity of all protected system files.
    )
)

echo Deleting resources associated with corrupted mounted images...
dism /image:%WINDOWS_DRIVE% /Cleanup-Mountpoints >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete resources associated with corrupted mounted images.
)

echo Analyzing component store...
dism /image:%WINDOWS_DRIVE% /Cleanup-Image /AnalyzeComponentStore >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to analyze component store.
)

echo Cleaning component store...
dism /image:%WINDOWS_DRIVE% /Cleanup-Image /StartComponentCleanup >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to clean component store.
)

if "%choice%"=="5" goto startup
goto menu

:startup
echo.
echo Running Startup Repair...

call :run_bootrec

if "%choice%"=="5" goto memory
goto menu

:memory
echo.
echo Scheduling Memory Diagnostic for next restart...
mdsched >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to schedule a memory diagnostic for next restart.
)

if "%choice%"=="5" goto end
goto menu

:end
echo.
echo Repair operations completed.
echo Please restart your computer for changes to take effect.

timeout /t 5 /nobreak
exit /b 0

:: ========================= BOOTREC FUNCTIONS =========================

:run_bootrec
cd /d "%WINDOWS_DRIVE%\Windows\System32" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %WINDOWS_DRIVE%\Windows\System32
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
    echo Failed to scan all disks for Windows installations.
)

echo Rebuilding the BCD store...
bootrec /rebuildbcd >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to rebuild the BCD store, trying again...
    bcdedit /export "%WINDOWS_DRIVE%\BCDBackup" >nul 2>&1
    attrib bcd -s -h -r >nul 2>&1
    ren "%WINDOWS_DRIVE%\boot\bcd" "bcd.old" >nul 2>&1
    bootrec /rebuildbcd >nul 2>&1
    
    if %errorlevel% neq 0 (
        echo Still failed to rebuild BCD. Attempting to repair EFI partition...
        call :repair_efi
        
        if %errorlevel% neq 0 (
            echo EFI repair failed. Attempting to delete and recreate EFI partition...
            call :delete_remake_efi
        )
    )
)

echo Writing a new boot sector on the system partition...
bootrec /fixboot >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to write a new boot sector on the system partition, trying again...
    bootsect /nt60 SYS >nul 2>&1
    bootrec /fixboot >nul 2>&1
    
    if %errorlevel% neq 0 (
        echo Still failed to fix boot. Attempting to repair EFI partition...
        call :repair_efi
        
        if %errorlevel% neq 0 (
            echo EFI repair failed. Attempting to delete and recreate EFI partition...
            call :delete_remake_efi
        )
    )
)

cd /d "X:\Windows\System32" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to X:\Windows\System32
)

exit /b 0

:: ============= REPAIR EFI FUNCTION =============
:repair_efi
echo Attempting to repair the EFI partition...

:: Create a temporary diskpart script file in X:\, which is the RAM drive in WinRE
set "tmpfile=X:\diskpart_script_%RANDOM%.txt"
set "RepairDriveLetter=S:"

:: Create diskpart script to list all disks and their partitions
(
    echo list disk
) > "%tmpfile%"

:: Get list of all disks
for /f "skip=6 tokens=2" %%a in ('diskpart /s "%tmpfile%"') do (
    :: For each disk, list its partitions
    (
        echo select disk %%a
        echo list partition
    ) > "%tmpfile%"
    
    :: Check each partition on this disk
    for /f "tokens=1,2,3,4,5 delims= " %%b in ('diskpart /s "%tmpfile%" ^| findstr /i "System"') do (
        if "%%f"=="System" (
            set "foundDisk=%%a"
            set "partitionNum=%%c"
        )
    )
)

:: If no EFI partition found, exit
if not defined partitionNum (
    echo Error: EFI partition not found.
    if exist "%tmpfile%" del "%tmpfile%"
    exit /b 1
)

:: Create new diskpart script to assign letter
(
    echo select disk %foundDisk%
    echo select partition %partitionNum%
    echo assign letter=%RepairDriveLetter:~0,1%
) > "%tmpfile%"

echo Found EFI partition on disk %foundDisk%, partition %partitionNum%
echo Assigning drive letter %RepairDriveLetter% to EFI partition...
diskpart /s "%tmpfile%" > nul

echo Repairing %RepairDriveLetter% file system...
chkdsk "%RepairDriveLetter%" /R /X >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to repair %RepairDriveLetter% file system.
)

echo Repairing the MBR on %RepairDriveLetter%...
bootsect /nt60 "%RepairDriveLetter%" /mbr /force >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to repair the MBR on %RepairDriveLetter%
)

:: Create diskpart script to remove letter
echo Removing drive letter...
(
    echo select disk %foundDisk%
    echo select partition %partitionNum%
    echo remove letter=%RepairDriveLetter:~0,1%
) > "%tmpfile%"

diskpart /s "%tmpfile%" > nul

:: Clean up temporary file
echo Cleaning up temporary files...
if exist "%tmpfile%" del "%tmpfile%"

exit /b %errorlevel%

:: ============= DELETE & REMAKE EFI FUNCTION =============
:delete_remake_efi
echo Attempting to delete and recreate the EFI partition...

:: Create a temporary diskpart script file in X:\, which is the RAM drive in WinRE
set "tmpfile2=X:\diskpart_script_2_%RANDOM%.txt"
set "foundDisk="
set "partitionNum="
set "newEFIDrive=T:"
set "newPartitionNum="

:: Locate the EFI Partition
(
    echo list disk
) > "%tmpfile2%"

:: Get list of all disks
for /f "skip=6 tokens=2" %%a in ('diskpart /s "%tmpfile2%"') do (
    :: For each disk, list its partitions
    (
        echo select disk %%a
        echo list partition
    ) > "%tmpfile2%"
    
    :: Check each partition on this disk for "System" (EFI)
    for /f "tokens=1,2,3,4,5 delims= " %%b in ('diskpart /s "%tmpfile2%" ^| findstr /i "System"') do (
        if "%%f"=="System" (
            set "foundDisk=%%a"
            set "partitionNum=%%c"
        )
    )
)

:: If no EFI partition found, exit
if not defined partitionNum (
    echo Error: EFI partition not found.
    if exist "%tmpfile2%" del "%tmpfile2%"
    exit /b 1
)

echo Found EFI partition on Disk %foundDisk%, Partition %partitionNum%.

:: Delete the Corrupted EFI
echo Deleting the corrupted EFI partition...
(
    echo select disk %foundDisk%
    echo select partition %partitionNum%
    echo delete partition override
) > "%tmpfile2%"
diskpart /s "%tmpfile2%"

:: Create a New EFI
echo Creating a new EFI partition...
(
    echo select disk %foundDisk%
    echo create partition efi size=100
    echo format fs=fat32 quick
    echo assign letter=%newEFIDrive%
) > "%tmpfile2%"
diskpart /s "%tmpfile2%"

:: Find the new EFI partition number
(
    echo select disk %foundDisk%
    echo list partition
) > "%tmpfile2%"
for /f "tokens=1,2,3,4,5 delims= " %%a in ('diskpart /s "%tmpfile2%" ^| findstr /i "System"') do (
    if "%%f"=="System" (
        set "newPartitionNum=%%b"
    )
)

:: Restore Bootloader
echo Restoring the bootloader...
bcdboot %windowsDrive%\Windows /s %newEFIDrive% /f UEFI >nul 2>&1

:: Remove the drive letter from the new EFI partition
echo Removing the drive letter from the new EFI partition...
(
    echo select disk %foundDisk%
    echo select partition %newPartitionNum%
    echo remove letter=%newEFIDrive%
) > "%tmpfile2%"
diskpart /s "%tmpfile2%"

echo Updating the boot sector to be compatible with modern Windows versions...
bootsect /nt60 %foundDisk% >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to update the boot sector.
)

:: Cleanup
echo Cleaning up temporary files...
if exist "%tmpfile2%" del "%tmpfile2%"

exit /b %errorlevel%
