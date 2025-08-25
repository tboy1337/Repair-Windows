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
        echo Python is not installed or in PATH.
        timeout /t 5 /nobreak
        exit /b 1
    )
)

set TEMP_FILE=%TEMP%\installed_packages_%RANDOM%_%RANDOM%.txt

where %PYTHON_CMD% -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Pip is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Generating list of installed packages...
%PYTHON_CMD% -m pip freeze > %TEMP_FILE% >nul

echo Uninstalling all packages...
for /f "delims==" %%p in (%TEMP_FILE%) do (
    %PYTHON_CMD% -m pip uninstall -y %%p >nul 2>&1
)

del %TEMP_FILE% >nul 2>&1

echo Reinstalling default packages...
%PYTHON_CMD% -m pip install --upgrade pip >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to upgrade pip, trying to reinstall pip...
    %PYTHON_CMD% -m ensurepip --upgrade >nul 2>&1
    if %errorlevel% equ 0 (
        echo Successfully reinstalled pip, now trying to upgrade pip again...
        %PYTHON_CMD% -m pip install --upgrade pip >nul 2>&1
        if %errorlevel% neq 0 (
            echo Failed to upgrade pip again.  Error code: %errorlevel%
        )
    ) else (
        echo Failed to reinstall pip.  Error code: %errorlevel%
        timeout /t 5 /nobreak
        exit /b 1
    )
)

%PYTHON_CMD% -m pip install --upgrade setuptools >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to upgrade setuptools.  Error code: %errorlevel%
)

%PYTHON_CMD% -m pip install --upgrade wheel >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to upgrade wheel.  Error code: %errorlevel%
)

echo Purging pip cache...
%PYTHON_CMD% -m pip cache purge >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to purge pip cache.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
endlocal
exit /b 0
