@echo off
setlocal EnableDelayedExpansion

:: Create a temporary diskpart script file in X:\, which is the RAM drive in WinRE
set "tmpfile=X:\diskpart_script_%RANDOM%.txt"
set "driveLetter=S:"

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

:: If no system partition found, exit
if not defined partitionNum (
    echo Error: System partition not found.
    goto :cleanup
)

:: Create new diskpart script to assign letter
(
    echo select disk %foundDisk%
    echo select partition %partitionNum%
    echo assign letter=%driveLetter:~0,1%
) > "%tmpfile%"

echo Found System partition on disk %foundDisk%, partition %partitionNum%
echo Assigning drive letter %driveLetter% to system partition...
diskpart /s "%tmpfile%" > nul

:: Create diskpart script to remove letter
(
    echo select disk %foundDisk%
    echo select partition %partitionNum%
    echo remove letter=%driveLetter:~0,1%
) > "%tmpfile%"

cd /d %driveLetter%
:: ENTER COMMANDS HERE
cd /d X:

echo Removing drive letter...
diskpart /s "%tmpfile%" > nul

:cleanup
:: Clean up temporary file
if exist "%tmpfile%" del "%tmpfile%"

:: ----------------------------------------------------------------------------------------------------------------------------------------------

:: Create a temporary diskpart script file in X:\, which is the RAM drive in WinRE
set "tmpfile2=X:\diskpart_script_2_%RANDOM%.txt"
set "driveLetter2=T:"

:: Create diskpart script to list all disks and their partitions
(
    echo list disk
) > "%tmpfile2%"

:: Get list of all disks
for /f "skip=6 tokens=2" %%a in ('diskpart /s "%tmpfile%2"') do (
    :: For each disk, list its partitions
    (
        echo select disk %%a
        echo list partition
    ) > "%tmpfile2%"
    
    :: Check each partition on this disk
    for /f "tokens=1,2,3,4,5 delims= " %%b in ('diskpart /s "%tmpfile2%" ^| findstr /i "Reserved"') do (
        if "%%f"=="System" (
            set "foundDisk2=%%a"
            set "partitionNum2=%%c"
        )
    )
)

:: If no system partition found, exit
if not defined partitionNum2 (
    echo Error: System partition not found.
    goto :cleanup2
)

:: Create new diskpart script to assign letter
(
    echo select disk %foundDisk2%
    echo select partition %partitionNum2%
    echo assign letter=%driveLetter2:~0,1%
) > "%tmpfile2%"

echo Found System partition on disk %foundDisk2%, partition %partitionNum2%
echo Assigning drive letter %driveLetter2% to system partition...
diskpart /s "%tmpfile2%" > nul

:: Create diskpart script to remove letter
(
    echo select disk %foundDisk2%
    echo select partition %partitionNum2%
    echo remove letter=%driveLetter2:~0,1%
) > "%tmpfile2%"

cd /d %driveLetter2%
:: ENTER COMMANDS HERE
cd /d X:

echo Removing drive letter...
diskpart /s "%tmpfile2%" > nul

:cleanup2
:: Clean up temporary file
if exist "%tmpfile2%" del "%tmpfile2%"

exit
