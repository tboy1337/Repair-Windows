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
    echo Error: EFI partition not found.
    goto :cleanup
)

:: Create new diskpart script to assign letter
(
    echo select disk %foundDisk%
    echo select partition %partitionNum%
    echo assign letter=%driveLetter:~0,1%
) > "%tmpfile%"

echo Found EFI partition on disk %foundDisk%, partition %partitionNum%
echo Assigning drive letter %driveLetter% to EFI partition...
diskpart /s "%tmpfile%" > nul

echo Checking %driveLetter% file system...
chkdsk "%driveLetter%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Repairing %driveLetter% file system...
    chkdsk "%driveLetter%" /R /X >nul 2>&1
)

cd /d "%driveLetter%\EFI\Microsoft\Boot"

echo Fixing BOOT...
bootrec /fixboot >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to fix BOOT.
)

cd /d "X:\Windows\System32"

:: Create diskpart script to remove letter
(
    echo select disk %foundDisk%
    echo select partition %partitionNum%
    echo remove letter=%driveLetter:~0,1%
) > "%tmpfile%"

echo Removing drive letter...
diskpart /s "%tmpfile%" > nul

:cleanup
:: Clean up temporary file
if exist "%tmpfile%" del "%tmpfile%"
