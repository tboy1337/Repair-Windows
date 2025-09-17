@echo off
setlocal

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 10 /nobreak
    exit /b 1
)

echo Detecting available certificate stores...
echo.

set "STORE_MY=0"
set "STORE_ROOT=0"
set "STORE_CA=0"
set "STORE_AUTHROOT=0"
set "STORE_DISALLOWED=0"
set "STORE_TRUSTEDPUBLISHER=0"
set "DETECTION_FAILED=0"

rem Run certutil -store and parse output to detect available stores
for /f "tokens=1 delims= " %%a in ('certutil -store 2^>nul ^| findstr /r "^[A-Za-z]"') do (
    if /i "%%a"=="My" set "STORE_MY=1"
    if /i "%%a"=="Root" set "STORE_ROOT=1"
    if /i "%%a"=="CA" set "STORE_CA=1"
    if /i "%%a"=="AuthRoot" set "STORE_AUTHROOT=1"
    if /i "%%a"=="Disallowed" set "STORE_DISALLOWED=1"
    if /i "%%a"=="TrustedPublisher" set "STORE_TRUSTEDPUBLISHER=1"
)

rem Check if certutil -store command failed
certutil -store >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Failed to detect certificate stores. Using fallback behavior.
    set "DETECTION_FAILED=1"
    set "STORE_MY=1"
    set "STORE_ROOT=1"
    set "STORE_CA=1"
    set "STORE_AUTHROOT=1"
    set "STORE_DISALLOWED=1"
    set "STORE_TRUSTEDPUBLISHER=1"
) else (
    echo Detected stores - My:%STORE_MY% Root:%STORE_ROOT% CA:%STORE_CA% AuthRoot:%STORE_AUTHROOT% Disallowed:%STORE_DISALLOWED% TrustedPublisher:%STORE_TRUSTEDPUBLISHER%
)
echo.

echo Starting certificate repairs...
echo.

echo Flushing certificate and cryptographic caches...
certutil -flushcache >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Failed to flush certificate caches.  Error code: %errorlevel%
)

echo Synchronizing with Windows Update for certificate updates...
certutil -syncWithWU >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Failed to sync with Windows Update.  Error code: %errorlevel%
)

echo Verifying AuthRoot certificates...
certutil -verifyCTL AuthRootWU >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: AuthRoot certificate verification issues detected.  Error code: %errorlevel%
)

echo Verifying Disallowed certificates...
certutil -verifyCTL DisallowedCertWU >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Disallowed certificate verification issues detected.  Error code: %errorlevel%
)
echo.

echo Repairing certificate stores and key associations...
echo.

if %STORE_MY%==1 (
    echo Repairing Local Machine Personal store...
    certutil -repairstore My >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/repair Local Machine Personal store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Local Machine Personal store ^(not detected^)
)

if %STORE_ROOT%==1 (
    echo Repairing Local Machine Root store...
    certutil -repairstore Root >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/repair Local Machine Root store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Local Machine Root store ^(not detected^)
)

if %STORE_CA%==1 (
    echo Repairing Local Machine CA store...
    certutil -repairstore CA >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/repair Local Machine CA store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Local Machine CA store ^(not detected^)
)

if %STORE_AUTHROOT%==1 (
    echo Repairing Local Machine AuthRoot store...
    certutil -repairstore AuthRoot >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/repair Local Machine AuthRoot store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Local Machine AuthRoot store ^(not detected^)
)

if %STORE_DISALLOWED%==1 (
    echo Repairing Local Machine Disallowed store...
    certutil -repairstore Disallowed >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/repair Local Machine Disallowed store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Local Machine Disallowed store ^(not detected^)
)

if %STORE_TRUSTEDPUBLISHER%==1 (
    echo Repairing Trust Publishers store...
    certutil -repairstore TrustedPublisher >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/repair Trusted Publishers store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Trusted Publishers store ^(not detected^)
)
echo.

echo Verifying certificate stores after repair...
echo.

if %STORE_MY%==1 (
    echo Verifying Local Machine Personal store...
    certutil -verifystore My >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/verify Local Machine Personal store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Local Machine Personal store verification ^(not detected^)
)

if %STORE_ROOT%==1 (
    echo Verifying Local Machine Root store...
    certutil -verifystore Root >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/verify Local Machine Root store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Local Machine Root store verification ^(not detected^)
)

if %STORE_CA%==1 (
    echo Verifying Local Machine CA store...
    certutil -verifystore CA >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/verify Local Machine CA store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Local Machine CA store verification ^(not detected^)
)

if %STORE_TRUSTEDPUBLISHER%==1 (
    echo Verifying Trust Publishers store...
    certutil -verifystore TrustedPublisher >nul 2>&1
    if %errorlevel% neq 0 (
        echo Warning: Failed to find/verify Trusted Publishers store.  Error code: %errorlevel%
    )
) else (
    echo Skipping Trusted Publishers store verification ^(not detected^)
)

echo Regenerating certificate trust lists...
certutil -generateSSTFromWU >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Failed to regenerate certificate trust lists.  Error code: %errorlevel%
)

echo Clearing certificate-related URL cache...
certutil -URLCache * delete >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Failed to clear URL cache.  Error code: %errorlevel%
)

echo Clearing policy cache...
certutil -PolicyCache * delete >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Failed to clear policy cache.  Error code: %errorlevel%
)

echo Final cache flush...
certutil -flushcache >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Failed final cache flush.  Error code: %errorlevel%
)
echo.

echo Certificate repair operations completed.
echo It is recommended to restart your computer to ensure all changes take effect.
echo.

timeout /t 10 /nobreak
endlocal
exit /b 0
