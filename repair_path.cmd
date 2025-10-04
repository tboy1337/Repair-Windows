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

:: Check for /y flag (skip confirmation)
set "AUTO_CONFIRM=0"
if /i "%~1"=="/y" set "AUTO_CONFIRM=1"

:: Check admin rights
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

:: Generate timestamp using PowerShell with fallback
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd_HHmmss'" 2^>nul`) do set "TIMESTAMP=%%I"
if not defined TIMESTAMP (
    :: Improved fallback using WMIC for locale-independent timestamp
    for /f "skip=1 tokens=1" %%a in ('wmic os get localdatetime 2^>nul') do (
        set "dt=%%a"
        if defined dt goto :gottime
    )
    :gottime
    if defined dt (
        set "TIMESTAMP=!dt:~0,8!_!dt:~8,6!"
    ) else (
        :: Last resort: use simple counter
        set "TIMESTAMP=backup_%RANDOM%"
    )
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

:: Verify backup was created successfully
if exist "%BACKUP_FILE%" (
    echo Backup saved to: %BACKUP_FILE%
) else (
    echo ERROR: Failed to create backup file
    echo Cannot proceed without backup
    timeout /t 10 /nobreak
    exit /b 1
)
echo.

echo [3/6] Reading current PATH values...
set "USER_PATH="
for /f "skip=2 tokens=2,*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    if /i "%%a"=="REG_SZ" set "USER_PATH=%%b"
    if /i "%%a"=="REG_EXPAND_SZ" set "USER_PATH=%%b"
)
if not defined USER_PATH (
    echo   User PATH is not defined in registry
)

if "%ADMIN%"=="1" (
    set "SYSTEM_PATH="
    for /f "skip=2 tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do (
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
        
        REM Check for completely empty entry first (before any processing)
        if "!ENTRY!"=="" (
            set /a USER_EMPTY_REMOVED+=1
        ) else (
            REM Remove quotes
            set "ENTRY=!ENTRY:"=!"
            
            REM Remove trailing backslash (unless it's a root path)
            set "TEMP_LEN=0"
            call :GetLength "!ENTRY!" TEMP_LEN
            
            if !TEMP_LEN! gtr 3 (
                if "!ENTRY:~-1!"=="\" (
                    set "ENTRY=!ENTRY:~0,-1!"
                )
            )
            
            REM Check again after processing for empty entries
            if "!ENTRY!"=="" (
                set /a USER_EMPTY_REMOVED+=1
            ) else (
                set "IS_VALID=0"
                set "IS_DUPLICATE=0"
                
                REM Check if path contains environment variables
                echo !ENTRY! | findstr /i /c:"%%" >nul 2>&1
                if !errorlevel! equ 0 (
                    REM Contains environment variable, keep it
                    set "IS_VALID=1"
                ) else (
                    REM Check if directory exists
                    if exist "!ENTRY!\*" (
                        set "IS_VALID=1"
                    ) else if exist "!ENTRY!" (
                        REM Check if it's a file (some PATH entries point to files)
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
            )
        )
    )
)

:: Calculate USER PATH statistics
set "USER_CLEAN_COUNT=0"
if defined CLEAN_USER_PATH (
    for %%p in ("%CLEAN_USER_PATH:;=";"%") do set /a USER_CLEAN_COUNT+=1
)

:: Check USER PATH length
set "USER_PATH_LEN=0"
if defined CLEAN_USER_PATH (
    call :StrLen USER_PATH_LEN "!CLEAN_USER_PATH!"
)

echo.
echo   Original entries: !USER_ORIG_COUNT!
echo   Cleaned entries: !USER_CLEAN_COUNT!
echo   Empty entries removed: !USER_EMPTY_REMOVED!
echo   Duplicates removed: !USER_DUPLICATES_REMOVED!
echo   Invalid paths removed: !USER_INVALID_REMOVED!
if !USER_PATH_LEN! gtr 0 (
    echo   Path length: !USER_PATH_LEN! characters ^(limit: 2047^)
    if !USER_PATH_LEN! gtr 2047 (
        echo   WARNING: Path length EXCEEDS Windows limit!
    ) else if !USER_PATH_LEN! gtr 1800 (
        echo   WARNING: Path length is approaching the limit
    )
)
if !USER_CLEAN_COUNT! equ 0 (
    if !USER_ORIG_COUNT! gtr 0 (
        echo.
        echo   *** CRITICAL: All USER PATH entries are invalid! ***
        echo   *** PATH will be EMPTY after cleaning! ***
    )
)
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
            
            REM Check for completely empty entry first (before any processing)
            if "!ENTRY!"=="" (
                set /a SYSTEM_EMPTY_REMOVED+=1
            ) else (
                REM Remove quotes
                set "ENTRY=!ENTRY:"=!"
                
                REM Remove trailing backslash (unless it's a root path)
                set "TEMP_LEN=0"
                call :GetLength "!ENTRY!" TEMP_LEN
                
                if !TEMP_LEN! gtr 3 (
                    if "!ENTRY:~-1!"=="\" (
                        set "ENTRY=!ENTRY:~0,-1!"
                    )
                )
                
                REM Check again after processing for empty entries
                if "!ENTRY!"=="" (
                    set /a SYSTEM_EMPTY_REMOVED+=1
                ) else (
                    set "IS_VALID=0"
                    set "IS_DUPLICATE=0"
                    
                    REM Check if path contains environment variables
                    echo !ENTRY! | findstr /i /c:"%%" >nul 2>&1
                    if !errorlevel! equ 0 (
                        REM Contains environment variable, keep it
                        set "IS_VALID=1"
                    ) else (
                        REM Check if directory exists
                        if exist "!ENTRY!\*" (
                            set "IS_VALID=1"
                        ) else if exist "!ENTRY!" (
                            REM Check if it's a file (some PATH entries point to files)
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
                )
            )
        )
    )
    
    :: Calculate SYSTEM PATH statistics
    set "SYSTEM_CLEAN_COUNT=0"
    if defined CLEAN_SYSTEM_PATH (
        for %%p in ("%CLEAN_SYSTEM_PATH:;=";"%") do set /a SYSTEM_CLEAN_COUNT+=1
    )
    
    :: Check SYSTEM PATH length
    set "SYSTEM_PATH_LEN=0"
    if defined CLEAN_SYSTEM_PATH (
        call :StrLen SYSTEM_PATH_LEN "!CLEAN_SYSTEM_PATH!"
    )
    
    echo.
    echo   Original entries: !SYSTEM_ORIG_COUNT!
    echo   Cleaned entries: !SYSTEM_CLEAN_COUNT!
    echo   Empty entries removed: !SYSTEM_EMPTY_REMOVED!
    echo   Duplicates removed: !SYSTEM_DUPLICATES_REMOVED!
    echo   Invalid paths removed: !SYSTEM_INVALID_REMOVED!
    if !SYSTEM_PATH_LEN! gtr 0 (
        echo   Path length: !SYSTEM_PATH_LEN! characters ^(limit: 8191^)
        if !SYSTEM_PATH_LEN! gtr 8191 (
            echo   WARNING: Path length EXCEEDS Windows limit!
        ) else if !SYSTEM_PATH_LEN! gtr 7500 (
            echo   WARNING: Path length is approaching the limit
        )
    )
    if !SYSTEM_CLEAN_COUNT! equ 0 (
        if !SYSTEM_ORIG_COUNT! gtr 0 (
            echo.
            echo   *** CRITICAL: All SYSTEM PATH entries are invalid! ***
            echo   *** PATH will be EMPTY after cleaning! ***
        )
    )
    echo.
) else (
    echo [5/6] Skipping SYSTEM PATH (requires Administrator privileges)...
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
    echo WARNING: About to modify PATH environment variables
    if "%AUTO_CONFIRM%"=="1" (
        echo Auto-confirm mode enabled, proceeding...
    ) else (
        echo Press Ctrl+C to cancel or
        pause
    )
    echo.
    
    :: Update USER PATH
    if !USER_TOTAL_CHANGES! gtr 0 (
        if defined CLEAN_USER_PATH (
            :: Check PATH length
            if !USER_PATH_LEN! gtr 2047 (
                echo   ERROR: USER PATH length (!USER_PATH_LEN! chars^) exceeds Windows limit ^(2047 chars^)
                echo   Please remove more paths manually or use shorter path names
            ) else (
                echo Updating USER PATH via registry...
                reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!CLEAN_USER_PATH!" /f >nul 2>&1
                if !errorlevel! equ 0 (
                    echo   USER PATH updated successfully
                ) else (
                    echo   ERROR: Failed to update USER PATH ^(Error code: !errorlevel!^)
                    echo   You can restore from backup: %BACKUP_FILE%
                )
            )
        ) else (
            echo   ERROR: USER PATH would be EMPTY after cleaning!
            echo   Skipping update to prevent loss of all paths.
            echo   Please manually review your PATH entries.
            echo   Backup available at: %BACKUP_FILE%
        )
    ) else (
        echo USER PATH: No changes needed
    )
    
    :: Update SYSTEM PATH (admin only)
    if "%ADMIN%"=="1" (
        if !SYSTEM_TOTAL_CHANGES! gtr 0 (
            if defined CLEAN_SYSTEM_PATH (
                :: Check PATH length
                if !SYSTEM_PATH_LEN! gtr 8191 (
                    echo   ERROR: SYSTEM PATH length (!SYSTEM_PATH_LEN! chars^) exceeds Windows limit ^(8191 chars^)
                    echo   Please remove more paths manually or use shorter path names
                ) else (
                    echo Updating SYSTEM PATH via registry...
                    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "!CLEAN_SYSTEM_PATH!" /f >nul 2>&1
                    if !errorlevel! equ 0 (
                        echo   SYSTEM PATH updated successfully
                    ) else (
                        echo   ERROR: Failed to update SYSTEM PATH ^(Error code: !errorlevel!^)
                        echo   You can restore from backup: %BACKUP_FILE%
                    )
                )
            ) else (
                echo   ERROR: SYSTEM PATH would be EMPTY after cleaning!
                echo   Skipping update to prevent loss of all paths.
                echo   Please manually review your PATH entries.
                echo   Backup available at: %BACKUP_FILE%
            )
        ) else (
            echo SYSTEM PATH: No changes needed
        )
    )
    
    echo.
    echo Broadcasting environment change notification...
    :: Use simpler PowerShell approach for WM_SETTINGCHANGE with error handling
    powershell -NoProfile -WindowStyle Hidden -Command "try { $signature = '[DllImport(\"user32.dll\", SetLastError = true, CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);'; $type = Add-Type -MemberDefinition $signature -Name 'Win32' -Namespace 'NativeMethods' -PassThru -ErrorAction Stop; $result = [UIntPtr]::Zero; $type::SendMessageTimeout(0xffff, 0x1a, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result) | Out-Null; exit 0 } catch { exit 1 }" 2>nul
    if !errorlevel! equ 0 (
        echo   System notified successfully
    ) else (
        echo   Warning: Failed to broadcast change notification
        echo   You may need to log off and back on for changes to take full effect
    )
    
    echo.
    echo +=====================================+
    echo + PATH repair completed successfully! +
    echo +=====================================+
    echo.
    echo Total changes made: !TOTAL_CHANGES!
    echo Backup location: %BACKUP_DIR%
    echo.
    echo NOTE: New command prompts will use the updated PATH.
    echo Some applications may need to be restarted to see changes.
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
echo Usage: %~nx0 [/y]
echo   /y  Skip confirmation prompt ^(auto-confirm changes^)

:: Cleanup temporary files
if exist "%TEMP_ENTRIES%" del "%TEMP_ENTRIES%"
if exist "%TEMP_SYSTEM_ENTRIES%" del "%TEMP_SYSTEM_ENTRIES%"

timeout /t 10 /nobreak
endlocal
exit /b 0

:GetLength
:: Simple helper to get string length for root path check
setlocal enabledelayedexpansion
set "str=%~1"
set "len=0"
:GetLength_Loop
if "!str:~%len%,1!" neq "" (
    set /a len+=1
    goto :GetLength_Loop
)
endlocal & set "%~2=%len%"
exit /b

:StrLen
:: Subroutine to calculate string length using binary search method
:: Usage: call :StrLen result_var "string"
:: This is much faster than character-by-character iteration
setlocal enabledelayedexpansion
set "str=%~2"
set "len=0"
if defined str (
    :: Use binary search to find length efficiently
    :: This handles strings up to 8192 characters (2^13)
    for /l %%i in (12,-1,0) do (
        set /a "pow=1<<%%i"
        for %%p in (!pow!) do (
            if "!str:~%%p,1!" neq "" (
                set /a "len+=%%p"
                set "str=!str:~%%p!"
            )
        )
    )
    :: Check if there's one remaining character
    if "!str!" neq "" set /a len+=1
)
endlocal & set "%~1=%len%"
exit /b
