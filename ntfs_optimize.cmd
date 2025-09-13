@echo off
setlocal

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

echo #=======================================================#
echo #          Optimizing NTFS behavior settings.           #
echo # These changes require a system reboot to take effect. #
echo #=======================================================#
echo.

echo Setting NTFS memory usage:
echo   0: System default (automatic memory management).
echo   1: Balanced memory usage (recommended for most systems).
echo   2: High memory usage (better performance, requires 16GB+ RAM).
:mem_prompt
set /p memchoice=Enter your choice (0-2): 
if not "%memchoice%"=="0" if not "%memchoice%"=="1" if not "%memchoice%"=="2" (
    echo Invalid choice. Please enter 0, 1, or 2.
    goto mem_prompt
)
fsutil behavior set memoryusage %memchoice% >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set memory usage. Error code: %errorlevel%
)

echo.
echo Setting MFT Zone size:
echo   1: ~12.5%% of volume (default, suitable for most users).
echo   2: ~25%% of volume (good for volumes with moderate file counts).
echo   3: ~37.5%% of volume (for high file-count scenarios, e.g., servers).
echo   4: ~50%% of volume (maximum reservation, use only if MFT fragmentation is a severe issue; reduces available space).
:mft_prompt
set /p mftchoice=Enter your choice (1-4): 
if not "%mftchoice%"=="1" if not "%mftchoice%"=="2" if not "%mftchoice%"=="3" if not "%mftchoice%"=="4" (
    echo Invalid choice. Please enter 1, 2, 3, or 4.
    goto mft_prompt
)
fsutil behavior set mftzone %mftchoice% >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set MFT Zone. Error code: %errorlevel%
)

echo.
echo Setting 8.3 filename creation:
echo   0: Enable (default, required for legacy applications).
echo   1: Disable (recommended for modern systems - improves performance).
:dot3_prompt
set /p dot3choice=Enter your choice (0-1): 
if not "%dot3choice%"=="0" if not "%dot3choice%"=="1" (
    echo Invalid choice. Please enter 0 or 1.
    goto dot3_prompt
)
fsutil behavior set disable8dot3 %dot3choice% >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set 8.3 filename creation. Error code: %errorlevel%
)

echo.
echo #==================================================================#
echo #                   NTFS optimization complete!                    #
echo #==================================================================#
echo # IMPORTANT: These changes require a system reboot to take effect. #
echo #           It is recommended to reboot your system now.           #
echo #==================================================================#
echo.

set /p rebootchoice=Would you like to reboot now? (Y/N): 
if /i "%rebootchoice%"=="Y" (
    echo Rebooting system in 30 seconds...
    timeout /t 30 /nobreak >nul 2>&1
    shutdown /r /t 1 >nul 2>&1
) else (
    echo Please reboot your system for changes to take effect.
)

timeout /t 10 /nobreak
endlocal
exit /b 0
