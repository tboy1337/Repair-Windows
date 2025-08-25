#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Update Script with User Notification
.DESCRIPTION
    Downloads and installs Windows updates using PowerShell, with user notification
    and 60-second countdown before restart if required.
.NOTES
    Must be run as Administrator
#>

# Function to show countdown with option to cancel
function Show-RestartCountdown {
    param(
        [int]$Seconds = 60
    )
    
    Write-Host "`n" -ForegroundColor Yellow
    Write-Host "=" * 70 -ForegroundColor Yellow
    Write-Host "  RESTART REQUIRED - SAVE YOUR WORK NOW!" -ForegroundColor Red
    Write-Host "=" * 70 -ForegroundColor Yellow
    Write-Host "`nUpdates have been installed and require a restart to complete." -ForegroundColor White
    Write-Host "The system will restart automatically in $Seconds seconds." -ForegroundColor White
    Write-Host "`nPress 'C' to cancel the restart, or any other key to restart immediately." -ForegroundColor Cyan
    Write-Host "Or simply wait for the countdown to complete." -ForegroundColor Cyan
    
    for ($i = $Seconds; $i -gt 0; $i--) {
        Write-Host "`rRestart in: $i seconds... " -NoNewline -ForegroundColor Red
        
        # Check if user pressed a key
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'C') {
                Write-Host "`n`nRestart cancelled by user." -ForegroundColor Green
                Write-Host "Please restart your computer manually when convenient to complete the updates." -ForegroundColor Yellow
                return $false
            } else {
                Write-Host "`n`nRestarting immediately..." -ForegroundColor Yellow
                return $true
            }
        }
        
        Start-Sleep -Seconds 1
    }
    
    Write-Host "`n`nTime's up! Restarting now..." -ForegroundColor Yellow
    return $true
}

# Function to install PSWindowsUpdate module if not present
function Install-WindowsUpdateModule {
    Write-Host "Checking for PSWindowsUpdate module..." -ForegroundColor Cyan
    
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "PSWindowsUpdate module not found. Installing..." -ForegroundColor Yellow
        
        try {
            # Install NuGet provider first (required for module installation)
            Write-Host "Installing NuGet provider..." -ForegroundColor Cyan
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers -Confirm:$false | Out-Null
            
            # Set PSGallery as trusted repository to avoid prompts
            Write-Host "Setting PSGallery as trusted repository..." -ForegroundColor Cyan
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            
            # Install the PSWindowsUpdate module
            Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Cyan
            Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Scope AllUsers -Confirm:$false -SkipPublisherCheck
            Write-Host "PSWindowsUpdate module installed successfully." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install PSWindowsUpdate module: $_"
            exit 1
        }
    } else {
        Write-Host "PSWindowsUpdate module is already installed." -ForegroundColor Green
    }
    
    # Import the module
    Import-Module PSWindowsUpdate -Force
}

# Main script
Write-Host "Windows Update Script Starting..." -ForegroundColor Green
Write-Host "Time: $(Get-Date)" -ForegroundColor Gray

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "`nExiting in 10 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
    exit 1
}

# Install/Import the Windows Update module
Install-WindowsUpdateModule

Write-Host "`nChecking for available updates..." -ForegroundColor Cyan

try {
    # Get list of available updates
    $Updates = Get-WUList -Verbose
    
    if ($Updates.Count -eq 0) {
        Write-Host "No updates available. Your system is up to date!" -ForegroundColor Green
        Write-Host "`nExiting in 10 seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        exit 0
    }
    
    Write-Host "`nFound $($Updates.Count) update(s):" -ForegroundColor Yellow
    foreach ($Update in $Updates) {
        Write-Host "  - $($Update.Title)" -ForegroundColor White
    }
    
    Write-Host "`nStarting update download and installation..." -ForegroundColor Cyan
    Write-Host "This may take several minutes depending on update size." -ForegroundColor Gray
    
    # Install updates and capture the result
    $InstallResult = Install-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose
    
    Write-Host "`nUpdate installation completed!" -ForegroundColor Green
    
    # Check if restart is required
    $RestartRequired = $false
    foreach ($Result in $InstallResult) {
        if ($Result.RebootRequired) {
            $RestartRequired = $true
            break
        }
    }
    
    # Also check using Get-WURebootStatus if available
    try {
        $RebootStatus = Get-WURebootStatus
        if ($RebootStatus.RebootRequired) {
            $RestartRequired = $true
        }
    }
    catch {
        # Fallback: check Windows Update registry key for pending restart
        $PendingReboot = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
        if ($PendingReboot) {
            $RestartRequired = $true
        }
    }
    
    if ($RestartRequired) {
        $ShouldRestart = Show-RestartCountdown -Seconds 60
        
        if ($ShouldRestart) {
            Write-Host "Initiating system restart..." -ForegroundColor Red
            Start-Sleep -Seconds 2
            Restart-Computer -Force
        }
    } else {
        Write-Host "`nNo restart required. All updates have been installed successfully!" -ForegroundColor Green
        Write-Host "`nExiting in 10 seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
    
} catch {
    Write-Error "An error occurred during the update process: $_"
    Write-Host "`nYou may want to run Windows Update manually or try again later." -ForegroundColor Yellow
    Write-Host "`nExiting in 10 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
