@echo off
echo Restoring pip packages to default...

echo Generating list of installed packages...
pip freeze > installed_packages.txt

echo Uninstalling all packages...
for /f "delims==" %%p in (installed_packages.txt) do (
    pip uninstall -y %%p
)

echo Reinstalling default packages...
python -m ensurepip --upgrade
pip install --upgrade setuptools wheel

del installed_packages.txt

echo Done! Your pip packages have been restored to default.

timeout /t 5 /nobreak
exit
