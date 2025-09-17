@echo off
setlocal enabledelayedexpansion

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

echo Analysing all applicable drives...
defrag /C /A /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to analyze all applicable drives.  Error code: %errorlevel%
)

echo Checking if %SystemDrive% is an SSD...
set "IsSSD=false"
set "PhysicalDiskNum="

REM Find which physical disk contains the C: drive
for /f "tokens=2 delims==" %%i in ('wmic logicaldisk where "DeviceID='%SystemDrive%'" assoc:diskpartition 2^>nul ^| findstr "DiskIndex"') do (
    set "PhysicalDiskNum=%%i"
)

REM Alternative method using PowerShell to find physical disk
if "!PhysicalDiskNum!"=="" (
    for /f %%i in ('powershell -command "Get-Partition -DriveLetter '%SystemDrive:~0,1%' | Select-Object -ExpandProperty DiskNumber" 2^>nul') do (
        set "PhysicalDiskNum=%%i"
    )
)

if "!PhysicalDiskNum!"=="" (
    echo WARNING: Could not determine physical disk type for %SystemDrive% - assuming SSD for safety
    set "IsSSD=true"
) else (
    REM Check if this physical disk is an SSD:
    REM Method 1: PowerShell MediaType
    for /f %%i in ('powershell -command "Get-PhysicalDisk | Where-Object {$_.DeviceID -eq !PhysicalDiskNum!} | Select-Object -ExpandProperty MediaType" 2^>nul') do (
        if /i "%%i"=="SSD" set "IsSSD=true"
    )
    
    REM Method 2: PowerShell SpindleSpeed check
    if "!IsSSD!"=="false" (
        for /f %%i in ('powershell -command "Get-PhysicalDisk | Where-Object {$_.DeviceID -eq !PhysicalDiskNum!} | Select-Object -ExpandProperty SpindleSpeed" 2^>nul') do (
            if "%%i"=="0" set "IsSSD=true"
        )
    )
    
    REM Method 3: Check if TRIM is enabled
    if "!IsSSD!"=="false" (
        for /f %%i in ('fsutil behavior query DisableDeleteNotify 2^>nul') do (
            if "%%i"=="0" (
                set "IsSSD=true"
            )
        )
    )
)

if "!IsSSD!"=="true" (
    echo %SystemDrive% is an SSD - skipping boot optimization...
) else (
    echo %SystemDrive% is an HDD - performing boot optimization...
    defrag "%SystemDrive%" /B /H >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to perform boot optimization on %SystemDrive%.  Error code: %errorlevel%
    )
)

echo Optimizing the storage tiers on all applicable drives...
defrag /C /G /I 300 /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to optimize the storage tiers on all applicable drives.  Error code: %errorlevel%
)

echo Performing slab consolidation on all applicable drives...
defrag /C /K /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to perform slab consolidation on all applicable drives.  Error code: %errorlevel%
)

echo Optimizing all applicable drives (might take a long time)...
defrag /C /O /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to optimize all applicable drives.  Error code: %errorlevel%
)

echo Performing free space consolidation on all applicable drives...
defrag /C /X /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to perform free space consolidation on all applicable drives.  Error code: %errorlevel%
)

timeout /t 10 /nobreak
endlocal
exit /b 0
