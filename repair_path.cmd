@echo off
setlocal enabledelayedexpansion

echo +=========================+
echo + System PATH Repair Tool +
echo +=========================+
echo.

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Not running as Administrator
    echo Only user PATH will be modified
    echo Run as Administrator to repair system PATH
    echo.
    timeout /t 5 /nobreak
    set "ADMIN=0"
) else (
    set "ADMIN=1"
)

:: Generate timestamp using WMIC for better reliability
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set dt=%%I
if defined dt (
    set "TIMESTAMP=%dt:~0,8%_%dt:~8,6%"
) else (
    :: Fallback to DATE/TIME if WMIC fails
    set "TIMESTAMP=%DATE:~-4%%DATE:~-7,2%%DATE:~-10,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
    set "TIMESTAMP=!TIMESTAMP: =0!"
)

set "BACKUP_DIR=%USERPROFILE%\PATH_Backup"
set "BACKUP_FILE=%BACKUP_DIR%\PATH_backup_%TIMESTAMP%.txt"
set "TEMP_ENTRIES=%TEMP%\path_entries_%RANDOM%_%RANDOM%.tmp"
set "TEMP_SYSTEM_ENTRIES=%TEMP%\system_path_entries_%RANDOM%_%RANDOM%.tmp"

echo [1/6] Creating backup directory...
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo Failed to create backup directory.  Error code: !errorlevel!
        timeout /t 10 /nobreak
        exit /b 1
    )
)

echo [2/6] Backing up current PATH environment variables...
echo ===== PATH BACKUP %TIMESTAMP% ===== > "%BACKUP_FILE%"
echo. >> "%BACKUP_FILE%"
echo [USER PATH] >> "%BACKUP_FILE%"
reg query "HKCU\Environment" /v Path >> "%BACKUP_FILE%" 2>&1
echo. >> "%BACKUP_FILE%"
if "%ADMIN%"=="1" (
    echo [SYSTEM PATH] >> "%BACKUP_FILE%"
    reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path >> "%BACKUP_FILE%" 2>&1
)

echo Backup saved to: %BACKUP_FILE%
echo.

echo [3/6] Reading current PATH values...
for /f "skip=2 tokens=3*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    set "USER_PATH=%%a %%b"
)
if defined USER_PATH set "USER_PATH=!USER_PATH:~0,-1!"

if "%ADMIN%"=="1" (
    for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do (
        set "SYSTEM_PATH=%%a %%b"
    )
    if defined SYSTEM_PATH set "SYSTEM_PATH=!SYSTEM_PATH:~0,-1!"
)

echo.
echo [4/6] Cleaning USER PATH...
set "CLEAN_USER_PATH="
set "USER_ORIG_COUNT=0"
set "USER_DUPLICATES_REMOVED=0"
set "USER_INVALID_REMOVED=0"
set "USER_EMPTY_REMOVED=0"

if exist "%TEMP_ENTRIES%" del "%TEMP_ENTRIES%"

if defined USER_PATH (
    for %%p in ("%USER_PATH:;=";"%") do (
        set /a USER_ORIG_COUNT+=1
        set "ENTRY=%%~p"
        
        REM Remove quotes
        set "ENTRY=!ENTRY:"=!"
        
        REM Remove trailing backslash (unless it's a root path like C:\)
        if "!ENTRY:~-1!"=="\" (
            if not "!ENTRY:~-2,1!"==":" (
                set "ENTRY=!ENTRY:~0,-1!"
            )
        )
        
        REM Skip empty entries
        if not "!ENTRY!"=="" (
            set "IS_VALID=0"
            set "IS_DUPLICATE=0"
            
            REM Check if path contains environment variables
            echo !ENTRY! | findstr /i /c:"%%" >nul 2>&1
            if !errorlevel! equ 0 (
                REM Contains environment variable, keep it
                set "IS_VALID=1"
            ) else (
                REM Check if directory exists
                if exist "!ENTRY!\." (
                    set "IS_VALID=1"
                ) else (
                    echo   [INVALID] Removing: !ENTRY!
                    set /a USER_INVALID_REMOVED+=1
                )
            )
            
            REM Check for duplicates using exact matching
            if !IS_VALID! equ 1 (
                findstr /i /x /c:"!ENTRY!" "%TEMP_ENTRIES%" >nul 2>&1
                if !errorlevel! equ 0 (
                    echo   [DUPLICATE] Removing: !ENTRY!
                    set /a USER_DUPLICATES_REMOVED+=1
                    set "IS_DUPLICATE=1"
                ) else (
                    echo !ENTRY!>> "%TEMP_ENTRIES%"
                )
            )
            
            REM Add to clean path if valid and not duplicate
            if !IS_VALID! equ 1 (
                if !IS_DUPLICATE! equ 0 (
                    if "!CLEAN_USER_PATH!"=="" (
                        set "CLEAN_USER_PATH=!ENTRY!"
                    ) else (
                        set "CLEAN_USER_PATH=!CLEAN_USER_PATH!;!ENTRY!"
                    )
                )
            )
        ) else (
            set /a USER_EMPTY_REMOVED+=1
        )
    )
)

:: Calculate USER PATH statistics
set "USER_CLEAN_COUNT=0"
if defined CLEAN_USER_PATH (
    for %%p in ("%CLEAN_USER_PATH:;=";"%") do set /a USER_CLEAN_COUNT+=1
)

echo.
echo   Original entries: !USER_ORIG_COUNT!
echo   Cleaned entries: !USER_CLEAN_COUNT!
echo   Empty entries removed: !USER_EMPTY_REMOVED!
echo   Duplicates removed: !USER_DUPLICATES_REMOVED!
echo   Invalid paths removed: !USER_INVALID_REMOVED!
echo.

if "%ADMIN%"=="1" (
    echo [5/6] Cleaning SYSTEM PATH...
    set "CLEAN_SYSTEM_PATH="
    set "SYSTEM_ORIG_COUNT=0"
    set "SYSTEM_DUPLICATES_REMOVED=0"
    set "SYSTEM_INVALID_REMOVED=0"
    set "SYSTEM_EMPTY_REMOVED=0"
    
    if exist "%TEMP_SYSTEM_ENTRIES%" del "%TEMP_SYSTEM_ENTRIES%"
    
    if defined SYSTEM_PATH (
        for %%p in ("%SYSTEM_PATH:;=";"%") do (
            set /a SYSTEM_ORIG_COUNT+=1
            set "ENTRY=%%~p"
            
            REM Remove quotes
            set "ENTRY=!ENTRY:"=!"
            
            REM Remove trailing backslash (unless it's a root path like C:\)
            if "!ENTRY:~-1!"=="\" (
                if not "!ENTRY:~-2,1!"==":" (
                    set "ENTRY=!ENTRY:~0,-1!"
                )
            )
            
            REM Skip empty entries
            if not "!ENTRY!"=="" (
                set "IS_VALID=0"
                set "IS_DUPLICATE=0"
                
                REM Check if path contains environment variables
                echo !ENTRY! | findstr /i /c:"%%" >nul 2>&1
                if !errorlevel! equ 0 (
                    REM Contains environment variable, keep it
                    set "IS_VALID=1"
                ) else (
                    REM Check if directory exists
                    if exist "!ENTRY!\." (
                        set "IS_VALID=1"
                    ) else (
                        echo   [INVALID] Removing: !ENTRY!
                        set /a SYSTEM_INVALID_REMOVED+=1
                    )
                )
                
                REM Check for duplicates using exact matching
                if !IS_VALID! equ 1 (
                    findstr /i /x /c:"!ENTRY!" "%TEMP_SYSTEM_ENTRIES%" >nul 2>&1
                    if !errorlevel! equ 0 (
                        echo   [DUPLICATE] Removing: !ENTRY!
                        set /a SYSTEM_DUPLICATES_REMOVED+=1
                        set "IS_DUPLICATE=1"
                    ) else (
                        echo !ENTRY!>> "%TEMP_SYSTEM_ENTRIES%"
                    )
                )
                
                REM Add to clean path if valid and not duplicate
                if !IS_VALID! equ 1 (
                    if !IS_DUPLICATE! equ 0 (
                        if "!CLEAN_SYSTEM_PATH!"=="" (
                            set "CLEAN_SYSTEM_PATH=!ENTRY!"
                        ) else (
                            set "CLEAN_SYSTEM_PATH=!CLEAN_SYSTEM_PATH!;!ENTRY!"
                        )
                    )
                )
            ) else (
                set /a SYSTEM_EMPTY_REMOVED+=1
            )
        )
    )
    
    :: Calculate SYSTEM PATH statistics
    set "SYSTEM_CLEAN_COUNT=0"
    if defined CLEAN_SYSTEM_PATH (
        for %%p in ("%CLEAN_SYSTEM_PATH:;=";"%") do set /a SYSTEM_CLEAN_COUNT+=1
    )
    
    echo.
    echo   Original entries: !SYSTEM_ORIG_COUNT!
    echo   Cleaned entries: !SYSTEM_CLEAN_COUNT!
    echo   Empty entries removed: !SYSTEM_EMPTY_REMOVED!
    echo   Duplicates removed: !SYSTEM_DUPLICATES_REMOVED!
    echo   Invalid paths removed: !SYSTEM_INVALID_REMOVED!
    echo.
)

:: Calculate total changes
set /a USER_TOTAL_CHANGES=!USER_DUPLICATES_REMOVED!+!USER_INVALID_REMOVED!+!USER_EMPTY_REMOVED!
set /a SYSTEM_TOTAL_CHANGES=0
if "%ADMIN%"=="1" (
    set /a SYSTEM_TOTAL_CHANGES=!SYSTEM_DUPLICATES_REMOVED!+!SYSTEM_INVALID_REMOVED!+!SYSTEM_EMPTY_REMOVED!
)
set /a TOTAL_CHANGES=!USER_TOTAL_CHANGES!+!SYSTEM_TOTAL_CHANGES!

if !TOTAL_CHANGES! gtr 0 (
    echo [6/6] Applying changes...
    echo.
    
    :: Update USER PATH
    if !USER_TOTAL_CHANGES! gtr 0 (
        if defined CLEAN_USER_PATH (
            echo Updating USER PATH...
            setx PATH "!CLEAN_USER_PATH!" >nul 2>&1
            if !errorlevel! equ 0 (
                echo   USER PATH updated successfully
            ) else (
                echo   ERROR: Failed to update USER PATH
                echo   Check if PATH length exceeds Windows limits
            )
        ) else (
            echo   Warning: USER PATH is empty after cleaning. Skipping update.
        )
    ) else (
        echo USER PATH: No changes needed
    )
    
    :: Update SYSTEM PATH (admin only)
    if "%ADMIN%"=="1" (
        if !SYSTEM_TOTAL_CHANGES! gtr 0 (
            if defined CLEAN_SYSTEM_PATH (
                echo Updating SYSTEM PATH...
                setx PATH "!CLEAN_SYSTEM_PATH!" /M >nul 2>&1
                if !errorlevel! equ 0 (
                    echo   SYSTEM PATH updated successfully
                ) else (
                    echo   ERROR: Failed to update SYSTEM PATH
                    echo   Check if PATH length exceeds Windows limits
                )
            ) else (
                echo   Warning: SYSTEM PATH is empty after cleaning. Skipping update.
            )
        ) else (
            echo SYSTEM PATH: No changes needed
        )
    )
    
    echo.
    echo +=====================================+
    echo + PATH repair completed successfully! +
    echo +=====================================+
    echo.
    echo Total changes made: !TOTAL_CHANGES!
    echo Backup location: %BACKUP_DIR%
    echo.
    echo NOTE: You may need to restart applications
    echo or log out/in for changes to take effect.
) else (
    echo [6/6] Analysis complete
    echo.
    echo +==================================+
    echo + No issues found - PATH is clean! +
    echo +==================================+
    echo.
    echo Backup location: %BACKUP_DIR%
)

echo.

:: Cleanup temporary files
if exist "%TEMP_ENTRIES%" del "%TEMP_ENTRIES%"
if exist "%TEMP_SYSTEM_ENTRIES%" del "%TEMP_SYSTEM_ENTRIES%"

timeout /t 10 /nobreak
endlocal
exit /b 0
