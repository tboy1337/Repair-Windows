@echo off

echo Updating all programs via winget...

winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: winget is not available or not installed on this system.
    echo Please install Windows App Installer from Microsoft Store.
    timeout /t 5 /nobreak
    exit /b 1
)

winget upgrade --all --accept-package-agreements --accept-source-agreements --silent >nul 2>&1

if %errorlevel% equ 0 (
    echo All updates completed successfully.
) else if %errorlevel% equ -1978335189 (
    echo No updates were available.
) else (
    echo Update process completed with some issues. Check output above.
)

timeout /t 5 /nobreak
exit /b 0
