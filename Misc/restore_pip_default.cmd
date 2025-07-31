@echo off
setlocal enabledelayedexpansion

set TEMP_FILE=%TEMP%\installed_packages_%RANDOM%.txt

echo Restoring pip packages to default...

echo Generating list of installed packages...
py -m pip freeze > %TEMP_FILE%

echo Uninstalling all packages...
for /f "delims==" %%p in (%TEMP_FILE%) do (
    py -m pip uninstall -y %%p
)

echo Reinstalling default packages...
py -m ensurepip --upgrade
py -m pip install --upgrade setuptools wheel

del %TEMP_FILE%

echo Purging pip cache...
py -m pip cache purge

timeout /t 5 /nobreak
exit
