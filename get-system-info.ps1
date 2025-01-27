# Get current timestamp for the filename
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputFile = "SystemInfo_$timestamp.txt"

# Create an array to store the information
$systemInfo = @()

$systemInfo += "=== System Information Report ==="
$systemInfo += "Generated on: $(Get-Date)"
$systemInfo += "`n=== Computer System ==="
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$systemInfo += "Manufacturer: $($computerSystem.Manufacturer)"
$systemInfo += "Model: $($computerSystem.Model)"
$systemInfo += "System Name: $($computerSystem.Name)"
$systemInfo += "Domain: $($computerSystem.Domain)"
$systemInfo += "Total Physical Memory (GB): $([math]::Round($computerSystem.TotalPhysicalMemory/1GB, 2))"

$systemInfo += "`n=== Operating System ==="
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$systemInfo += "OS Name: $($os.Caption)"
$systemInfo += "Version: $($os.Version)"
$systemInfo += "Build Number: $($os.BuildNumber)"
$systemInfo += "Architecture: $($os.OSArchitecture)"
$systemInfo += "Install Date: $($os.InstallDate)"
$systemInfo += "Last Boot Time: $($os.LastBootUpTime)"

$systemInfo += "`n=== Processor Information ==="
$processor = Get-CimInstance -ClassName Win32_Processor
$systemInfo += "CPU: $($processor.Name)"
$systemInfo += "Description: $($processor.Description)"
$systemInfo += "Manufacturer: $($processor.Manufacturer)"
$systemInfo += "Number of Cores: $($processor.NumberOfCores)"
$systemInfo += "Number of Logical Processors: $($processor.NumberOfLogicalProcessors)"
$systemInfo += "Max Clock Speed (GHz): $([math]::Round($processor.MaxClockSpeed/1000, 2))"
$systemInfo += "L2 Cache Size (KB): $($processor.L2CacheSize)"
$systemInfo += "L3 Cache Size (KB): $($processor.L3CacheSize)"

$systemInfo += "`n=== Memory Information ==="
$memory = Get-CimInstance -ClassName Win32_PhysicalMemory
foreach ($mem in $memory) {
    $systemInfo += "Memory Module:"
    $systemInfo += "  Manufacturer: $($mem.Manufacturer)"
    $systemInfo += "  Capacity (GB): $([math]::Round($mem.Capacity/1GB, 2))"
    $systemInfo += "  Speed (MHz): $($mem.Speed)"
    $systemInfo += "  Memory Type: $($mem.MemoryType)"
    $systemInfo += "  Form Factor: $($mem.FormFactor)"
    $systemInfo += "  Bank Label: $($mem.BankLabel)"
}

$systemInfo += "`n=== Graphics Information ==="
$videoController = Get-CimInstance -ClassName Win32_VideoController
foreach ($gpu in $videoController) {
    $systemInfo += "Graphics Card:"
    $systemInfo += "  Name: $($gpu.Name)"
    $systemInfo += "  Video Processor: $($gpu.VideoProcessor)"
    $systemInfo += "  Driver Version: $($gpu.DriverVersion)"
    $systemInfo += "  Video Memory (GB): $([math]::Round($gpu.AdapterRAM/1GB, 2))"
    $systemInfo += "  Current Resolution: $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)"
    $systemInfo += "  Refresh Rate: $($gpu.CurrentRefreshRate) Hz"
}

$systemInfo += "`n=== Motherboard Information ==="
$baseboard = Get-CimInstance -ClassName Win32_BaseBoard
$systemInfo += "Manufacturer: $($baseboard.Manufacturer)"
$systemInfo += "Product: $($baseboard.Product)"
$systemInfo += "Serial Number: $($baseboard.SerialNumber)"

$systemInfo += "`n=== BIOS Information ==="
$bios = Get-CimInstance -ClassName Win32_BIOS
$systemInfo += "BIOS Manufacturer: $($bios.Manufacturer)"
$systemInfo += "BIOS Version: $($bios.Version)"
$systemInfo += "BIOS Release Date: $($bios.ReleaseDate)"
$systemInfo += "SMBIOS Version: $($bios.SMBIOSBIOSVersion)"

$systemInfo += "`n=== Storage Information ==="
$disks = Get-CimInstance -ClassName Win32_DiskDrive
foreach ($disk in $disks) {
    $systemInfo += "Disk Drive:"
    $systemInfo += "  Model: $($disk.Model)"
    $systemInfo += "  Size (GB): $([math]::Round($disk.Size/1GB, 2))"
    $systemInfo += "  Interface Type: $($disk.InterfaceType)"
    $systemInfo += "  Partitions: $($disk.Partitions)"
}

$systemInfo += "`n=== Network Adapters ==="
$networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }
foreach ($adapter in $networkAdapters) {
    $systemInfo += "Network Adapter:"
    $systemInfo += "  Name: $($adapter.Name)"
    $systemInfo += "  Manufacturer: $($adapter.Manufacturer)"
    $systemInfo += "  Adapter Type: $($adapter.AdapterType)"
    $systemInfo += "  MAC Address: $($adapter.MACAddress)"
    $systemInfo += "  Speed (Mbps): $($adapter.Speed/1000000)"
}

# Export information to file
$systemInfo | Out-File -FilePath $outputFile -Encoding UTF8

# Display completion message
Write-Host "System information has been exported to: $outputFile"

Start-Sleep -Seconds 5
exit
