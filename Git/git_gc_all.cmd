@echo off
setlocal enabledelayedexpansion

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed or in PATH.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Running git garbage collection on all repositories...

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

timeout /t 5 /nobreak
endlocal
exit /b 0
