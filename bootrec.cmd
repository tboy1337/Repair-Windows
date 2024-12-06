cd /d "%WINDOWS_DRIVE%\Windows\System32" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %WINDOWS_DRIVE%\Windows\System32
)

echo Scanning all disks for Windows installations...
bootrec /scanos >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to scan all disks for Windows installations.
)

:: Determine boot mode
echo Checking if the OS is running in Legacy or UEFI mode...
bcdedit | findstr /i "\EFI\" >nul
if %errorlevel% equ 0 (
    echo The system is running in UEFI mode.

    :: Rebuilding the BCD store
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

    :: Writing a new boot sector
    echo Writing a new boot sector on the system partition...
    bootrec /fixboot >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to write a new boot sector on the system partition.
        bootsect /nt60 SYS >nul 2>&1
        bootrec /fixboot >nul 2>&1
        :: NOW DO repair_EFI.cmd method to assign drive letters and repair if above is error. (PROBABLY THIS ONE ONLY)
        :: NOW DO delete_remake_EFI.cmd method if the above is error.
    )
) else (
    echo The system is running in Legacy mode.

    :: Check if the drive is FAT-based
    for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo %WINDOWS_DRIVE%^|find "File System Name"') do (
        echo %%A | findstr /i /r "^FAT" >nul
        if not errorlevel 1 (
            echo %WINDOWS_DRIVE% drive is FAT-based, repairing the MBR...
            bootrec /fixmbr >nul 2>&1
            if !errorlevel! neq 0 (
                echo Failed to fix the MBR.
            )
        )
    )
)

cd /d "X:\Windows\System32" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to X:\Windows\System32
)
