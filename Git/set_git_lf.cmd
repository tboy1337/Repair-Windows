@echo off
setlocal enabledelayedexpansion

echo Setting Git configuration for LF line endings...
git config --local core.autocrlf false
if %errorlevel% neq 0 (
    echo Failed to disable CRLF line endings.
)

git config --local core.eol lf
if %errorlevel% neq 0 (
    echo Failed to set Git configuration for LF line endings.
)

timeout /t 5 /nobreak
exit 