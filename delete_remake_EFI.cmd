@echo off
setlocal enabledelayedexpansion

:: Create a temporary diskpart script file in X:\, which is the RAM drive in WinRE
set "tmpfile=X:\diskpart_script_2_%RANDOM%.txt"
set "foundDisk="
set "partitionNum="
set "newEFIDrive=T:"

:: Step 1: Locate the Windows Installation Drive
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control Panel\Windows" /v SystemRoot 2^>nul') do set "windir=%%b"
if "%windir%"=="" (
    echo Could not determine Windows installation location.
    timeout /t 5 /nobreak
    exit /b 1
)

:: Extract drive letter from Windows directory
set "windowsDrive=%windir:~0,2%"
echo Found Windows installation on drive: %windowsDrive%

:: Step 2: Locate the System Partition (EFI)
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
    
    :: Check each partition on this disk for "System"
    for /f "tokens=1,2,3,4,5 delims= " %%b in ('diskpart /s "%tmpfile%" ^| findstr /i "System"') do (
        if "%%f"=="System" (
            set "foundDisk=%%a"
            set "partitionNum=%%c"
        )
    )
)

:: If no system partition found, exit
if not defined partitionNum (
    echo Error: System partition not found.
    goto :cleanup
)

echo Found system partition on Disk %foundDisk%, Partition %partitionNum%.

:: Step 3: Delete the Corrupted EFI
(
    echo select disk %foundDisk%
    echo select partition %partitionNum%
    echo delete partition override
) > "%tmpfile%"
diskpart /s "%tmpfile%"

:: Step 4: Create a New EFI
(
    echo select disk %foundDisk%
    echo create partition efi size=100
    echo format fs=fat32 quick
    echo assign letter=%newEFIDrive%
) > "%tmpfile%"
diskpart /s "%tmpfile%"

:: Step 5: Restore Bootloader
bcdboot %windowsDrive%\Windows /s %newEFIDrive% /f UEFI

:: Step 6: Cleanup and Exit
:cleanup
if exist "%tmpfile%" del "%tmpfile%"
echo Operation completed. Reboot your system.
exit /b 0
