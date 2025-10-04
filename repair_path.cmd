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

:: Generate timestamp using PowerShell
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd_HHmmss'" 2^>nul`) do set "TIMESTAMP=%%I"
if not defined TIMESTAMP (
    :: Fallback to DATE/TIME if PowerShell fails
    set "TIMESTAMP=%DATE:~-4%%DATE:~-7,2%%DATE:~-10,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
    set "TIMESTAMP=!TIMESTAMP: =0!"
)

set "BACKUP_DIR=%USERPROFILE%\PATH_Backup"
set "BACKUP_FILE=%BACKUP_DIR%\PATH_backup_%TIMESTAMP%.txt"
set "TEMP_ENTRIES=%TEMP%\path_entries_%RANDOM%_%RANDOM%.tmp"
set "TEMP_SYSTEM_ENTRIES=%TEMP%\system_path_entries_%RANDOM%_%RANDOM%.tmp"

:: Verify TEMP directory is accessible
if not exist "%TEMP%\" (
    echo ERROR: TEMP directory is not accessible
    timeout /t 10 /nobreak
    exit /b 1
)

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

if exist "%BACKUP_FILE%" (
    echo Backup saved to: %BACKUP_FILE%
) else (
    echo WARNING: Failed to create backup file
    timeout /t 5 /nobreak
)
echo.

echo [3/6] Reading current PATH values...
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    if /i "%%a"=="REG_SZ" set "USER_PATH=%%b"
    if /i "%%a"=="REG_EXPAND_SZ" set "USER_PATH=%%b"
)
if not defined USER_PATH (
    echo   User PATH is not defined in registry
)

if "%ADMIN%"=="1" (
    for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do (
        if /i "%%a"=="REG_SZ" set "SYSTEM_PATH=%%b"
        if /i "%%a"=="REG_EXPAND_SZ" set "SYSTEM_PATH=%%b"
    )
    if not defined SYSTEM_PATH (
        echo   System PATH is not defined in registry ^(this should not happen^)
    )
)

echo.
echo [4/6] Cleaning USER PATH...
set "CLEAN_USER_PATH="
set "USER_ORIG_COUNT=0"
set "USER_DUPLICATES_REMOVED=0"
set "USER_INVALID_REMOVED=0"
set "USER_EMPTY_REMOVED=0"

if exist "%TEMP_ENTRIES%" del "%TEMP_ENTRIES%"
type nul > "%TEMP_ENTRIES%"

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
    type nul > "%TEMP_SYSTEM_ENTRIES%"
    
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
            :: Check PATH length (setx has a limit of 1024 characters, registry allows up to 2047)
            call :StrLen USER_PATH_LEN "!CLEAN_USER_PATH!"
            if !USER_PATH_LEN! gtr 2047 (
                echo   ERROR: USER PATH length (!USER_PATH_LEN! chars) exceeds Windows limit (2047 chars)
                echo   Please remove more paths manually or use shorter path names
            ) else if !USER_PATH_LEN! gtr 1024 (
                echo   WARNING: USER PATH length (!USER_PATH_LEN! chars) exceeds setx limit (1024 chars)
                echo   Attempting registry update instead...
                reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!CLEAN_USER_PATH!" /f >nul 2>&1
                if !errorlevel! equ 0 (
                    echo   USER PATH updated successfully via registry
                ) else (
                    echo   ERROR: Failed to update USER PATH
                )
            ) else (
                echo Updating USER PATH...
                setx PATH "!CLEAN_USER_PATH!" >nul 2>&1
                if !errorlevel! equ 0 (
                    echo   USER PATH updated successfully
                ) else (
                    echo   ERROR: Failed to update USER PATH
                )
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
                :: Check PATH length (registry allows up to 8191 characters for system PATH)
                call :StrLen SYSTEM_PATH_LEN "!CLEAN_SYSTEM_PATH!"
                if !SYSTEM_PATH_LEN! gtr 8191 (
                    echo   ERROR: SYSTEM PATH length (!SYSTEM_PATH_LEN! chars) exceeds Windows limit (8191 chars)
                    echo   Please remove more paths manually or use shorter path names
                ) else if !SYSTEM_PATH_LEN! gtr 1024 (
                    echo   WARNING: SYSTEM PATH length (!SYSTEM_PATH_LEN! chars) exceeds setx limit (1024 chars)
                    echo   Attempting registry update instead...
                    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "!CLEAN_SYSTEM_PATH!" /f >nul 2>&1
                    if !errorlevel! equ 0 (
                        echo   SYSTEM PATH updated successfully via registry
                    ) else (
                        echo   ERROR: Failed to update SYSTEM PATH
                    )
                ) else (
                    echo Updating SYSTEM PATH...
                    setx PATH "!CLEAN_SYSTEM_PATH!" /M >nul 2>&1
                    if !errorlevel! equ 0 (
                        echo   SYSTEM PATH updated successfully
                    ) else (
                        echo   ERROR: Failed to update SYSTEM PATH
                    )
                )
            ) else (
                echo   Warning: SYSTEM PATH is empty after cleaning. Skipping update.
            )
        ) else (
            echo SYSTEM PATH: No changes needed
        )
    )
    
    echo.
    echo Notifying system of environment changes...
    :: Broadcast WM_SETTINGCHANGE to notify applications of environment changes
    powershell -NoProfile -Command "Add-Type -TypeDefinition @\"[DllImport(\\\"user32.dll\\\", SetLastError = true, CharSet = CharSet.Auto)]public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);\"@ -Name NativeMethods -Namespace Win32; [UIntPtr]$result = 0; [Win32.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x1a, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result) | Out-Null" 2>nul
    
    echo.
    echo +=====================================+
    echo + PATH repair completed successfully! +
    echo +=====================================+
    echo.
    echo Total changes made: !TOTAL_CHANGES!
    echo Backup location: %BACKUP_DIR%
    echo.
    echo NOTE: Running applications have been notified.
    echo New command prompts will use the updated PATH.
    echo Some applications may still need to be restarted.
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

:StrLen
:: Subroutine to calculate string length
:: Usage: call :StrLen result_var "string"
setlocal enabledelayedexpansion
set "str=%~2"
set "len=0"
if defined str (
    for /l %%i in (0,1,8191) do (
        if not "!str:~%%i,1!"=="" set /a len+=1
    )
)
endlocal & set "%~1=%len%"
exit /b
