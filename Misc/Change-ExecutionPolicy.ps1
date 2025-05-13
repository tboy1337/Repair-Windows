# Change-ExecutionPolicy.ps1
# This script allows you to easily change PowerShell execution policies systemwide
# Author: Claude
# Date: May 13, 2025

function Show-Menu {
    Clear-Host
    Write-Host "============================================="
    Write-Host "    POWERSHELL EXECUTION POLICY MANAGER      "
    Write-Host "============================================="
    Write-Host
    Write-Host "Current Execution Policy: $($currentPolicy)"
    Write-Host "Current User: $($currentUser)"
    Write-Host "Running as Administrator: $($isAdmin)"
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

function Set-NewExecutionPolicy {
    param(
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

# Check if running as administrator
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "WARNING: This script is not running with administrator privileges." -ForegroundColor Red
    Write-Host "Changing system execution policies requires administrator rights." -ForegroundColor Red
    Write-Host "Please restart this script by right-clicking and selecting 'Run as administrator'." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

# Main program
$exit = $false

while (-not $exit) {
    # Get current execution policy
    $currentPolicy = Get-ExecutionPolicy -Scope MachinePolicy
    
    # Show menu
    Show-Menu
    
    # Get user input
    $choice = Read-Host "Enter your choice"
    
    switch ($choice) {
        {$_ -in "1", "2", "3", "4", "5", "6"} {
            Set-NewExecutionPolicy -SelectedPolicy $_
        }
        {$_ -in "Q", "q"} {
            $exit = $true
        }
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Read-Host "Press Enter to continue"
        }
    }
}

Write-Host "Thank you for using the PowerShell Execution Policy Manager." -ForegroundColor Cyan