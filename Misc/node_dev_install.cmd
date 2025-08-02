@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Node.js is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo npm is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Updating npm...
npm install -g npm@latest

echo Installing/updating global development tools...
npm install -g eslint
npm install -g prettier
npm install -g jest
npm install -g live-server

echo Clearing npm cache...
npm cache clean --force

timeout /t 5 /nobreak
endlocal
exit /b 0
