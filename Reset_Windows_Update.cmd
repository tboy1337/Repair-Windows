@echo off
setlocal enabledelayedexpansion

set "CHOSEN_DRIVE=%SystemDrive%"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

cd /d "%CHOSEN_DRIVE%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %CHOSEN_DRIVE%
)

echo Resetting Windows Update Components...
call net stop wuauserv
call net stop cryptSvc
call net stop bits
call net stop msiserver
call net stop appidsvc
call net stop RpcSs
call del "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\*.*" >nul 2>&1
call rmdir "%systemroot%\SoftwareDistribution" /S /Q >nul 2>&1
call rmdir "%systemroot%\system32\catroot2" /S /Q >nul 2>&1
call del /F /S /Q %systemroot%\WindowsUpdate.log
call net start appidsvc
call net start RpcSs
call net start wuauserv
call net start cryptSvc
call net start bits
call net start msiserver

call bitsadmin /reset /allusers

timeout /t 5 /nobreak

exit /b 0
