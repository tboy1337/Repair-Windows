# Change-ExecutionPolicy.ps1
# This script allows you to easily change PowerShell execution policies systemwide
# Author: Claude
# Date: May 13, 2025

#Requires -RunAsAdministrator

# Self-elevate the script if not running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    exit
}

<#
.SYNOPSIS
    Displays the execution policy management menu.
.DESCRIPTION
    Shows a menu interface for the execution policy manager with current status information.
.PARAMETER CurrentPolicy
    The current execution policy.
.PARAMETER CurrentUser
    The name of the current user.
.PARAMETER IsAdmin
    Boolean indicating if the script is running with admin privileges.
.EXAMPLE
    Show-ExecutionPolicyMenu -CurrentPolicy "RemoteSigned" -CurrentUser "Administrator" -IsAdmin $true
#>
function Show-ExecutionPolicyMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentPolicy,
        
        [Parameter(Mandatory = $true)]
        [string]$CurrentUser,
        
        [Parameter(Mandatory = $true)]
        [bool]$IsAdmin
    )
    
    Clear-Host
    Write-Host "============================================="
    Write-Host "    POWERSHELL EXECUTION POLICY MANAGER      "
    Write-Host "============================================="
    Write-Host
    Write-Host "Current Execution Policy: $CurrentPolicy"
    Write-Host "Current User: $CurrentUser"
    Write-Host "Running as Administrator: $IsAdmin"
    Write-Host
    Write-Host "Available Policies:"
    Write-Host "1: Restricted - No scripts can run"
    Write-Host "2: AllSigned - Only signed scripts can run"
    Write-Host "3: RemoteSigned - Local scripts can run; downloaded scripts must be signed"
    Write-Host "4: Unrestricted - All scripts can run (security warning for downloaded scripts)"
    Write-Host "5: Bypass - All scripts run with no warnings (least secure)"
    Write-Host "6: Undefined - Remove the execution policy"
    Write-Host
    Write-Host "Q: Quit"
    Write-Host
}

<#
.SYNOPSIS
    Sets a new PowerShell execution policy.
.DESCRIPTION
    Changes the execution policy systemwide with confirmation and security warnings.
.PARAMETER SelectedPolicy
    The selected policy number (1-6) from the menu.
.EXAMPLE
    Set-ExecutionPolicyFromMenu -SelectedPolicy "3"
#>
function Set-ExecutionPolicyFromMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SelectedPolicy
    )
    
    $policyMap = @{
        "1" = "Restricted"
        "2" = "AllSigned"
        "3" = "RemoteSigned"
        "4" = "Unrestricted"
        "5" = "Bypass"
        "6" = "Undefined"
    }
    
    $policyName = $policyMap[$SelectedPolicy]
    
    if (-not $policyName) {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        return
    }
    
    try {
        # Confirm before making changes
        Write-Host
        Write-Host "WARNING: You are about to change the system execution policy to '$policyName'." -ForegroundColor Yellow
        
        if ($policyName -eq "Unrestricted" -or $policyName -eq "Bypass") {
            Write-Host "SECURITY NOTICE: '$policyName' reduces security and should only be used in trusted environments." -ForegroundColor Red
        }
        
        $confirmation = Read-Host "Do you want to continue? (Y/N)"
        
        if ($confirmation -ne "Y" -and $confirmation -ne "y") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return
        }
        
        # Set the policy
        Set-ExecutionPolicy -ExecutionPolicy $policyName -Scope MachinePolicy -Force
        Write-Host "Execution policy successfully changed to '$policyName' for the entire system." -ForegroundColor Green
        
        # Provide information about persistence
        Write-Host "This change affects all users and persists across PowerShell sessions." -ForegroundColor Cyan
        
        # Show recommendation for RemoteSigned if they chose a less secure option
        if ($policyName -eq "Unrestricted" -or $policyName -eq "Bypass") {
            Write-Host "RECOMMENDATION: Consider using 'RemoteSigned' for better security when finished with your task." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Failed to change execution policy. Make sure you're running as Administrator." -ForegroundColor Red
    }
    
    Write-Host
    Read-Host "Press Enter to continue"
}

# Main program
function Start-ExecutionPolicyManager {
    [CmdletBinding()]
    param()
    
    # Initialize variables
    $script:currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $script:isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    $script:exit = $false

    while (-not $script:exit) {
        # Get current execution policy
        $currentPolicy = Get-ExecutionPolicy -Scope MachinePolicy
        
        # Show menu
        Show-ExecutionPolicyMenu -CurrentPolicy $currentPolicy -CurrentUser $script:currentUser -IsAdmin $script:isAdmin
        
        # Get user input
        $choice = Read-Host "Enter your choice"
        
        switch ($choice) {
            {$_ -in "1", "2", "3", "4", "5", "6"} {
                Set-ExecutionPolicyFromMenu -SelectedPolicy $_
            }
            {$_ -in "Q", "q"} {
                $script:exit = $true
            }
            default {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Read-Host "Press Enter to continue"
            }
        }
    }

    Write-Host "Thank you for using the PowerShell Execution Policy Manager." -ForegroundColor Cyan
}

# Start the execution policy manager
Start-ExecutionPolicyManager