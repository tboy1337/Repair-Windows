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

echo.
echo Optimizing NTFS behavior settings.
echo These changes require a system reboot to take effect.
echo.

echo Setting NTFS memory usage:
echo   0: Resets NTFS memory usage to the system default value.
echo   1: Sets to the standard/default memory allocation for NTFS caching and operations (recommended for typical desktops and systems with standard workloads^).
echo   2: Increases the memory allocation for NTFS, allowing larger in-memory caches for improved performance (best for systems with 16GB+ RAM and heavy file I/O^).
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
echo   1: ~12.5%% of volume (default, suitable for most users^).
echo   2: ~25%% of volume (good for volumes with moderate file counts^).
echo   3: ~37.5%% of volume (for high file-count scenarios, e.g., servers^).
echo   4: ~50%% of volume (maximum reservation, use only if MFT fragmentation is a severe issue; reduces available space^).
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

timeout /t 5 /nobreak
endlocal
exit /b 0
