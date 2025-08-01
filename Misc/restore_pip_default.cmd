@echo off
setlocal enabledelayedexpansion

set TEMP_FILE=%TEMP%\installed_packages_%RANDOM%.txt

echo Restoring pip packages to default...

echo Generating list of installed packages...
py -m pip freeze > %TEMP_FILE% >nul

echo Uninstalling all packages...
for /f "delims==" %%p in (%TEMP_FILE%) do (
    py -m pip uninstall -y %%p >nul 2>&1
)

echo Reinstalling default packages...
py -m ensurepip --upgrade >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to upgrade pip.  Error code: %errorlevel%
)

py -m pip install --upgrade setuptools wheel >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to upgrade setuptools and wheel.  Error code: %errorlevel%
)

del %TEMP_FILE%

echo Purging pip cache...
py -m pip cache purge >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to purge pip cache.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
exit
