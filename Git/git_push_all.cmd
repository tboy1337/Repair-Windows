@echo off
setlocal enabledelayedexpansion

echo Running git commit and push on all repositories...
echo Using commit message: "YOUR_MESSAGE_HERE"
echo.

for /d %%D in (*) do (
    echo Checking directory: %%D
    if exist "%%D\.git" (
        echo Found Git repository in %%D, committing and pushing...
        pushd "%%D"
        git add .
        git commit -m "YOUR_MESSAGE_HERE"
        git push
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