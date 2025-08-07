@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

echo Analysing all drives...
defrag /C /A /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to analyze all drives.  Error code: %errorlevel%
)

echo Checking if %SystemDrive% is an SSD...
set "IsSSD=false"
for /f "tokens=2 delims==" %%i in ('wmic diskdrive where "DeviceID like '%%PHYSICALDRIVE0%%'" get MediaType /value 2^>nul ^| find "="') do (
    if /i "%%i"=="SSD" set "IsSSD=true"
)

REM Alternative method using PowerShell if WMIC fails
if "!IsSSD!"=="false" (
    for /f %%i in ('powershell -command "Get-PhysicalDisk | Where-Object {$_.DeviceID -eq 0} | Select-Object -ExpandProperty MediaType" 2^>nul') do (
        if /i "%%i"=="SSD" set "IsSSD=true"
    )
)

if "!IsSSD!"=="true" (
    echo %SystemDrive% is an SSD - skipping boot optimization...
) else (
    echo Performing boot optimization on %SystemDrive%...
    defrag "%SystemDrive%" /B /H >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to perform boot optimization on %SystemDrive%.  Error code: %errorlevel%
    )
)

echo Optimizing the storage tiers on all drives...
defrag /C /G /I 300 /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to optimize the storage tiers on all drives.  Error code: %errorlevel%
)

echo Performing slab consolidation on all drives...
defrag /C /K /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to perform slab consolidation on all drives.  Error code: %errorlevel%
)

echo Optimizing all drives (might take a long time)...
defrag /C /O /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to optimize all drives.  Error code: %errorlevel%
)

echo Performing free space consolidation on all drives...
defrag /C /X /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to perform free space consolidation on all drives.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
endlocal
exit /b 0
