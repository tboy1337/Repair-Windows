@echo off
setlocal enabledelayedexpansion

echo Running git pull on all repositories...
echo.

for /d %%D in (*) do (
    echo Checking directory: %%D
    if exist "%%D\.git" (
        echo Found Git repository in %%D, running git pull...
        pushd "%%D"
        git pull
        popd
        echo Finished %%D
        echo.
    ) else (
        echo No Git repository found in %%D, skipping...
        echo.
    )
)

echo All repositories processed!

timeout /t 5 /nobreak
exit
