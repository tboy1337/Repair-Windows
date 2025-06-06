@echo off
setlocal enabledelayedexpansion

echo Setting Git configuration for CRLF line endings...
git config --local core.autocrlf true
if %errorlevel% neq 0 (
    echo Failed to set Git configuration for CRLF line endings.
)
    else (
        echo Git configuration for CRLF line endings set successfully.
    )

timeout /t 5 /nobreak
exit 