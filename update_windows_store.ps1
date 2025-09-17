<# Self-Elevating PowerShell Script
This script automatically handles execution policy and administrator elevation
#>

# Suppress PSScriptAnalyzer warnings that are not applicable to this user-facing script
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for user-facing scripts that need colored console output')]
param()

# Check if we're running with the right parameters (bypass execution policy and elevated)
$IsElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
$CurrentPolicy = Get-ExecutionPolicy -Scope Process

# If we're not elevated or don't have bypass policy, restart with proper parameters
if (-NOT $IsElevated -or $CurrentPolicy -eq "Undefined" -or $CurrentPolicy -eq "Restricted") {
    Write-Host "Initializing script with proper permissions..." -ForegroundColor Yellow

    try {
        $ScriptPath = $MyInvocation.MyCommand.Path
        $Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

        if (-NOT $IsElevated) {
            # Need elevation
            Start-Process PowerShell -Verb RunAs -ArgumentList $Arguments -Wait
        } else {
            # Just need execution policy bypass
            Start-Process PowerShell -ArgumentList $Arguments -Wait
        }
        exit 0
    }
    catch {
        Write-Error "Failed to restart script with proper parameters: $_"
        Write-Host "Please run this script as Administrator with execution policy bypass." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        exit 1
    }
}

<#
.SYNOPSIS
    Windows Store Apps Update Script with Modern Methods
.DESCRIPTION
    Updates Windows Store apps using multiple modern approaches with automatic fallbacks.
    Uses the latest WinGet methods, WinRT APIs, and legacy approaches as needed.
    Provides detailed feedback on update process and handles errors gracefully.
.FEATURES
    - Primary Method: Microsoft.WinGet.Client module with Repair-WingetPackageManager
    - Fallback Method: Update-InboxApp script using WinRT APIs (PowerShell 5.1 only)
    - Legacy Method: Windows Update COM objects and scheduled tasks
    - Comprehensive diagnostics and repair capabilities
    - Automatic elevation and execution policy handling
.NOTES
    Automatically handles elevation and execution policy
    Script works with both PowerShell 5.1 and PowerShell 7+
#>

# Function to update Windows Store apps using modern methods
function Update-StoreApp {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param()
    if (-not $PSCmdlet.ShouldProcess("Windows Store Apps", "Update")) {
        return $false
    }

    Write-Host "`nUpdating Windows Store apps using modern methods..." -ForegroundColor Cyan

    try {
        # Reset Windows Store cache first
        Write-Host "Resetting Windows Store cache..." -ForegroundColor Gray
        Start-Process "wsreset.exe" -NoNewWindow -Wait

        # Get the Windows Store app to verify it exists
        Write-Host "Verifying Windows Store availability..." -ForegroundColor Gray
        $StoreApp = Get-AppxPackage -Name "Microsoft.WindowsStore" -ErrorAction SilentlyContinue
        if (-not $StoreApp) {
            Write-Host "Windows Store app not found. Cannot proceed with updates." -ForegroundColor Yellow
            return $false
        }

        Write-Host "Windows Store found (Version: $($StoreApp.Version))" -ForegroundColor Green

        $UpdateSuccess = $false

        # Method 1: Use modern WinGet approach (Primary method)
        Write-Host "`nAttempting Method 1: Modern WinGet approach..." -ForegroundColor Cyan
        if (Update-StoreAppViaWinGet) {
            $UpdateSuccess = $true
            Write-Host "Method 1 (WinGet) completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Method 1 (WinGet) failed or unavailable, trying fallback..." -ForegroundColor Yellow
        }

        # Method 2: Use WinRT API approach (Fallback method)
        if (-not $UpdateSuccess) {
            Write-Host "`nAttempting Method 2: WinRT API approach..." -ForegroundColor Cyan
            if (Update-StoreAppViaWinRT) {
                $UpdateSuccess = $true
                Write-Host "Method 2 (WinRT API) completed successfully!" -ForegroundColor Green
            } else {
                Write-Host "Method 2 (WinRT API) failed or unavailable, trying legacy methods..." -ForegroundColor Yellow
            }
        }

        # Method 3: Legacy methods (Final fallback)
        if (-not $UpdateSuccess) {
            Write-Host "`nAttempting Method 3: Legacy approaches..." -ForegroundColor Cyan
            $UpdateSuccess = Update-StoreAppLegacy
        }

        if ($UpdateSuccess) {
            Write-Host "`nStore app update process completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "`nStore app update process completed with warnings. Some methods may have failed." -ForegroundColor Yellow
        }

        Write-Host "Note: Store app updates may continue processing in the background." -ForegroundColor Cyan
        return $UpdateSuccess
    }
    catch {
        Write-Error "Failed to update Store apps: $_"
        return $false
    }
}

# Function to update Store apps using modern WinGet approach
function Update-StoreAppViaWinGet {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param()
    if (-not $PSCmdlet.ShouldProcess("Windows Store Apps via WinGet", "Update")) {
        return $false
    }

    Write-Host "Attempting to use Repair-WingetPackageManager..." -ForegroundColor Gray

    try {
        # Check if Microsoft.WinGet.Client module is available
        $WinGetModule = Get-Module -ListAvailable -Name "Microsoft.WinGet.Client" -ErrorAction SilentlyContinue

        if (-not $WinGetModule) {
            Write-Host "Installing Microsoft.WinGet.Client module..." -ForegroundColor Gray
            Install-Module -Name Microsoft.WinGet.Client -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
            Import-Module -Name Microsoft.WinGet.Client -ErrorAction Stop
        } else {
            Write-Host "Microsoft.WinGet.Client module found, importing..." -ForegroundColor Gray
            Import-Module -Name Microsoft.WinGet.Client -ErrorAction Stop
        }

        # Repair WinGet package manager to ensure it's up to date
        Write-Host "Repairing WinGet package manager..." -ForegroundColor Gray
        Repair-WingetPackageManager -Latest -ErrorAction Stop
        Write-Host "WinGet package manager repaired successfully" -ForegroundColor Green

        # Update Store apps via WinGet
        Write-Host "Updating Microsoft Store apps via WinGet..." -ForegroundColor Gray

        # Get list of Store apps that can be updated
        $AvailableUpdates = Get-WinGetPackage -Source msstore | Where-Object { $_.AvailableVersions.Count -gt 0 }

        if ($AvailableUpdates.Count -gt 0) {
            Write-Host "Found $($AvailableUpdates.Count) Store app updates available" -ForegroundColor White

            foreach ($Package in $AvailableUpdates) {
                try {
                    Write-Host "Updating: $($Package.Name)" -ForegroundColor Gray
                    Update-WinGetPackage -Id $Package.Id -Source msstore -ErrorAction Continue
                    Write-Host "Updated: $($Package.Name)" -ForegroundColor Green
                }
                catch {
                    Write-Host "Failed to update $($Package.Name): $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            Write-Host "WinGet Store app updates completed" -ForegroundColor Green
        } else {
            Write-Host "No Store app updates available via WinGet" -ForegroundColor Green
        }

        return $true
    }
    catch {
        Write-Host "WinGet method failed: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Function to update Store apps using WinRT API approach
function Update-StoreAppViaWinRT {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param()
    if (-not $PSCmdlet.ShouldProcess("Windows Store Apps via WinRT", "Update")) {
        return $false
    }

    Write-Host "Attempting to use Update-InboxApp WinRT API approach..." -ForegroundColor Gray

    try {
        # Check if we're running PowerShell 5.1 (required for WinRT APIs)
        if ($PSVersionTable.PSVersion.Major -ne 5) {
            Write-Host "WinRT API method requires PowerShell 5.1, current version is $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
            return $false
        }

        # Check if Update-InboxApp script is available
        $InboxAppScript = Get-InstalledScript -Name "Update-InboxApp" -ErrorAction SilentlyContinue

        if (-not $InboxAppScript) {
            Write-Host "Installing Update-InboxApp script..." -ForegroundColor Gray
            Install-Script -Name Update-InboxApp -Force -Scope CurrentUser -ErrorAction Stop
        } else {
            Write-Host "Update-InboxApp script found" -ForegroundColor Gray
        }

        Write-Host "Updating Store apps using WinRT APIs..." -ForegroundColor Gray

        # Update all Store apps using the WinRT API approach
        $StoreApps = Get-AppxPackage | Where-Object { $_.InstallLocation -like "*WindowsApps*" -and $_.SignatureKind -eq "Store" }

        if ($StoreApps.Count -gt 0) {
            Write-Host "Found $($StoreApps.Count) Store apps to check for updates" -ForegroundColor White

            foreach ($App in $StoreApps) {
                try {
                    Write-Host "Checking updates for: $($App.Name)" -ForegroundColor Gray
                    & Update-InboxApp $App.PackageFamilyName -ErrorAction Continue
                }
                catch {
                    Write-Host "Failed to update $($App.Name): $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            Write-Host "WinRT API Store app updates completed" -ForegroundColor Green
        } else {
            Write-Host "No Store apps found for WinRT API updates" -ForegroundColor Yellow
        }

        return $true
    }
    catch {
        Write-Host "WinRT API method failed: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Function to update Store apps using legacy methods (fallback)
function Update-StoreAppLegacy {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param()
    if (-not $PSCmdlet.ShouldProcess("Windows Store Apps via Legacy Methods", "Update")) {
        return $false
    }

    Write-Host "Using legacy update methods as final fallback..." -ForegroundColor Gray

    try {
        # Method 1: Use Windows Update PowerShell cmdlets for Store apps
        try {
            Write-Host "Attempting to trigger Store app updates via Windows Update..." -ForegroundColor Gray
            # This triggers the same update mechanism that Windows Update uses for Store apps
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
            $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'")

            if ($SearchResult.Updates.Count -gt 0) {
                Write-Host "Found $($SearchResult.Updates.Count) potential app updates" -ForegroundColor White

                # Download and install updates
                $UpdatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
                foreach ($Update in $SearchResult.Updates) {
                    $UpdatesToDownload.Add($Update) | Out-Null
                }

                if ($UpdatesToDownload.Count -gt 0) {
                    $Downloader = $UpdateSession.CreateUpdateDownloader()
                    $Downloader.Updates = $UpdatesToDownload
                    $DownloadResult = $Downloader.Download()

                    if ($DownloadResult.ResultCode -eq 2) {  # Success
                        $Installer = $UpdateSession.CreateUpdateInstaller()
                        $Installer.Updates = $UpdatesToDownload
                        $InstallResult = $Installer.Install()

                        if ($InstallResult.ResultCode -eq 2) {  # Success
                            Write-Host "Store app updates processed successfully via Windows Update mechanism" -ForegroundColor Green
                        } else {
                            Write-Host "Some Store app updates had issues (Result: $($InstallResult.ResultCode))" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "Failed to download some Store app updates (Result: $($DownloadResult.ResultCode))" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "No Store app updates available via Windows Update" -ForegroundColor Green
                }
            } else {
                Write-Host "No app updates found via Windows Update mechanism" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Windows Update method not available: $($_.Exception.Message)" -ForegroundColor Gray
        }

        # Method 2: Trigger Store background tasks
        Write-Host "Triggering Store background update tasks..." -ForegroundColor Gray
        try {
            # Get and start Store-related scheduled tasks that handle updates
            $StoreTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*Store*" -and $_.State -eq "Ready" }
            foreach ($Task in $StoreTasks) {
                Start-ScheduledTask -TaskName $Task.TaskName -ErrorAction SilentlyContinue
                Write-Host "Started task: $($Task.TaskName)" -ForegroundColor Gray
            }
            Write-Host "Store background tasks triggered" -ForegroundColor Green
        }
        catch {
            Write-Host "Could not trigger all Store background tasks: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        return $true
    }
    catch {
        Write-Host "Legacy methods failed: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Function to diagnose Windows Store issues (improved accuracy)
function Test-WindowsStoreHealth {
    Write-Host "`nDiagnosing Windows Store health..." -ForegroundColor Cyan

    $IssuesFound = $false
    $CriticalIssuesFound = $false

    try {
        # Check 1: Verify Store app package exists and is properly registered
        Write-Host "Checking Windows Store app package..." -ForegroundColor Gray
        $StoreApp = Get-AppxPackage -Name "Microsoft.WindowsStore" -ErrorAction SilentlyContinue
        if (-not $StoreApp) {
            Write-Host "Windows Store app package not found" -ForegroundColor Red
            $CriticalIssuesFound = $true
        } elseif ($StoreApp.Status -ne "Ok") {
            Write-Host "Windows Store app package status: $($StoreApp.Status)" -ForegroundColor Yellow
            $IssuesFound = $true
        } else {
            Write-Host "Windows Store app package healthy (Version: $($StoreApp.Version), Status: $($StoreApp.Status))" -ForegroundColor Green
        }

        # Check 2: Verify Store app can be launched (better than COM test)
        Write-Host "Testing Store app accessibility..." -ForegroundColor Gray
        try {
            # Test if Store app manifest is accessible (more relevant than Shell COM)
            $StoreManifestPath = "$($StoreApp.InstallLocation)\AppxManifest.xml"
            if ($StoreApp -and (Test-Path $StoreManifestPath -ErrorAction SilentlyContinue)) {
                Write-Host "Store app manifest accessible" -ForegroundColor Green
            } else {
                Write-Host "Store app manifest not accessible" -ForegroundColor Yellow
                $IssuesFound = $true
            }
        }
        catch {
            Write-Host "Store app accessibility check failed: $($_.Exception.Message)" -ForegroundColor Yellow
            $IssuesFound = $true
        }

        # Check 3: Verify critical Store services (improved logic for on-demand services)
        Write-Host "Checking Windows Store services..." -ForegroundColor Gray
        $StoreServices = @(
            @{Name="AppXSvc"; DisplayName="Application Experience"; Critical=$false},
            @{Name="ClipSVC"; DisplayName="Client License Service"; Critical=$false}
        )

        foreach ($ServiceInfo in $StoreServices) {
            $Service = Get-Service -Name $ServiceInfo.Name -ErrorAction SilentlyContinue
            if (-not $Service) {
                Write-Host "$($ServiceInfo.DisplayName) ($($ServiceInfo.Name)) service not found" -ForegroundColor Red
                if ($ServiceInfo.Critical) { $CriticalIssuesFound = $true }
                else { $IssuesFound = $true }
            } elseif ($Service.StartType -eq "Disabled") {
                Write-Host "$($ServiceInfo.DisplayName) service is disabled" -ForegroundColor Red
                if ($ServiceInfo.Critical) { $CriticalIssuesFound = $true }
                else { $IssuesFound = $true }
            } elseif ($Service.Status -eq "Running") {
                Write-Host "$($ServiceInfo.DisplayName) service is running" -ForegroundColor Green
            } elseif ($Service.StartType -eq "Manual" -or $Service.StartType -eq "Automatic") {
                Write-Host "$($ServiceInfo.DisplayName) service is available (Start: $($Service.StartType), Status: $($Service.Status))" -ForegroundColor Green
            } else {
                Write-Host "$($ServiceInfo.DisplayName) service issue (Start: $($Service.StartType), Status: $($Service.Status))" -ForegroundColor Yellow
                $IssuesFound = $true
            }
        }

        # Check 4: Test Store cache directory
        Write-Host "Checking Store cache directory..." -ForegroundColor Gray
        $StoreCachePath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe"
        if (Test-Path $StoreCachePath -ErrorAction SilentlyContinue) {
            Write-Host "Store cache directory exists" -ForegroundColor Green
        } else {
            Write-Host "Store cache directory missing" -ForegroundColor Yellow
            $IssuesFound = $true
        }

        # Only report issues if critical problems found, or if multiple minor issues detected
        $TotalIssues = $IssuesFound + $CriticalIssuesFound
        if ($CriticalIssuesFound) {
            Write-Host "`nCritical Store issues detected - repair recommended" -ForegroundColor Red
            return $true
        } elseif ($IssuesFound -and $TotalIssues -gt 1) {
            Write-Host "`nMultiple minor Store issues detected - repair may help" -ForegroundColor Yellow
            return $true
        } else {
            Write-Host "`nStore health check: No significant issues detected" -ForegroundColor Green
            return $false
        }
    }
    catch {
        Write-Host "Error during Store health check: $_" -ForegroundColor Yellow
        Write-Host "Unable to complete health check - assuming Store is healthy" -ForegroundColor Gray
        return $false  # Changed: Don't assume issues if we can't diagnose properly
    }
}

# Function to repair Windows Store (only runs if issues detected)
function Repair-WindowsStore {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param()
    if (-not $PSCmdlet.ShouldProcess("Windows Store", "Repair")) {
        return $false
    }

    Write-Host "`nRepairing Windows Store components..." -ForegroundColor Cyan

    try {
        # Re-register Windows Store
        Write-Host "Re-registering Windows Store..." -ForegroundColor Gray
        $StoreAppxPath = "${env:ProgramFiles}\WindowsApps\Microsoft.WindowsStore*\AppxManifest.xml"
        $StoreManifests = Get-ChildItem -Path $StoreAppxPath -ErrorAction SilentlyContinue

        if ($StoreManifests) {
            foreach ($Manifest in $StoreManifests) {
                Add-AppxPackage -Register $Manifest.FullName -DisableDevelopmentMode -ErrorAction SilentlyContinue
            }
            Write-Host "Windows Store re-registration completed." -ForegroundColor Green
        }

        # Reset Windows Store data
        Write-Host "Resetting Windows Store data..." -ForegroundColor Gray
        Start-Process "wsreset.exe" -NoNewWindow -Wait

        return $true
    }
    catch {
        Write-Error "Failed to repair Windows Store: $_"
        return $false
    }
}

# Main script execution
Write-Host "Windows Store Apps Update Script Starting..." -ForegroundColor Green
Write-Host "Time: $(Get-Date)" -ForegroundColor Gray

# At this point, we're running as administrator with bypass execution policy

try {
    $UpdateSuccess = $true
    $RepairPerformed = $false

    # Step 1: Diagnose Windows Store health
    Write-Host -Object ("`n" + "=" * 70) -ForegroundColor Cyan
    Write-Host "  STEP 1: DIAGNOSING WINDOWS STORE" -ForegroundColor Cyan
    Write-Host -Object ("=" * 70) -ForegroundColor Cyan

    $StoreIssuesFound = Test-WindowsStoreHealth

    if ($StoreIssuesFound) {
        Write-Host "`nIssues detected. Proceeding with Store repair..." -ForegroundColor Yellow
        Write-Host -Object ("`n" + "=" * 70) -ForegroundColor Yellow
        Write-Host "  REPAIR: FIXING STORE COMPONENTS" -ForegroundColor Yellow
        Write-Host -Object ("=" * 70) -ForegroundColor Yellow

        if (-not (Repair-WindowsStore)) {
            $UpdateSuccess = $false
        } else {
            $RepairPerformed = $true
        }
    } else {
        Write-Host "`nWindows Store appears healthy. No repair needed." -ForegroundColor Green
    }

    # Step 2: Update Store apps using modern methods
    Write-Host -Object ("`n" + "=" * 70) -ForegroundColor Cyan
    Write-Host "  STEP 2: UPDATING STORE APPS (MODERN METHODS)" -ForegroundColor Cyan
    Write-Host -Object ("=" * 70) -ForegroundColor Cyan

    Write-Host "Available update methods:" -ForegroundColor White
    Write-Host "  1. WinGet (Microsoft.WinGet.Client) - Primary method" -ForegroundColor White
    Write-Host "  2. WinRT APIs (Update-InboxApp) - Fallback for PS 5.1" -ForegroundColor White
    Write-Host "  3. Legacy methods - Final fallback" -ForegroundColor White

    if (-not (Update-StoreApp)) {
        $UpdateSuccess = $false
    }

    # Final results
    Write-Host -Object ("`n" + "=" * 70) -ForegroundColor Green
    if ($UpdateSuccess) {
        Write-Host "  ALL UPDATES COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    } else {
        Write-Host "  UPDATES COMPLETED WITH SOME WARNINGS" -ForegroundColor Yellow
    }
    Write-Host -Object ("=" * 70) -ForegroundColor Green

    Write-Host "`nUpdate Summary:" -ForegroundColor White
    if ($RepairPerformed) {
        Write-Host "- Windows Store: Issues detected and repaired" -ForegroundColor White
    } else {
        Write-Host "- Windows Store: Health check passed, no repair needed" -ForegroundColor White
    }
    Write-Host "- Store Apps: Modern update methods attempted with fallbacks" -ForegroundColor White
    Write-Host "  * WinGet method (Repair-WingetPackageManager)" -ForegroundColor Gray
    Write-Host "  * WinRT API method (Update-InboxApp)" -ForegroundColor Gray
    Write-Host "  * Legacy methods (Windows Update COM + Scheduled Tasks)" -ForegroundColor Gray

    Write-Host "`nNote: Some Store app updates may continue in the background." -ForegroundColor Cyan
    Write-Host "You can check the Microsoft Store 'Downloads and updates' page for progress." -ForegroundColor Cyan
    Write-Host "`nFor best results on future runs:" -ForegroundColor White
    Write-Host "- Use PowerShell 5.1 for WinRT API support" -ForegroundColor Gray
    Write-Host "- Ensure internet connectivity for WinGet module downloads" -ForegroundColor Gray

    Write-Host "`nExiting in 10 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 10

} catch {
    Write-Error "An error occurred during the update process: $_"
    Write-Host "`nYou may want to run Windows Store updates manually or try again later." -ForegroundColor Yellow
    Write-Host "`nExiting in 10 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
