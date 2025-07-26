@echo off

echo Setting Git configuration for LF line endings...
git config --global core.autocrlf false
if %errorlevel% neq 0 (
    echo Failed to set autocrlf to false.
)
    else (
        echo Autocrlf disabled successfully.
    )

git config --global core.eol lf
if %errorlevel% neq 0 (
    echo Failed to set Git configuration for LF line endings.
)
    else (
        echo Git configuration for LF line endings set successfully.
    )

timeout /t 5 /nobreak
exit
