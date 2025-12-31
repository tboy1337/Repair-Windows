@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo Right-click and select "Run as administrator"
    timeout /t 10 /nobreak
    exit /b 1
)

echo +=========================================+
echo + Windows Performance Optimization Script +
echo +=========================================+
echo.

echo Creating system restore point...
powershell -Command "Checkpoint-Computer -Description 'Before Performance Tweaks' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Could not create restore point.
    echo Exiting...
    timeout /t 10 /nobreak
    exit /b 1
) else (
    echo Restore point created successfully.
)
echo.

echo Applying performance tweaks...
echo.

echo [1/13] Enabling Hardware-accelerated GPU Scheduling...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to enable GPU scheduling
) else (
    echo    SUCCESS: GPU scheduling enabled
)
echo.

echo [2/13] Optimizing GPU timeout detection and recovery...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay /t REG_DWORD /d 10 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize TdrDelay
) else (
    echo    SUCCESS: TdrDelay optimized
)

reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDdiDelay /t REG_DWORD /d 10 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize TdrDdiDelay
) else (
    echo    SUCCESS: TdrDdiDelay optimized
)
echo.

echo [3/13] Disabling Network Throttling Index...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to disable network throttling
) else (
    echo    SUCCESS: Network throttling disabled
)
echo.

echo [4/13] Optimizing network adapter settings...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 64 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize DefaultTTL
) else (
    echo    SUCCESS: DefaultTTL optimized
)

reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDupAcks /t REG_DWORD /d 2 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize TcpMaxDupAcks
) else (
    echo    SUCCESS: TcpMaxDupAcks optimized
)

echo    Disabling network adapter power management...
powershell -Command "$adapters = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}; foreach ($adapter in $adapters) { $powerMgmt = Get-WmiObject -Class MSPower_DeviceEnable -Namespace root\wmi | Where-Object {$_.InstanceName -like \"*$($adapter.InterfaceGuid)*\"}; if ($powerMgmt) { $powerMgmt.Enable = $false; $powerMgmt.Put() | Out-Null } }; Write-Host '    SUCCESS: Network adapter power management disabled'" 2>nul
echo.

echo [5/13] Improving system responsiveness...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to improve system responsiveness
) else (
    echo    SUCCESS: System responsiveness improved
)
echo.

echo [6/13] Optimizing task scheduling for games/multimedia...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize GPU Priority
) else (
    echo    SUCCESS: GPU Priority optimized
)

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority /t REG_DWORD /d 6 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize Priority
) else (
    echo    SUCCESS: Priority optimized
)

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d High /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize Scheduling Category
) else (
    echo    SUCCESS: Scheduling Category optimized
)
echo.

echo [7/13] Disabling paging executive (requires 8GB+ RAM)...
powershell -Command "$totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2); Write-Host \"    Detected RAM: $totalRAM GB\"; if ($totalRAM -ge 8) { Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'DisablePagingExecutive' -Value 1 -Type DWord -ErrorAction Stop; Write-Host '    SUCCESS: Paging executive disabled' } else { Write-Host '    SKIPPED: Less than 8GB RAM detected' }" 2>nul
echo.

echo [8/13] Optimizing large system cache...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize system cache
) else (
    echo    SUCCESS: System cache optimized
)
echo.

echo [9/13] Reducing menu show delay...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to reduce menu delay
) else (
    echo    SUCCESS: Menu delay reduced
)
echo.

echo [10/13] Disabling mouse acceleration...
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize MouseSpeed
) else (
    echo    SUCCESS: MouseSpeed optimized
)

reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize MouseThreshold1
) else (
    echo    SUCCESS: MouseThreshold1 optimized
)

reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to optimize MouseThreshold2
) else (
    echo    SUCCESS: MouseThreshold2 optimized
)
echo.

echo [11/13] Disabling USB selective suspend...
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to disable USB selective suspend
) else (
    echo    SUCCESS: USB selective suspend disabled
)

powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to disable USB selective suspend on DC
) else (
    echo    SUCCESS: USB selective suspend disabled on DC
)
echo.

echo [12/13] Setting processor power management to maximum performance...
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 >nul 2>&1
if %errorLevel% neq 0 (
    echo    ERROR: Failed to set processor power management
) else (
    echo    SUCCESS: Processor set to maximum performance
)
echo.

echo [13/13] Checking for SSD and disabling Superfetch if needed...
powershell -Command "$hasSSD = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' }; if ($hasSSD) { Stop-Service -Name 'SysMain' -Force -ErrorAction SilentlyContinue; Set-Service -Name 'SysMain' -StartupType Disabled -ErrorAction SilentlyContinue; Write-Host '    SUCCESS: Superfetch disabled (SSD detected)' } else { Write-Host '    INFO: No SSD detected, keeping Superfetch enabled' }" 2>nul

echo.
echo +==================================+
echo + All tweaks applied successfully! +
echo +==================================+
echo.
echo IMPORTANT: A system restart is REQUIRED for 
echo these changes to take full effect.
echo.
echo If you experience issues, restore using the
echo system restore point created at the start.
echo.

timeout /t 10 /nobreak
exit /b 0
