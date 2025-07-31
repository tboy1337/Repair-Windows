@echo off
setlocal enabledelayedexpansion

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Setting global Git user details...

set /p USER_NAME="Enter Git user name: "
if "%USER_NAME%"=="" (
    echo User name cannot be empty.
    timeout /t 5 /nobreak
    exit /b 1
)

git config --global user.name "%USER_NAME%"
if %errorlevel% neq 0 (
    echo Failed to set global Git user name.  Error code: %errorlevel%
)

set /p USER_EMAIL="Enter Git user email: "
if "%USER_EMAIL%"=="" (
    echo User email cannot be empty.
    timeout /t 5 /nobreak
    exit /b 1
)

git config --global user.email "%USER_EMAIL%"
if %errorlevel% neq 0 (
    echo Failed to set global Git user email.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
exit
