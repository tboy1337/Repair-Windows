@echo off
setlocal

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

:: Check if message was provided as parameter
if "%~1"=="" (
    echo Usage: %~nx0 "Your message here"
    echo Example: %~nx0 "Hello, this is a test message"
    timeout /t 10 /nobreak
    exit /b 1
)

:: Get the message from command line parameter
set "message=%~1"

:: Create temporary VBS script for TTS
set "tempvbs=%temp%\tts_temp_%RANDOM%_%RANDOM%.vbs"

:: Write VBS script content
echo Set objVoice = CreateObject("SAPI.SpVoice") > "%tempvbs%"
echo objVoice.Speak "%message%" >> "%tempvbs%"

:: Execute the VBS script
cscript //nologo "%tempvbs%"
if %errorlevel% neq 0 (
    echo Failed to speak message.  Error code: %errorlevel%
)

:: Clean up temporary file
del "%tempvbs%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete temporary file.  Error code: %errorlevel%
)

endlocal
exit /b 0
