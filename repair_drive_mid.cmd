@echo off
setlocal

set "TARGET_DRIVE=%SystemDrive%"

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 10 /nobreak
    exit /b 1
)

for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo %TARGET_DRIVE%^|find "File System Name"') do (
    echo %%A | findstr /i /r "^FAT" >nul
    if not errorlevel 1 (
        echo %TARGET_DRIVE% drive is FAT-based.
        echo Repairing %TARGET_DRIVE% file system...
        echo This may take a while...
        if /i "%TARGET_DRIVE%"=="%SystemDrive%" (
            echo y | chkdsk "%TARGET_DRIVE%" /R /X >nul 2>&1
            echo Restarting system to complete repairs, please save your work.
            timeout /t 30 /nobreak
            shutdown /r /t 1 >nul 2>&1
            exit /b 1
        ) else (
            chkdsk "%TARGET_DRIVE%" /R /X >nul 2>&1
        )
    ) else (
        echo %TARGET_DRIVE% drive is NTFS-based.
        echo Repairing %TARGET_DRIVE% file system...
        echo This may take a while...
        if /i "%TARGET_DRIVE%"=="%SystemDrive%" (
            echo y | chkdsk "%TARGET_DRIVE%" /R /X >nul 2>&1
            echo Restarting system to complete repairs, please save your work.
            echo Run chkdsk "%TARGET_DRIVE%" /sdcleanup after repair finishes.
            timeout /t 30 /nobreak
            shutdown /r /t 1 >nul 2>&1
            exit /b 1
        ) else (
            chkdsk "%TARGET_DRIVE%" /R /X >nul 2>&1
            echo Cleaning up unnecessary data structures and unallocated metadata files...
            chkdsk "%TARGET_DRIVE%" /sdcleanup >nul 2>&1
        )
    )
)

echo Error repair finished.

timeout /t 10 /nobreak
endlocal
exit /b 1
