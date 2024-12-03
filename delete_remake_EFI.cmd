@echo off
setlocal enabledelayedexpansion

:: Create a temporary diskpart script file in X:\, which is the RAM drive in WinRE
set "tmpfile2=X:\diskpart_script_2_%RANDOM%.txt"
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
) > "%tmpfile2%"

:: Get list of all disks
for /f "skip=6 tokens=2" %%a in ('diskpart /s "%tmpfile2%"') do (
    :: For each disk, list its partitions
    (
        echo select disk %%a
        echo list partition
    ) > "%tmpfile2%"
    
    :: Check each partition on this disk for "System"
    for /f "tokens=1,2,3,4,5 delims= " %%b in ('diskpart /s "%tmpfile2%" ^| findstr /i "System"') do (
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
) > "%tmpfile2%"
diskpart /s "%tmpfile2%"

:: Step 4: Create a New EFI
(
    echo select disk %foundDisk%
    echo create partition efi size=100
    echo format fs=fat32 quick
    echo assign letter=%newEFIDrive%
) > "%tmpfile2%"
diskpart /s "%tmpfile2%"

:: Step 5: Restore Bootloader
bcdboot %windowsDrive%\Windows /s %newEFIDrive% /f UEFI
bootsect /nt60 SYS

:: Step 6: Cleanup and Exit
:cleanup
if exist "%tmpfile2%" del "%tmpfile2%"
