@echo off

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Setting Git configuration for LF line endings...
git config --global core.autocrlf false
if %errorlevel% neq 0 (
    echo Failed to set autocrlf to false.  Error code: %errorlevel%
)
    else (
        echo Autocrlf disabled successfully.
    )

git config --global core.eol lf
if %errorlevel% neq 0 (
    echo Failed to set Git configuration for LF line endings.  Error code: %errorlevel%
)
    else (
        echo Git configuration for LF line endings set successfully.
    )

timeout /t 5 /nobreak
exit
