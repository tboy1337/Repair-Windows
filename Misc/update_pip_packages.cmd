@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Updating All Pip Packages
echo ========================================
echo.

REM Check if Python/pip is available
python -m pip --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python or pip is not installed or not in PATH
    echo Please install Python and ensure it's added to your PATH
    timeout /t 10 /nobreak
    exit /b 1
)

echo Current pip version:
python -m pip --version
echo.

REM Update pip itself first
echo Updating pip itself...
python -m pip install --upgrade pip
if errorlevel 1 (
    echo WARNING: Failed to update pip itself
    echo.
)

echo.
echo Getting list of outdated packages...

REM Get list of outdated packages
python -m pip list --outdated > temp_outdated.txt 2>nul

REM Check if there are any outdated packages
if not exist temp_outdated.txt (
    echo No outdated packages found or error occurred.
    timeout /t 10 /nobreak
    exit /b 0
)

REM Count outdated packages (excluding header lines)
set /a count=0
for /f "skip=2 tokens=1" %%i in (temp_outdated.txt) do (
    if not "%%i"=="" set /a count+=1
)

if !count! equ 0 (
    echo All packages are already up to date!
    del temp_outdated.txt
    timeout /t 10 /nobreak
    exit /b 0
)

echo Found !count! outdated package(s).
echo.

REM Display outdated packages
echo Outdated packages:
echo ------------------
for /f "skip=2 tokens=1" %%i in (temp_outdated.txt) do (
    if not "%%i"=="" echo %%i
)

echo.
echo Proceeding with automatic updates...

echo.
echo Starting package updates...
echo ==========================

REM Update each package
set /a updated=0
set /a failed=0

for /f "skip=2 tokens=1" %%i in (temp_outdated.txt) do (
    if not "%%i"=="" (
        echo.
        echo Updating %%i...
        python -m pip install --upgrade %%i
        if errorlevel 1 (
            echo ERROR: Failed to update %%i
            set /a failed+=1
        ) else (
            echo SUCCESS: Updated %%i
            set /a updated+=1
        )
    )
)

REM Cleanup
del temp_outdated.txt

echo.
echo ========================================
echo           Update Summary
echo ========================================
echo Successfully updated: !updated! packages
echo Failed to update: !failed! packages
echo.

if !failed! gtr 0 (
    echo Some packages failed to update. This could be due to:
    echo - Permission issues ^(try running as administrator^)
    echo - Package conflicts or dependencies
    echo - Network connectivity issues
    echo.
)

echo Update process completed.
timeout /t 10 /nobreak
exit /b 0
