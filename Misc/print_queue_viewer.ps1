<#
.SYNOPSIS
    Interactive Printer Queue Viewer and Manager

.DESCRIPTION
    This script provides an interactive interface to view and manage print queues
    for all available printers (both local and network). Users can cancel individual
    jobs or clear entire queues.

.NOTES
    - Requires PowerShell 5.0 or later
    - May require administrator privileges for some operations
    - Uses Write-Host intentionally for interactive UI display

.AUTHOR
    tboy1337

.VERSION
    2.0
#>

#Requires -Version 5.0

function Show-PrinterMenu {
    <#
    .SYNOPSIS
        Displays a menu of available printers and allows user selection.

    .DESCRIPTION
        Retrieves all available printers (local and network), displays them in a
        numbered list, and prompts the user to select one.

    .OUTPUTS
        [Object] The selected printer object, or $null if user chooses to quit
    #>
    [CmdletBinding()]
    param()

    try {
        Clear-Host
        Write-Host "=== Printer Queue Viewer ===" -ForegroundColor Cyan
        Write-Host

        # Get all printers including network printers with error handling
        Write-Verbose "Retrieving printer list..."
        $printers = @(Get-Printer -ErrorAction Stop | Sort-Object Name)

        if ($printers.Count -eq 0) {
            Write-Host "No printers found on this system." -ForegroundColor Yellow
            Write-Host "Press any key to exit..."
            $null = $Host.UI.RawUI.ReadKey()
            return $null
        }

        # Display printer list with numbers
        for ($i = 0; $i -lt $printers.Count; $i++) {
            $status = $printers[$i].PrinterStatus
            $type = if ($printers[$i].Type -eq "Connection") { "Network" } else { "Local" }
            Write-Host ("{0,3}) {1,-40} [{2}] - {3}" -f ($i + 1), $printers[$i].Name, $type, $status)
        }

        Write-Host
        Write-Host "Q) Quit" -ForegroundColor Yellow
        Write-Host

        # Get user selection with validation
        do {
            $selection = Read-Host "Select a printer (1-$($printers.Count) or Q to quit)"

            if ([string]::IsNullOrWhiteSpace($selection)) {
                Write-Host "Please enter a valid selection." -ForegroundColor Red
                continue
            }

            if ($selection.ToUpper() -eq 'Q') {
                return $null
            }

            if (-not ($selection -match '^\d+$')) {
                Write-Host "Please enter a number between 1 and $($printers.Count) or Q to quit." -ForegroundColor Red
                continue
            }

            $selectionInt = [int]$selection
            if ($selectionInt -lt 1 -or $selectionInt -gt $printers.Count) {
                Write-Host "Please enter a number between 1 and $($printers.Count) or Q to quit." -ForegroundColor Red
                continue
            }

            break
        } while ($true)

        return $printers[$selectionInt - 1]
    }
    catch {
        Write-Host "Error retrieving printers: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You may need administrator privileges to access printer information." -ForegroundColor Yellow
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey()
        return $null
    }
}

function Show-PrintQueue {
    <#
    .SYNOPSIS
        Displays and manages the print queue for a specified printer.

    .DESCRIPTION
        Shows all pending print jobs for the selected printer and provides options
        to cancel individual jobs, clear the entire queue, or refresh the display.

    .PARAMETER Printer
        The printer object for which to display the queue
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $Printer
    )

    while ($true) {
        try {
            Clear-Host
            Write-Host "=== Print Queue for $($Printer.Name) ===" -ForegroundColor Cyan
            Write-Host

            # Get print jobs for the selected printer with error handling
            Write-Verbose "Retrieving print jobs for printer: $($Printer.Name)"
            $jobs = @(Get-PrintJob -PrinterName $Printer.Name -ErrorAction Stop | Sort-Object JobStatus, SubmittedTime)

            if ($jobs.Count -eq 0) {
                Write-Host "No jobs in queue" -ForegroundColor Yellow
                Write-Host
                Write-Host "Options:" -ForegroundColor Green
                Write-Host "B) Back to printer selection"
                Write-Host "Q) Quit"

                $choice = Read-Host "Select an option"
                switch ($choice.ToUpper()) {
                    'B' { return }
                    'Q' { exit 0 }
                    default {
                        Write-Host "Invalid option. Please select B or Q." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
            }
            else {
                # Display all jobs with improved formatting
                Write-Host "Current Jobs:" -ForegroundColor Green
                Write-Host ("-" * 80)

                for ($i = 0; $i -lt $jobs.Count; $i++) {
                    $job = $jobs[$i]
                    Write-Host ("{0,3}) Job ID: {1}" -f ($i + 1), $job.JobId)
                    $docName = if ($job.DocumentName) { $job.DocumentName } else { "Unknown" }
                    Write-Host ("     Document: {0}" -f $docName)
                    Write-Host ("     Status: {0}" -f $job.JobStatus)
                    Write-Host ("     Submitted: {0}" -f $job.SubmittedTime)
                    $pagesPrinted = if ($job.PagesPrinted) { $job.PagesPrinted } else { 0 }
                    Write-Host ("     Pages Printed: {0}" -f $pagesPrinted)
                    $totalPages = if ($job.TotalPages) { $job.TotalPages } else { 0 }
                    Write-Host ("     Total Pages: {0}" -f $totalPages)
                    if ($i -lt $jobs.Count - 1) {
                        Write-Host ("-" * 40)
                    }
                }

                Write-Host ("-" * 80)
                Write-Host
                Write-Host "Options:" -ForegroundColor Green
                Write-Host "1-$($jobs.Count)) Cancel specific job"
                Write-Host "A) Cancel ALL jobs" -ForegroundColor Red
                Write-Host "R) Refresh queue"
                Write-Host "B) Back to printer selection"
                Write-Host "Q) Quit"
                Write-Host

                $choice = Read-Host "Select an option"

                switch -Regex ($choice.ToUpper()) {
                    '^[0-9]+$' {
                        $jobIndex = [int]$choice - 1
                        if ($jobIndex -ge 0 -and $jobIndex -lt $jobs.Count) {
                            $jobToCancel = $jobs[$jobIndex]  # Fixed typo: was $jobToCanel

                            $cancelDocName = if ($jobToCancel.DocumentName) { $jobToCancel.DocumentName } else { "Unknown Document" }
                            Write-Host "Cancelling job: $cancelDocName..." -ForegroundColor Yellow
                            try {
                                Remove-PrintJob -InputObject $jobToCancel -ErrorAction Stop
                                Write-Host "Job cancelled successfully!" -ForegroundColor Green
                            }
                            catch {
                                Write-Host "Error cancelling job: $($_.Exception.Message)" -ForegroundColor Red
                                Write-Host "You may need administrator privileges to cancel print jobs." -ForegroundColor Yellow
                            }
                            Start-Sleep -Seconds 2
                        }
                        else {
                            Write-Host "Invalid job number. Please select 1-$($jobs.Count)." -ForegroundColor Red
                            Start-Sleep -Seconds 1
                        }
                    }
                    'A' {
                        Write-Host "Are you sure you want to cancel ALL $($jobs.Count) jobs? (Y/N)" -ForegroundColor Red
                        $confirm = Read-Host
                        if ($confirm.ToUpper() -eq 'Y') {
                            Write-Host "Cancelling all jobs..." -ForegroundColor Yellow
                            $cancelledCount = 0
                            $errorCount = 0

                            foreach ($job in $jobs) {
                                try {
                                    Remove-PrintJob -InputObject $job -ErrorAction Stop
                                    $cancelledCount++
                                }
                                catch {
                                    $errorCount++
                                    Write-Verbose "Failed to cancel job $($job.JobId): $($_.Exception.Message)"
                                }
                            }

                            if ($cancelledCount -gt 0) {
                                Write-Host "$cancelledCount job(s) cancelled successfully!" -ForegroundColor Green
                            }
                            if ($errorCount -gt 0) {
                                Write-Host "$errorCount job(s) could not be cancelled." -ForegroundColor Red
                                Write-Host "You may need administrator privileges to cancel some jobs." -ForegroundColor Yellow
                            }
                        }
                        else {
                            Write-Host "Operation cancelled." -ForegroundColor Yellow
                        }
                        Start-Sleep -Seconds 2
                    }
                    'R' {
                        Write-Host "Refreshing queue..." -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        continue
                    }
                    'B' { return }
                    'Q' { exit 0 }
                    default {
                        Write-Host "Invalid option. Please select from the available choices." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
            }
        }
        catch {
            Write-Host "Error accessing print queue: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "The printer may be offline or inaccessible." -ForegroundColor Yellow
            Write-Host
            Write-Host "Press any key to return to printer selection..."
            $null = $Host.UI.RawUI.ReadKey()
            return
        }
    }
}

function Start-PrintQueueManager {
    <#
    .SYNOPSIS
        Main script entry point that runs the printer queue management interface.

    .DESCRIPTION
        Continuously displays the printer selection menu and manages print queues
        until the user chooses to exit.
    #>
    [CmdletBinding()]
    param()

    # Check if running with sufficient privileges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "Note: Some operations may require administrator privileges." -ForegroundColor Yellow
        Write-Host "Consider running PowerShell as Administrator for full functionality." -ForegroundColor Yellow
        Write-Host
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey()
    }

    # Main application loop
    while ($true) {
        $selectedPrinter = Show-PrinterMenu
        if ($null -eq $selectedPrinter) {
            break
        }
        Show-PrintQueue -Printer $selectedPrinter
    }

    Write-Host "Goodbye!" -ForegroundColor Yellow
}

# Script execution starts here
if ($MyInvocation.InvocationName -ne '.') {
    # Only run if script is executed directly, not dot-sourced
    Start-PrintQueueManager
}
