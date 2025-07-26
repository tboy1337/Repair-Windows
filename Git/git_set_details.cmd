@echo off
setlocal enabledelayedexpansion

echo Setting global Git user name...
git config --global user.name "Your Name"
if %errorlevel% neq 0 (
    echo Failed to set global Git user name.
) else (
    echo Global Git user name set successfully.
)

echo Setting global Git user email...
git config --global user.email "your.email@example.com"
if %errorlevel% neq 0 (
    echo Failed to Set global Git user email.
) else (
    echo Global Git user email set successfully.
)

timeout /t 5 /nobreak
exit
