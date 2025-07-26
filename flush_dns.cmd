@echo off
setlocal enabledelayedexpansion

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

echo Flushing DNS cache...
ipconfig /flushdns
if %errorlevel% equ 0 (
    echo DNS cache flushed successfully.
) else (
    echo Failed to flush DNS cache.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
exit /b 0
