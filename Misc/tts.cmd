@echo off
setlocal

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

if "%~1"=="" (
    echo Usage: %~nx0 Your message here
    echo Example: %~nx0 Hello, this is a test message
    timeout /t 10 /nobreak
    exit /b 1
)

set "TTS_MESSAGE=%*"

powershell -NoProfile -Command "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak($env:TTS_MESSAGE)"
if %errorlevel% neq 0 (
    echo Failed to speak message.  Error code: %errorlevel%
    endlocal
    exit /b 1
)

endlocal
exit /b 0
