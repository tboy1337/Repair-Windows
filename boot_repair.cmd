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
        chkdsk "%WINDOWS_DRIVE%" /sdcleanup >nul 2>&1
    )
)

if "%choice%"=="7" goto sfcdism
goto menu

:sfcdism
echo.
echo Running SFC & DISM health check & repair on %WINDOWS_DRIVE%...
echo This may take a while...

echo Checking integrity of all protected system files...
sfc /scannow /offbootdir=%WINDOWS_DRIVE%\ /offwindir=%windir% >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check integrity of all protected system files.
    SFC_SUCCESS=1
)

echo Checking for corruption flags in the local Windows image...
dism /image:%WINDOWS_DRIVE%\ /cleanup-image /checkhealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Corruption flags found in the local Windows image, attempting repair...
    dism /image:%WINDOWS_DRIVE%\ /cleanup-image /restorehealth >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to repair corruption in the local Windows image.
    )
    goto jump
)

echo Checking for corruption in the local Windows image...
dism /image:%WINDOWS_DRIVE%\ /cleanup-image /scanhealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Corruption found in the local Windows image, attempting repair...
    dism /image:%WINDOWS_DRIVE%\ /cleanup-image /restorehealth >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to repair corruption in the local Windows image.
    )
)

:jump
if %SFC_SUCCESS% neq 0 (
    echo Checking integrity of all protected system files...
    sfc /scannow /offbootdir=%WINDOWS_DRIVE%\ /offwindir=%windir% >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to check integrity of all protected system files.
    )
)

echo Deleting resources associated with corrupted mounted images...
DISM /image:%WINDOWS_DRIVE%\ /Cleanup-Mountpoints >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete resources associated with corrupted mounted images.
)

if "%choice%"=="7" goto startup
goto menu

:startup
:: This should be bootrec.cmd!!!!!
echo.
echo Running Startup Repair...
cd /d "%WINDOWS_DRIVE%\Windows\System32\Boot"

bootrec /scanos >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to scan OS.
)

for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo %WINDOWS_DRIVE%^|find "File System Name"') do (
    echo %%A | findstr /i /r "^FAT" >nul
    if not errorlevel 1 (
        echo %WINDOWS_DRIVE% drive is FAT-based, repairing the MBR...
        bootrec /fixmbr >nul 2>&1
        if %errorlevel% neq 0 (
            echo Failed to fix the MBR.
        )
    )
)

bootrec /fixboot >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to fix BOOT.
)

bootrec /rebuildbcd >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to rebuild BCD.
)

cd /d "X:\Windows\System32"
if "%choice%"=="7" goto memory
goto menu

:memory
echo.
echo Scheduling Memory Diagnostic for next restart...
mdsched >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to schedule a memory diagnostic for next restart.
)

if "%choice%"=="7" goto end
goto menu

:end
echo.
echo Repair operations completed.
echo Please restart your computer for changes to take effect.

timeout /t 5 /nobreak
exit /b 0
