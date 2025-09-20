@echo off
setlocal

set "TARGET_DRIVE=%SystemDrive%"
set "TEMP_FILE=%TEMP%\chkdsk_output_%RANDOM%_%RANDOM%.txt"

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 10 /nobreak
    exit /b 1
)

echo Scanning %TARGET_DRIVE% for errors...
chkdsk %TARGET_DRIVE% > "%TEMP_FILE%" 2>&1

findstr /c:"found no problems" "%TEMP_FILE%" >nul
if %errorlevel% equ 0 (
    del "%TEMP_FILE%" >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to delete temporary file %TEMP_FILE%.  Error code: %errorlevel%
    )
    echo No errors found on %TARGET_DRIVE%
    echo Error repair finished.
    timeout /t 10 /nobreak
    exit /b 0
)

del "%TEMP_FILE%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete temporary file: %TEMP_FILE%.  Error code: %errorlevel%
)

echo Errors found on %TARGET_DRIVE%, preparing to repair...

if /i "%TARGET_DRIVE%"=="%SystemDrive%" (
    echo y | chkdsk "%TARGET_DRIVE%" /F /X >nul 2>&1
    echo Restarting system to complete repairs, please save your work.
    timeout /t 30 /nobreak
    shutdown /r /t 1 >nul 2>&1
    exit /b 1
) else (
    chkdsk "%TARGET_DRIVE%" /F /X >nul 2>&1
)

echo Error repair finished.

timeout /t 10 /nobreak
endlocal
exit /b 1
