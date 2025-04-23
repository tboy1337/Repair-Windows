@echo off
setlocal enabledelayedexpansion

echo Running Git garbage collection on all repositories...
echo.

for /d %%D in (*) do (
    echo Checking directory: %%D
    if exist "%%D\.git" (
        echo Found Git repository in %%D, running git gc...
        pushd "%%D"
        git gc
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
