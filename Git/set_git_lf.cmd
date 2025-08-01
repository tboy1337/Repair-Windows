@echo off
setlocal enabledelayedexpansion

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Setting Git configuration for LF line endings...
git config --global core.autocrlf false >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set Git configuration for LF line endings.  Error code: %errorlevel%
)

echo Setting Git configuration for explicit LF line endings...
git config --global core.eol lf >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set explicit LF line endings.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
endlocal
exit
