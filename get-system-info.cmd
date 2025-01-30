@echo off
setlocal

:: Get current timestamp for the filename
for /f "tokens=2 delims==." %%a in ('wmic os get localdatetime /value') do set datetime=%%a
set timestamp=%datetime:~0,8%-%datetime:~8,6%
set outputFile=SystemInfo_%timestamp%.txt

:: Call PowerShell to execute the commands
echo === System Information Report === > "%outputFile%"
echo Generated on: %date% %time% >> "%outputFile%"
echo. >> "%outputFile%"

:: Computer System Information
call powershell -Command "Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer,Model,Name,Domain,@{Name='TotalPhysicalMemoryGB';Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 2)}} | Format-List | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Operating System Information
call powershell -Command "Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture,InstallDate,LastBootUpTime | Format-List | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Processor Information
call powershell -Command "Get-CimInstance -ClassName Win32_Processor | Select-Object Name,Description,Manufacturer,NumberOfCores,NumberOfLogicalProcessors,@{Name='MaxClockSpeedGHz';Expression={[math]::Round($_.MaxClockSpeed/1000, 2)}},L2CacheSize,L3CacheSize | Format-List | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Memory Information
call powershell -Command "Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object Manufacturer,@{Name='CapacityGB';Expression={[math]::Round($_.Capacity/1GB, 2)}},Speed,MemoryType,FormFactor,BankLabel | Format-List | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Graphics Information
call powershell -Command "Get-CimInstance -ClassName Win32_VideoController | Select-Object Name,VideoProcessor,DriverVersion,@{Name='AdapterRAMGB';Expression={[math]::Round($_.AdapterRAM/1GB, 2)}},@{Name='CurrentResolution';Expression={'$($_.CurrentHorizontalResolution) x $($_.CurrentVerticalResolution)'}},CurrentRefreshRate | Format-List | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Motherboard Information
call powershell -Command "Get-CimInstance -ClassName Win32_BaseBoard | Select-Object Manufacturer,Product,SerialNumber | Format-List | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: BIOS Information
call powershell -Command "Get-CimInstance -ClassName Win32_BIOS | Select-Object Manufacturer,Version,ReleaseDate,SMBIOSBIOSVersion | Format-List | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Storage Information
call powershell -Command "Get-CimInstance -ClassName Win32_DiskDrive | Select-Object Model,@{Name='SizeGB';Expression={[math]::Round($_.Size/1GB, 2)}},InterfaceType,Partitions | Format-List | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Network Adapters Information
call powershell -Command "Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true } | Select-Object Name,Manufacturer,AdapterType,MACAddress,@{Name='SpeedMbps';Expression={$_.Speed/1000000}} | Format-List | Out-File -FilePath '%outputFile%' -Append -Encoding UTF8"

:: Display completion message
echo System information has been exported to: %outputFile%

timeout /t 5 /nobreak

exit
