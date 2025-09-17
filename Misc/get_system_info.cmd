@echo off
setlocal

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

echo Creating system information report...
for /f "tokens=2 delims==." %%a in ('wmic os get localdatetime /value') do set datetime=%%a
set timestamp=%datetime:~0,8%-%datetime:~8,6%
set outputFile=SystemInfo_%timestamp%.txt

echo === System Information Report === > "%outputFile%"
echo Generated on: %date% %time% >> "%outputFile%"
echo. >> "%outputFile%"

:: Computer System Information
call powershell -Command "$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem; '=== Computer System ===' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Manufacturer: ' + $computerSystem.Manufacturer | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Model: ' + $computerSystem.Model | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'System Name: ' + $computerSystem.Name | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Domain: ' + $computerSystem.Domain | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Total Physical Memory (GB): ' + [math]::Round($computerSystem.TotalPhysicalMemory/1GB, 2) | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Operating System Information
call powershell -Command "$os = Get-CimInstance -ClassName Win32_OperatingSystem; '=== Operating System ===' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'OS Name: ' + $os.Caption | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Version: ' + $os.Version | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Build Number: ' + $os.BuildNumber | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Architecture: ' + $os.OSArchitecture | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Install Date: ' + $os.InstallDate | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Last Boot Time: ' + $os.LastBootUpTime | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Processor Information
call powershell -Command "$processor = Get-CimInstance -ClassName Win32_Processor; '=== Processor Information ===' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'CPU: ' + $processor.Name | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Description: ' + $processor.Description | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Manufacturer: ' + $processor.Manufacturer | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Number of Cores: ' + $processor.NumberOfCores | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Number of Logical Processors: ' + $processor.NumberOfLogicalProcessors | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Max Clock Speed (GHz): ' + [math]::Round($processor.MaxClockSpeed/1000, 2) | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'L2 Cache Size (KB): ' + $processor.L2CacheSize | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'L3 Cache Size (KB): ' + $processor.L3CacheSize | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Memory Information
call powershell -Command "$memory = Get-CimInstance -ClassName Win32_PhysicalMemory; '=== Memory Information ===' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; foreach ($mem in $memory) { 'Memory Module:' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Manufacturer: ' + $mem.Manufacturer | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Capacity (GB): ' + [math]::Round($mem.Capacity/1GB, 2) | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Speed (MHz): ' + $mem.Speed | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Memory Type: ' + $mem.MemoryType | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Form Factor: ' + $mem.FormFactor | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Bank Label: ' + $mem.BankLabel | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8 }; '' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Graphics Information
call powershell -Command "$videoController = Get-CimInstance -ClassName Win32_VideoController; '=== Graphics Information ===' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; foreach ($gpu in $videoController) { 'Graphics Card:' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Name: ' + $gpu.Name | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Video Processor: ' + $gpu.VideoProcessor | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Driver Version: ' + $gpu.DriverVersion | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; $vramText = '  Video Memory (GB): '; try { Start-Process -FilePath 'dxdiag' -ArgumentList '/t', 'dxtemp.txt' -Wait -WindowStyle Hidden; if (Test-Path 'dxtemp.txt') { $dxContent = Get-Content 'dxtemp.txt'; $memLine = $dxContent | Where-Object { $_ -match 'Dedicated Memory.*?(\d+)\s*MB' }; if ($memLine) { $vramMB = [regex]::Match($memLine[0], '(\d+)\s*MB').Groups[1].Value; $vramGB = [math]::Round([int]$vramMB / 1024, 2); $vramText += [string]$vramGB + ' (DXDIAG)' } else { if ($gpu.AdapterRAM -and $gpu.AdapterRAM -gt 0) { $vramText += [string]([math]::Round($gpu.AdapterRAM/1GB, 2)) + ' (WMI)' } else { $vramText += 'Not Available' } }; Remove-Item 'dxtemp.txt' -ErrorAction SilentlyContinue } else { if ($gpu.AdapterRAM -and $gpu.AdapterRAM -gt 0) { $vramText += [string]([math]::Round($gpu.AdapterRAM/1GB, 2)) + ' (WMI)' } else { $vramText += 'Not Available' } } } catch { if ($gpu.AdapterRAM -and $gpu.AdapterRAM -gt 0) { $vramText += [string]([math]::Round($gpu.AdapterRAM/1GB, 2)) + ' (WMI)' } else { $vramText += 'Not Available' } }; $vramText | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Current Resolution: ' + $gpu.CurrentHorizontalResolution + ' x ' + $gpu.CurrentVerticalResolution | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Refresh Rate: ' + $gpu.CurrentRefreshRate + ' Hz' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8 }; '' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Motherboard Information
call powershell -Command "$baseboard = Get-CimInstance -ClassName Win32_BaseBoard; '=== Motherboard Information ===' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Manufacturer: ' + $baseboard.Manufacturer | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Product: ' + $baseboard.Product | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'Serial Number: ' + $baseboard.SerialNumber | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: BIOS Information
call powershell -Command "$bios = Get-CimInstance -ClassName Win32_BIOS; '=== BIOS Information ===' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'BIOS Manufacturer: ' + $bios.Manufacturer | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'BIOS Version: ' + $bios.Version | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'BIOS Release Date: ' + $bios.ReleaseDate | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; 'SMBIOS Version: ' + $bios.SMBIOSBIOSVersion | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Storage Information
call powershell -Command "$disks = Get-CimInstance -ClassName Win32_DiskDrive; '=== Storage Information ===' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; foreach ($disk in $disks) { 'Disk Drive:' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Model: ' + $disk.Model | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Size (GB): ' + [math]::Round($disk.Size/1GB, 2) | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Interface Type: ' + $disk.InterfaceType | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Partitions: ' + $disk.Partitions | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8 }; '' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Network Adapters Information
call powershell -Command "$networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }; '=== Network Adapters ===' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; foreach ($adapter in $networkAdapters) { 'Network Adapter:' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Name: ' + $adapter.Name | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Manufacturer: ' + $adapter.Manufacturer | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Adapter Type: ' + $adapter.AdapterType | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  MAC Address: ' + $adapter.MACAddress | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8; '  Speed (Mbps): ' + ($adapter.Speed/1000000) | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8 }; '' | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

echo System information has been exported to: %outputFile%

timeout /t 10 /nobreak

endlocal
exit /b
