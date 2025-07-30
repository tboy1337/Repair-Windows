@echo off

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Setting Git configuration for CRLF line endings...
git config --global core.autocrlf true
if %errorlevel% neq 0 (
    echo Failed to set Git configuration for CRLF line endings.  Error code: %errorlevel%
)
    else (
        echo Git configuration for CRLF line endings set successfully.
    )

git config --global core.eol crlf
if %errorlevel% neq 0 (
    echo Failed to set explicit CRLF line endings.  Error code: %errorlevel%
)
    else (
        echo Explicit CRLF line endings set successfully.
    )

timeout /t 5 /nobreak
exit
