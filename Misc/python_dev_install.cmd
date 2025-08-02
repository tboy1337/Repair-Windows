@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

set PYTHON_CMD=
py --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=py
) else (
    python --version >nul 2>&1
    if %errorlevel% equ 0 (
        set PYTHON_CMD=python
    ) else (
        echo Python is not installed or not in PATH.
        timeout /t 5 /nobreak
        exit /b 1
    )
)

where %PYTHON_CMD% -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Pip is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Starting Package Installation/Upgrade...
%PYTHON_CMD% -m pip install --upgrade pip
%PYTHON_CMD% -m pip install --upgrade setuptools
%PYTHON_CMD% -m pip install --upgrade wheel
%PYTHON_CMD% -m pip install --upgrade virtualenv
%PYTHON_CMD% -m pip install --upgrade python-dotenv
%PYTHON_CMD% -m pip install --upgrade pytest
%PYTHON_CMD% -m pip install --upgrade pytest-asyncio
%PYTHON_CMD% -m pip install --upgrade pytest-timeout
%PYTHON_CMD% -m pip install --upgrade pytest-mock
%PYTHON_CMD% -m pip install --upgrade pytest-cov
%PYTHON_CMD% -m pip install --upgrade pytest-xdist

echo Purging pip cache...
%PYTHON_CMD% -m pip cache purge

timeout /t 5 /nobreak
endlocal
exit /b 0
