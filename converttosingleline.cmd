@echo off
setlocal enabledelayedexpansion

:: Check if a file is provided
if "%~1"=="" (
    echo Usage: %~nx0 [batchfile.bat/cmd]
    exit /b 1
)

:: Initialize the output line
set "output="

:: Read the input file line by line
for /f "tokens=*" %%a in (%1) do (
    set "line=%%a"
    
    :: Remove leading spaces
    for /f "tokens=*" %%b in ("!line!") do set "line=%%b"
    
    :: Skip empty lines and comments
    if not "!line!"=="" if not "!line:~0,1!"=="REM" (
        :: Escape special characters
        set "line=!line:&=^&!"
        set "line=!line:|=^|!"
        set "line=!line:<=^<!"
        set "line=!line:>=^>!"
        set "line=!line:^=^^!"
        set "line=!line:!=^!!"
        
        :: Append the line to the output
        if defined output (
            set "output=!output! && !line!"
        ) else (
            set "output=!line!"
        )
    )
)

:: Output the result
echo @echo off
echo %output%

timeout /t 5 /nobreak
exit
