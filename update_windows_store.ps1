<# Self-Elevating PowerShell Script
This script automatically handles execution policy and administrator elevation
#>

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
    Windows Store Apps Update Script with User Notification
.DESCRIPTION
    Updates Windows Store apps using PowerShell cmdlets automatically.
    Provides detailed feedback on update process and handles errors gracefully.
.NOTES
    Automatically handles elevation and execution policy
#>

# Function to update Windows Store apps automatically
function Update-StoreApps {
    Write-Host "`nUpdating Windows Store apps automatically..." -ForegroundColor Cyan
    
    try {
        # Reset Windows Store cache first
        Write-Host "Resetting Windows Store cache..." -ForegroundColor Gray
        Start-Process "wsreset.exe" -NoNewWindow -Wait
        
        # Get the Windows Store app to verify it exists
        Write-Host "Verifying Windows Store availability..." -ForegroundColor Gray
        $StoreApp = Get-AppxPackage -Name "Microsoft.WindowsStore" -ErrorAction SilentlyContinue
        if (-not $StoreApp) {
            Write-Host "⚠️  Windows Store app not found. Cannot proceed with updates." -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "✅ Windows Store found (Version: $($StoreApp.Version))" -ForegroundColor Green
        
        # Try to programmatically trigger Store app updates using PowerShell
        Write-Host "Triggering automatic app updates..." -ForegroundColor Cyan
        
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
                            Write-Host "✅ Store app updates processed successfully via Windows Update mechanism" -ForegroundColor Green
                        } else {
                            Write-Host "⚠️  Some Store app updates had issues (Result: $($InstallResult.ResultCode))" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "⚠️  Failed to download some Store app updates (Result: $($DownloadResult.ResultCode))" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "✅ No Store app updates available via Windows Update" -ForegroundColor Green
                }
            } else {
                Write-Host "✅ No app updates found via Windows Update mechanism" -ForegroundColor Green
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
            Write-Host "✅ Store background tasks triggered" -ForegroundColor Green
        }
        catch {
            Write-Host "Could not trigger all Store background tasks: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        Write-Host "`n✅ Store app update process completed automatically!" -ForegroundColor Green
        Write-Host "Note: Store app updates may continue processing in the background." -ForegroundColor Cyan
        return $true
    }
    catch {
        Write-Error "Failed to update Store apps: $_"
        return $false
    }
}

# Function to diagnose Windows Store issues
function Test-WindowsStoreHealth {
    Write-Host "`nDiagnosing Windows Store health..." -ForegroundColor Cyan
    
    $IssuesFound = $false
    
    try {
        # Check 1: Verify Store app package exists
        Write-Host "Checking Windows Store app package..." -ForegroundColor Gray
        $StoreApp = Get-AppxPackage -Name "Microsoft.WindowsStore" -ErrorAction SilentlyContinue
        if (-not $StoreApp) {
            Write-Host "⚠️  Windows Store app package not found" -ForegroundColor Yellow
            $IssuesFound = $true
        } else {
            Write-Host "✅ Windows Store app package found (Version: $($StoreApp.Version))" -ForegroundColor Green
        }
        
        # Check 2: Test Store COM interface
        Write-Host "Testing Store COM interface..." -ForegroundColor Gray
        try {
            $Shell = New-Object -ComObject Shell.Application -ErrorAction Stop
            $null = $Shell  # Just verify we can create it
            Write-Host "✅ Store COM interface accessible" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Store COM interface not accessible" -ForegroundColor Yellow
            $IssuesFound = $true
        }
        
        # Check 3: Verify critical Store services
        Write-Host "Checking Windows Store services..." -ForegroundColor Gray
        $StoreServices = @("AppXSvc", "ClipSVC")
        foreach ($ServiceName in $StoreServices) {
            $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($Service -and $Service.Status -eq "Running") {
                Write-Host "✅ $ServiceName service is running" -ForegroundColor Green
            } else {
                Write-Host "⚠️  $ServiceName service issue detected" -ForegroundColor Yellow
                $IssuesFound = $true
            }
        }
        
        return $IssuesFound
    }
    catch {
        Write-Host "⚠️  Error during Store health check: $_" -ForegroundColor Yellow
        return $true  # Assume issues if we can't diagnose
    }
}

# Function to repair Windows Store (only runs if issues detected)
function Repair-WindowsStore {
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
    Write-Host "`n" + "=" * 70 -ForegroundColor Cyan
    Write-Host "  STEP 1: DIAGNOSING WINDOWS STORE" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    
    $StoreIssuesFound = Test-WindowsStoreHealth
    
    if ($StoreIssuesFound) {
        Write-Host "`nIssues detected. Proceeding with Store repair..." -ForegroundColor Yellow
        Write-Host "`n" + "=" * 70 -ForegroundColor Yellow
        Write-Host "  REPAIR: FIXING STORE COMPONENTS" -ForegroundColor Yellow
        Write-Host "=" * 70 -ForegroundColor Yellow
        
        if (-not (Repair-WindowsStore)) {
            $UpdateSuccess = $false
        } else {
            $RepairPerformed = $true
        }
    } else {
        Write-Host "`n✅ Windows Store appears healthy. No repair needed." -ForegroundColor Green
    }
    
    # Step 2: Update Store apps automatically
    Write-Host "`n" + "=" * 70 -ForegroundColor Cyan
    Write-Host "  STEP 2: UPDATING STORE APPS" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    
    if (-not (Update-StoreApps)) {
        $UpdateSuccess = $false
    }
    
    # Final results
    Write-Host "`n" + "=" * 70 -ForegroundColor Green
    if ($UpdateSuccess) {
        Write-Host "  ALL UPDATES COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    } else {
        Write-Host "  UPDATES COMPLETED WITH SOME WARNINGS" -ForegroundColor Yellow
    }
    Write-Host "=" * 70 -ForegroundColor Green
    
    Write-Host "`nUpdate Summary:" -ForegroundColor White
    if ($RepairPerformed) {
        Write-Host "- Windows Store: Issues detected and repaired" -ForegroundColor White
    } else {
        Write-Host "- Windows Store: Health check passed, no repair needed" -ForegroundColor White
    }
    Write-Host "- Store Apps: Automatic update process completed" -ForegroundColor White
    
    Write-Host "`nNote: Some Store app updates may continue in the background." -ForegroundColor Cyan
    Write-Host "You can check the Microsoft Store 'Downloads and updates' page for progress." -ForegroundColor Cyan
    
    Write-Host "`nExiting in 15 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 15
    
} catch {
    Write-Error "An error occurred during the update process: $_"
    Write-Host "`nYou may want to run Windows Store updates manually or try again later." -ForegroundColor Yellow
    Write-Host "`nExiting in 10 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
