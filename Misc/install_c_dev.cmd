@echo off

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% equ 0 (
    echo This script is intended to be run as a user. Please run without administrator privileges.
    timeout /t 10 /nobreak
    exit /b 1
)

where cl >nul 2>&1
if %errorlevel% neq 0 (
    echo Visual Studio compiler (cl) not installed or not in PATH.
    echo Please run from Visual Studio Developer Command Prompt or install Visual Studio.
    timeout /t 10 /nobreak
    exit /b 1
)

where vcpkg >nul 2>&1
if %errorlevel% neq 0 (
    echo vcpkg not installed or not in PATH. Please check or install vcpkg first.
    timeout /t 10 /nobreak
    exit /b 1
)

where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo winget is not available on this system. Please install App Installer from Microsoft Store.
    timeout /t 10 /nobreak
    exit /b 1
)

echo Starting C++ Development Tools Installation...
echo.

REM Static Analysis and Code Coverage Tools
echo Installing LLVM and OpenCppCoverage...
winget install --id LLVM.LLVM --silent --accept-package-agreements --accept-source-agreements
winget install --id OpenCppCoverage.OpenCppCoverage --silent --accept-package-agreements --accept-source-agreements

REM Package Manager & Build Tools
echo Installing vcpkg packages...
vcpkg install fmt:x64-windows
vcpkg install spdlog:x64-windows
vcpkg install nlohmann-json:x64-windows

REM Testing Framework
echo Installing Google Test...
vcpkg install gtest:x64-windows
vcpkg install gmock:x64-windows

REM Static Analysis
echo Installing Clang Static Analyzer tools...
vcpkg install llvm:x64-windows

REM Environment Management
echo Setting up CMake for project management...
vcpkg install cmake:x64-windows

REM Additional useful libraries
echo Installing additional development libraries...
vcpkg install catch2:x64-windows
vcpkg install benchmark:x64-windows
vcpkg install cpprestsdk:x64-windows

timeout /t 10 /nobreak
exit /b 0
