@echo off

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

echo Setting registry keys on %SystemDrive%...
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Active Setup Temp Folders" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "BranchCache" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "D3D Shader Cache" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Delivery Optimization Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Device Driver Packages" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Device Driver Packages" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Diagnostic Data Viewer database files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Diagnostic Data Viewer database files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Downloaded Program Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Internet Cache Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Language Pack" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Language Pack" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Offline Pages Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Old ChkDsk Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Previous Installations" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Recycle Bin" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\RetailDemo Offline Content" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "RetailDemo Offline Content" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Service Pack Cleanup" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Setup Log Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "System error memory dump files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "System error minidump files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Temporary Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Temporary Setup Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Sync Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Temporary Sync Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Thumbnail Cache" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Update Cleanup" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Upgrade Discarded Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "User file versions" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Windows Defender" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Windows Error Reporting Files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Windows ESD installation files" registry key.  Error code: %errorlevel%
)

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files" /v StateFlags9999 /t REG_DWORD /d 00000002 /f >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to set "Windows Upgrade Log Files" registry key.  Error code: %errorlevel%
)

echo Freeing up space on all drives...
cleanmgr /sagerun:9999 >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to free up space on all drives.  Error code: %errorlevel%
)

echo Deleting all system temporary files...
del /q /f /s %temp%\* >nul 2>&1
for /d %%i in ("%temp%\*") do rd /s /q "%%i" >nul 2>&1

del /q /f /s %windir%\Temp\* >nul 2>&1
for /d %%i in ("%windir%\Temp\*") do rd /s /q "%%i" >nul 2>&1

del /q /f /s %windir%\Prefetch\* >nul 2>&1

echo Deleting all user temporary files...
for /d %%u in (%SystemDrive%\Users\*) do (
    if exist "%%u\AppData\Local\Temp" (
        rd /s /q "%%u\AppData\Local\Temp" >nul 2>&1
        if %errorlevel% neq 0 echo Failed to delete temp for %%u. Error code: %errorlevel%
        md "%%u\AppData\Local\Temp" >nul 2>&1
        if %errorlevel% neq 0 echo Failed to create temp for %%u. Error code: %errorlevel%
    )
)

timeout /t 10 /nobreak
exit /b 0
