@echo off
setlocal enabledelayedexpansion

set PYTHON_CMD=
py --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=py
) else (
    python --version >nul 2>&1
    if %errorlevel% equ 0 (
        set PYTHON_CMD=python
    ) else (
        echo ERROR: Python is not installed or not in PATH
        echo Please install Python first and ensure it's added to your system PATH
        pause
        exit /b 1
    )
)

set TEMP_FILE=%TEMP%\installed_packages_%RANDOM%_%RANDOM%.txt

echo Generating list of installed packages...
%PYTHON_CMD% -m pip freeze > %TEMP_FILE% >nul

echo Uninstalling all packages...
for /f "delims==" %%p in (%TEMP_FILE%) do (
    %PYTHON_CMD% -m pip uninstall -y %%p >nul 2>&1
)

echo Reinstalling default packages...
%PYTHON_CMD% -m pip install --upgrade pip >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to upgrade pip.  Error code: %errorlevel%
)

%PYTHON_CMD% -m pip install --upgrade setuptools >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to upgrade setuptools.  Error code: %errorlevel%
)

%PYTHON_CMD% -m pip install --upgrade wheel >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to upgrade wheel.  Error code: %errorlevel%
)

del %TEMP_FILE% >nul 2>&1

echo Purging pip cache...
%PYTHON_CMD% -m pip cache purge >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to purge pip cache.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
exit /b 0
