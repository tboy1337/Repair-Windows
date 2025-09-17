@echo off
setlocal EnableDelayedExpansion

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

:MAIN_MENU
cls
echo ===============================================================
echo              Windows Time Service Repair
echo ===============================================================
echo.
echo Current Date/Time: %date% %time%
echo.
echo 1. Quick Time Sync (Resync)
echo 2. Force Time Resync with Network Rediscovery
echo 3. Complete Time Service Repair (Stop/Restart/Configure)
echo 4. Configure Reliable Time Servers (pool.ntp.org)
echo 0. Exit
echo.
set /p choice="Select an option (0-4): "

if "%choice%"=="0" goto EXIT
if "%choice%"=="1" goto QUICK_SYNC
if "%choice%"=="2" goto FORCE_SYNC
if "%choice%"=="3" goto FIX_SERVICE
if "%choice%"=="4" goto CONFIGURE_RELIABLE

echo Invalid selection. Please try again.
timeout /t 2 /nobreak >nul 2>&1
goto MAIN_MENU

:QUICK_SYNC
echo ===============================================================
echo                    Quick Time Synchronization
echo ===============================================================
echo.
echo Performing quick time synchronization...
w32tm /resync /nowait
if %errorlevel% equ 0 (
    echo SUCCESS: Time synchronization initiated.
) else (
    echo ERROR: Failed to initiate time synchronization. Error code: %errorlevel%
)
echo.
echo Current time after sync: %time%
echo.
timeout /t 5 /nobreak
goto MAIN_MENU

:FORCE_SYNC
echo ===============================================================
echo              Force Resync with Network Rediscovery
echo ===============================================================
echo.
echo Performing forced time synchronization with network rediscovery...
echo This may take a few moments...
w32tm /resync /rediscover
if %errorlevel% equ 0 (
    echo SUCCESS: Forced time synchronization with rediscovery completed.
) else (
    echo ERROR: Failed to complete forced synchronization. Error code: %errorlevel%
)
echo.
echo Current time after sync: %time%
echo.
timeout /t 5 /nobreak
goto MAIN_MENU

:FIX_SERVICE
echo ===============================================================
echo               Complete Time Service Repair
echo ===============================================================
echo.
echo This will completely rebuild and repair the Windows Time Service:
echo - Stop and restart the time service
echo - Reset service registry configuration to Windows defaults
echo - Force time synchronization
echo.
set /p confirm="Are you sure you want to continue? (Y/N): "
if /i not "%confirm%"=="Y" goto MAIN_MENU

echo.
echo Step 1: Stopping Windows Time service...
net stop w32time
if %errorlevel% neq 0 (
    echo WARNING: Failed to stop Windows Time service. Error code: %errorlevel%
)

echo Step 2: Unregistering time service (clearing registry)...
w32tm /unregister
if %errorlevel% neq 0 (
    echo ERROR: Failed to unregister time service. Error code: %errorlevel%
    echo Repair cannot continue.
    timeout /t 5 /nobreak
    goto MAIN_MENU
)

timeout /t 2 /nobreak >nul 2>&1

echo Step 3: Re-registering time service (rebuilding registry)...
w32tm /register
if %errorlevel% neq 0 (
    echo ERROR: Failed to register time service. Error code: %errorlevel%
    echo Repair cannot continue.
    timeout /t 5 /nobreak
    goto MAIN_MENU
)

echo Step 4: Starting Windows Time service...
net start w32time
if %errorlevel% neq 0 (
    echo ERROR: Failed to start Windows Time service. Error code: %errorlevel%
    echo Repair cannot continue.
    timeout /t 5 /nobreak
    goto MAIN_MENU
)

echo Step 5: Forcing time synchronization with default configuration...
w32tm /resync /rediscover
if %errorlevel% equ 0 (
    echo SUCCESS: Time synchronization completed successfully.
) else (
    echo WARNING: Time synchronization failed. Error code: %errorlevel%
    echo However, the service has been repaired and reset to defaults.
)

echo Time service has been completely rebuilt and reset to Windows defaults.
echo Current time: %time%
echo.
timeout /t 5 /nobreak
goto MAIN_MENU

:CONFIGURE_RELIABLE
echo ===============================================================
echo            Configure Reliable Time Servers
echo ===============================================================
echo.
echo Configuring reliable time servers from pool.ntp.org...

echo Stopping Windows Time service...
net stop w32time >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Failed to stop Windows Time service. Error code: %errorlevel%
)

echo Configuring reliable time server pool...
w32tm /config /manualpeerlist:"0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org,3.pool.ntp.org" /syncfromflags:manual /reliable:NO /update
if %errorlevel% neq 0 (
    echo ERROR: Failed to configure time servers. Error code: %errorlevel%
    echo Configuration cannot continue.
    timeout /t 5 /nobreak
    goto MAIN_MENU
)

echo Starting Windows Time service...
net start w32time >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Failed to start Windows Time service. Error code: %errorlevel%
    echo Configuration cannot continue.
    timeout /t 5 /nobreak
    goto MAIN_MENU
)

echo Forcing immediate synchronization...
w32tm /resync /rediscover
if %errorlevel% equ 0 (
    echo SUCCESS: Time synchronization completed successfully.
) else (
    echo WARNING: Time synchronization failed. Error code: %errorlevel%
    echo However, reliable time servers have been configured.
)

echo Reliable time servers configured: 0-3.pool.ntp.org
echo Current time: %time%
echo.
timeout /t 5 /nobreak
goto MAIN_MENU

:EXIT
echo.
echo Thank you for using Windows Time Service Repair script.
echo.
timeout /t 5 /nobreak
exit /b 0
