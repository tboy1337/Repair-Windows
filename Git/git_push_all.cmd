@echo off
setlocal enabledelayedexpansion

echo Running git commit and push on all repositories...

set /p COMMIT_MSG="Enter commit message: "
if "%COMMIT_MSG%"=="" (
    echo Commit message cannot be empty.
    timeout /t 5 /nobreak
    exit /b 1
)

for /d %%D in (*) do (
    echo Checking directory: %%D
    if exist "%%D\.git" (
        echo Found Git repository in %%D, committing and pushing...
        pushd "%%D"
        git add .
        git commit -m "%COMMIT_MSG%"
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
