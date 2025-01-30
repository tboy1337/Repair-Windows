function Show-PrinterMenu {
    Clear-Host
    Write-Host "=== Printer Queue Viewer ===" -ForegroundColor Cyan
    Write-Host

    # Get all printers including network printers
    $printers = Get-Printer | Sort-Object Name
    
    # Display printer list with numbers
    for ($i = 0; $i -lt $printers.Count; $i++) {
        $status = $printers[$i].PrinterStatus
        $type = if ($printers[$i].Type -eq "Connection") { "Network" } else { "Local" }
        Write-Host ("{0,3}) {1,-40} [{2}] - {3}" -f ($i + 1), $printers[$i].Name, $type, $status)
    }
    
    Write-Host
    Write-Host "Q) Quit" -ForegroundColor Yellow
    Write-Host

    # Get user selection
    do {
        $selection = Read-Host "Select a printer (1-$($printers.Count) or Q to quit)"
        if ($selection -eq 'Q') {
            return $null
        }
    } while (
        -not ($selection -match '^\d+$') -or
        [int]$selection -lt 1 -or 
        [int]$selection -gt $printers.Count
    )

    return $printers[$selection - 1]
}

function Show-PrintQueue {
    param (
        [Parameter(Mandatory = $true)]
        $Printer
    )
    
    while ($true) {
        Clear-Host
        Write-Host "=== Print Queue for $($Printer.Name) ===" -ForegroundColor Cyan
        Write-Host

        # Get print jobs for the selected printer
        $jobs = Get-PrintJob -PrinterName $Printer.Name | Sort-Object JobStatus, SubmittedTime

        if ($jobs.Count -eq 0) {
            Write-Host "No jobs in queue" -ForegroundColor Yellow
            Write-Host
            Write-Host "Options:" -ForegroundColor Green
            Write-Host "B) Back to printer selection"
            Write-Host "Q) Quit"
            
            $choice = Read-Host "Select an option"
            switch ($choice.ToUpper()) {
                'B' { return }
                'Q' { exit }
            }
        }
        else {
            # Display all jobs
            $jobList = @()
            for ($i = 0; $i -lt $jobs.Count; $i++) {
                $job = $jobs[$i]
                Write-Host ("{0,3}) Job ID: {1}" -f ($i + 1), $job.JobId)
                Write-Host ("     Document: {0}" -f $job.DocumentName)
                Write-Host ("     Status: {0}" -f $job.JobStatus)
                Write-Host ("     Submitted: {0}" -f $job.SubmittedTime)
                Write-Host ("     Pages: {0}" -f $job.PagesPrinted)
                Write-Host ("-" * 40)
                $jobList += $job
            }

            Write-Host
            Write-Host "Options:" -ForegroundColor Green
            Write-Host "1-$($jobs.Count)) Cancel specific job"
            Write-Host "A) Cancel ALL jobs"
            Write-Host "R) Refresh queue"
            Write-Host "B) Back to printer selection"
            Write-Host "Q) Quit"
            Write-Host

            $choice = Read-Host "Select an option"
            
            switch -Regex ($choice.ToUpper()) {
                '^[0-9]+$' {
                    $jobIndex = [int]$choice - 1
                    if ($jobIndex -ge 0 -and $jobIndex -lt $jobs.Count) {
                        $jobToCanel = $jobList[$jobIndex]
                        try {
                            Remove-PrintJob -InputObject $jobToCanel
                            Write-Host "Job cancelled successfully!" -ForegroundColor Green
                        }
                        catch {
                            Write-Host "Error cancelling job: $_" -ForegroundColor Red
                        }
                        Start-Sleep -Seconds 2
                    }
                }
                'A' {
                    try {
                        $jobs | ForEach-Object { Remove-PrintJob -InputObject $_ }
                        Write-Host "All jobs cancelled successfully!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Error cancelling jobs: $_" -ForegroundColor Red
                    }
                    Start-Sleep -Seconds 2
                }
                'R' { continue }
                'B' { return }
                'Q' { exit }
            }
        }
    }
}

# Main loop
while ($true) {
    $selectedPrinter = Show-PrinterMenu
    if ($null -eq $selectedPrinter) {
        break
    }
    Show-PrintQueue -Printer $selectedPrinter
}

Write-Host "Goodbye!" -ForegroundColor Yellow
