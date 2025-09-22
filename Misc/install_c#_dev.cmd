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

where dotnet >nul 2>&1
if %errorlevel% neq 0 (
    echo .NET SDK not installed or not in PATH.
    echo Please install the .NET SDK.
    timeout /t 10 /nobreak
    exit /b 1
)

where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo winget is not available on this system. Please install App Installer from Microsoft Store.
    timeout /t 10 /nobreak
    exit /b 1
)

echo Starting C# Development Tools Installation...
echo.

REM .NET SDK and Runtime
echo Installing .NET SDK...
winget install --id Microsoft.DotNet.SDK.9 --silent --accept-package-agreements --accept-source-agreements

REM Package Management Tools
echo Installing NuGet CLI...
winget install --id Microsoft.NuGet --silent --accept-package-agreements --accept-source-agreements

REM Database Tools
echo Installing SQL Server LocalDB...
winget install --id Microsoft.SQLServerManagementStudio.21 --silent --accept-package-agreements --accept-source-agreements

REM Testing and Code Coverage
echo Installing ReportGenerator for code coverage...
dotnet tool install --global dotnet-reportgenerator-globaltool

REM Static Analysis
echo Installing SonarScanner for .NET...
dotnet tool install --global dotnet-sonarscanner

REM Entity Framework tools
echo Installing Entity Framework tools...
dotnet tool install --global dotnet-ef

REM Template management
echo Installing additional project templates...
dotnet new install Microsoft.DotNet.Web.Spa.ProjectTemplates.7.0
dotnet new install Microsoft.DotNet.Web.ProjectTemplates.9.0

timeout /t 10 /nobreak
exit /b 0
