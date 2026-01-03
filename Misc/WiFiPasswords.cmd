@echo off
setlocal enabledelayedexpansion

echo Retrieving saved WiFi networks...
echo.

REM Get all WiFi profiles
for /f "skip=9 tokens=1,* delims=:" %%i in ('netsh wlan show profiles') do (
    set "profile=%%j"
    set "profile=!profile:~1!"
    
    if not "!profile!"=="" (
        echo ----------------------------------------
        echo Network: !profile!
        echo ----------------------------------------
        
        REM Get password - process line by line with proper escaping
        set "found="
        for /f "delims=" %%a in ('netsh wlan show profile name^="!profile!" key^=clear ^| findstr /C:"Key Content"') do (
            set "line=%%a"
            REM Extract everything after "Key Content            : "
            set "line=!line:*Key Content            : =!"
            echo Password: !line!
            set "found=1"
        )
        
        if not defined found (
            echo Password: [Open Network / No Password]
        )
        
        echo.
    )
)

echo Scan complete!
echo.
pause
endlocal
exit /b 0
