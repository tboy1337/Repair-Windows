@echo off
setlocal enabledelayedexpansion

:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%
)

:: Determine drive type for the system drive (assuming it's on disk with Index=0)
for /f "tokens=2 delims==" %%A in ('wmic diskdrive where "Index=0" get MediaType /value ^| find "="') do (
    set driveType=%%A
    rem Remove any spaces from the value
    set driveType=!driveType: =!
)
echo Detected drive type: %driveType%

:: Check if the drive type contains "SSD"
echo %driveType% | findstr /I "SSD" >nul
if %errorlevel%==0 (
    echo SSD detected. Running SSD relevant commands...
    
    echo Analyzing SSD drive...
    defrag /C /A /H >nul 2>&1
    if %errorlevel% neq 0 (
       echo Failed to analyze SSD drive.
    )
    
    echo Optimizing SSD drive (TRIM operation)...
    defrag /C /O /H >nul 2>&1
    if %errorlevel% neq 0 (
       echo Failed to optimize SSD drive.
    )
) else (
    echo HDD detected. Running HDD relevant commands...
    
    echo Analyzing all drives...
    defrag /C /A /H >nul 2>&1
    if %errorlevel% neq 0 (
       echo Failed to analyze all drives.
    )
    
    echo Performing boot optimization on %SystemDrive%...
    defrag "%SystemDrive%" /B /H >nul 2>&1
    if %errorlevel% neq 0 (
       echo Failed to perform boot optimization on %SystemDrive%
    )
    
    echo Optimizing the storage tiers on all drives...
    defrag /C /G /I 60 /H >nul 2>&1
    if %errorlevel% neq 0 (
       echo Failed to optimize the storage tiers on all drives.
    )
    
    echo Performing slab consolidation on all drives...
    defrag /C /K /H >nul 2>&1
    if %errorlevel% neq 0 (
       echo Failed to perform slab consolidation on all drives.
    )
    
    echo Optimizing all drives (might take a long time)...
    defrag /C /O /H >nul 2>&1
    if %errorlevel% neq 0 (
       echo Failed to optimize all drives.
    )
    
    echo Performing free space consolidation on all drives...
    defrag /C /X /H >nul 2>&1
    if %errorlevel% neq 0 (
       echo Failed to perform free space consolidation on all drives.
    )
)

timeout /t 5 /nobreak

exit /b 0
