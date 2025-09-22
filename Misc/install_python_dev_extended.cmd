@echo off
setlocal

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% equ 0 (
    echo This script is intended to be run as a user. Please run without administrator privileges.
    timeout /t 10 /nobreak
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
        echo Python is not installed or in PATH.
        timeout /t 10 /nobreak
        exit /b 1
    )
)

where %PYTHON_CMD% -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Pip is not installed or in PATH.
    timeout /t 10 /nobreak
    exit /b 1
)

echo Starting Python Development Tools Installation and/or Upgrade...
%PYTHON_CMD% -m pip install --upgrade pip
%PYTHON_CMD% -m pip install --upgrade setuptools
%PYTHON_CMD% -m pip install --upgrade wheel
%PYTHON_CMD% -m pip install --upgrade virtualenv
%PYTHON_CMD% -m pip install --upgrade python-dotenv
%PYTHON_CMD% -m pip install --upgrade pylint
%PYTHON_CMD% -m pip install --upgrade mypy
%PYTHON_CMD% -m pip install --upgrade black
%PYTHON_CMD% -m pip install --upgrade isort
%PYTHON_CMD% -m pip install --upgrade autopep8
%PYTHON_CMD% -m pip install --upgrade pytest
%PYTHON_CMD% -m pip install --upgrade pytest-asyncio
%PYTHON_CMD% -m pip install --upgrade pytest-timeout
%PYTHON_CMD% -m pip install --upgrade pytest-mock
%PYTHON_CMD% -m pip install --upgrade pytest-cov
%PYTHON_CMD% -m pip install --upgrade pytest-xdist
%PYTHON_CMD% -m pip install --upgrade pytest-html
%PYTHON_CMD% -m pip install --upgrade pytest-json-report
%PYTHON_CMD% -m pip install --upgrade pytest-benchmark
%PYTHON_CMD% -m pip install --upgrade pytest-rerunfailures
%PYTHON_CMD% -m pip install --upgrade pytest-qt
%PYTHON_CMD% -m pip install --upgrade pytest-django
%PYTHON_CMD% -m pip install --upgrade pytest-flask
%PYTHON_CMD% -m pip install --upgrade pytest-postgresql
%PYTHON_CMD% -m pip install --upgrade pytest-mysql
%PYTHON_CMD% -m pip install --upgrade pytest-mongodb
%PYTHON_CMD% -m pip install --upgrade pytest-httpx
%PYTHON_CMD% -m pip install --upgrade pytest-responses
%PYTHON_CMD% -m pip install --upgrade pytest-vcr
%PYTHON_CMD% -m pip install --upgrade pytest-datadir
%PYTHON_CMD% -m pip install --upgrade pytest-subprocess
%PYTHON_CMD% -m pip install --upgrade pytest-socket
%PYTHON_CMD% -m pip install --upgrade pytest-celery
%PYTHON_CMD% -m pip install --upgrade pytest-redis
%PYTHON_CMD% -m pip install --upgrade pytest-elasticsearch
%PYTHON_CMD% -m pip install --upgrade pytest-twisted

echo Purging pip cache...
%PYTHON_CMD% -m pip cache purge

timeout /t 10 /nobreak
endlocal
exit /b 0
