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
    
    Clear-Host
    Write-Host "=== Print Queue for $($Printer.Name) ===" -ForegroundColor Cyan
    Write-Host

    # Get print jobs for the selected printer
    $jobs = Get-PrintJob -PrinterName $Printer.Name | Sort-Object JobStatus, SubmittedTime

    if ($jobs.Count -eq 0) {
        Write-Host "No jobs in queue" -ForegroundColor Yellow
    }
    else {
        foreach ($job in $jobs) {
            Write-Host ("Job ID: {0}" -f $job.JobId)
            Write-Host ("Document: {0}" -f $job.DocumentName)
            Write-Host ("Status: {0}" -f $job.JobStatus)
            Write-Host ("Submitted: {0}" -f $job.SubmittedTime)
            Write-Host ("Pages: {0}" -f $job.PagesPrinted)
            Write-Host ("-" * 40)
        }
    }

    Write-Host
    Write-Host "Press any key to return to printer selection..." -ForegroundColor Green
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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
