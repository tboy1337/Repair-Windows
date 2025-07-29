@echo off

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
