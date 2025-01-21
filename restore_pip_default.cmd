@echo off

echo Restoring pip packages to default...

set TEMP_FILE=%TEMP%\installed_packages_%RANDOM%.txt

echo Generating list of installed packages...
pip freeze > %TEMP_FILE%

echo Uninstalling all packages...
for /f "delims==" %%p in (%TEMP_FILE%) do (
    pip uninstall -y %%p
)

echo Reinstalling default packages...
python -m ensurepip --upgrade
pip install --upgrade setuptools wheel

del %TEMP_FILE%

echo Purging pip cache...
pip cache purge

echo Done! Your pip packages have been restored to default.

timeout /t 5 /nobreak
exit
