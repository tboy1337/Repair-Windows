:: Create a temporary diskpart script file in X:\, which is the RAM drive in WinRE
set "tmpfile2=X:\diskpart_script_2_%RANDOM%.txt"
set "foundDisk="
set "partitionNum="
set "newEFIDrive=T:"
set "newPartitionNum="

:: Step 2: Locate the EFI Partition
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
    goto :cleanup
)

echo Found EFI partition on Disk %foundDisk%, Partition %partitionNum%.

:: Step 3: Delete the Corrupted EFI
echo Deleting the Corrupted EFI partition...
(
    echo select disk %foundDisk%
    echo select partition %partitionNum%
    echo delete partition override
) > "%tmpfile2%"
diskpart /s "%tmpfile2%"

:: Step 4: Create a New EFI
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

:: Step 5: Restore Bootloader
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
bootsect /nt60 %newEFIDrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to update the boot sector.
)

:: Step 6: Cleanup
:cleanup
echo Cleaning up...
if exist "%tmpfile2%" del "%tmpfile2%"
