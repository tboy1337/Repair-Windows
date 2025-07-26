param(
    [Parameter(Mandatory=$false)]
    [string]$SourcePath = ".",
    [Parameter(Mandatory=$false)]
    [string]$SevenZipPath = "7z.exe"
)

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if 7-Zip is available
function Test-SevenZip {
    param([string]$Path)
    
    try {
        $null = & $Path 2>&1
        return $true
    }
    catch {
        return $false
    }
}

# Function to get archive files
function Get-ArchiveFiles {
    param([string]$Path)
    
    $extensions = @("*.7z", "*.zip", "*.rar", "*.tar", "*.gz", "*.bz2", "*.xz", "*.tar.gz", "*.tar.bz2", "*.tar.xz")
    $files = @()
    
    foreach ($ext in $extensions) {
        $files += Get-ChildItem -Path $Path -Filter $ext -File
    }
    
    return $files
}

# Function to get archive contents listing
function Get-ArchiveContents {
    param(
        [string]$ArchivePath,
        [string]$SevenZipExe
    )
    
    try {
        $result = & $SevenZipExe l "$ArchivePath" -slt 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
        else {
            return $null
        }
    }
    catch {
        return $null
    }
}

# Function to check if archive has single top-level folder with same name
function Test-SingleTopLevelFolder {
    param(
        [string]$ArchivePath,
        [string]$ArchiveBaseName,
        [string]$SevenZipExe
    )
    
    $contents = Get-ArchiveContents -ArchivePath $ArchivePath -SevenZipExe $SevenZipExe
    if (-not $contents) {
        return $false
    }
    
    # Parse the listing to find top-level entries
    $topLevelEntries = @()
    $inFileSection = $false
    
    foreach ($line in $contents) {
        if ($line -match "^----------") {
            $inFileSection = -not $inFileSection
            continue
        }
        
        if (-not $inFileSection) {
            continue
        }
        
        # Look for Path = lines in the detailed listing
        if ($line -match "^Path = (.+)$") {
            $path = $matches[1]
            
            # Get the top-level entry (first part before any slash/backslash)
            if ($path -match "^([^/\\]+)") {
                $topLevelEntry = $matches[1]
                if ($topLevelEntries -notcontains $topLevelEntry) {
                    $topLevelEntries += $topLevelEntry
                }
            }
        }
    }
    
    # Check if there's exactly one top-level entry and it's a folder with similar name
    if ($topLevelEntries.Count -eq 1) {
        $folderName = $topLevelEntries[0]
        
        # Check if the folder name matches the archive name (case-insensitive)
        if ($folderName -eq $ArchiveBaseName -or $folderName -eq $ArchiveBaseName.Replace('_', ' ') -or $folderName -eq $ArchiveBaseName.Replace(' ', '_')) {
            return $true
        }
        
        # Also check for close matches (removing common suffixes/prefixes)
        $cleanArchiveName = $ArchiveBaseName -replace '[\-_\s]*(backup|archive|compressed)[\-_\s]*', '' -replace '[\-_\s]+', ''
        $cleanFolderName = $folderName -replace '[\-_\s]*(backup|archive|compressed)[\-_\s]*', '' -replace '[\-_\s]+', ''
        
        if ($cleanArchiveName -eq $cleanFolderName) {
            return $true
        }
    }
    
    return $false
}

# Function to extract archive
function Expand-Archive {
    param(
        [string]$ArchivePath,
        [string]$DestinationPath,
        [string]$SevenZipExe,
        [bool]$FlattenSingleFolder = $false
    )
    
    try {
        if ($FlattenSingleFolder) {
            # Extract to a temporary subdirectory first
            $tempDir = Join-Path $DestinationPath "_temp_extract"
            
            # Remove temp directory if it exists
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force
            }
            
            # Extract to temp directory
            $result = & $SevenZipExe x "$ArchivePath" -o"$tempDir" -y 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                # Find the single top-level folder
                $topLevelItems = Get-ChildItem -Path $tempDir
                if ($topLevelItems.Count -eq 1 -and $topLevelItems[0].PSIsContainer) {
                    # Move contents of the single folder to destination
                    $singleFolderPath = $topLevelItems[0].FullName
                    $items = Get-ChildItem -Path $singleFolderPath -Force
                    
                    foreach ($item in $items) {
                        $destPath = Join-Path $DestinationPath $item.Name
                        Move-Item -Path $item.FullName -Destination $destPath -Force
                    }
                    
                    Write-ColorOutput "Flattened single top-level folder to avoid nesting" "Cyan"
                } else {
                    # Fallback: move everything from temp to destination
                    $items = Get-ChildItem -Path $tempDir -Force
                    foreach ($item in $items) {
                        $destPath = Join-Path $DestinationPath $item.Name
                        Move-Item -Path $item.FullName -Destination $destPath -Force
                    }
                }
                
                # Clean up temp directory
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                return $true
            }
            else {
                Write-ColorOutput "Error extracting $ArchivePath`: $result" "Red"
                # Clean up temp directory
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                return $false
            }
        }
        else {
            # Normal extraction
            $result = & $SevenZipExe x "$ArchivePath" -o"$DestinationPath" -y 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                return $true
            }
            else {
                Write-ColorOutput "Error extracting $ArchivePath`: $result" "Red"
                return $false
            }
        }
    }
    catch {
        Write-ColorOutput "Exception extracting $ArchivePath`: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main script execution
Write-ColorOutput "=== 7-Zip Archive Unpacker ===" "Cyan"
Write-ColorOutput "Source Path: $SourcePath" "Yellow"

# Validate source path
if (-not (Test-Path $SourcePath)) {
    Write-ColorOutput "Error: Source path '$SourcePath' does not exist!" "Red"
    exit 1
}

# Check if 7-Zip is available
$sevenZipPaths = @(
    $SevenZipPath,
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe",
    "${env:ProgramFiles}\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
)

$workingSevenZip = $null
foreach ($path in $sevenZipPaths) {
    if (Test-Path $path) {
        if (Test-SevenZip $path) {
            $workingSevenZip = $path
            break
        }
    }
}

if (-not $workingSevenZip) {
    Write-ColorOutput "Error: 7-Zip executable not found! Please install 7-Zip or specify the path with -SevenZipPath parameter." "Red"
    Write-ColorOutput "Download from: https://www.7-zip.org/" "Yellow"
    exit 1
}

Write-ColorOutput "Using 7-Zip: $workingSevenZip" "Green"

# Get all archive files
Write-ColorOutput "`nScanning for archive files..." "Yellow"
$archiveFiles = Get-ArchiveFiles -Path $SourcePath

if ($archiveFiles.Count -eq 0) {
    Write-ColorOutput "No archive files found in '$SourcePath'" "Yellow"
    exit 0
}

Write-ColorOutput "Found $($archiveFiles.Count) archive file(s)" "Green"

# Process each archive
$successCount = 0
$failCount = 0

foreach ($archive in $archiveFiles) {
    Write-ColorOutput "`n--- Processing: $($archive.Name) ---" "Cyan"
    
    # Get the archive name without extension for folder name
    $folderName = [System.IO.Path]::GetFileNameWithoutExtension($archive.Name)
    
    # Handle double extensions like .tar.gz
    if ($folderName -match '\.(tar|tar\.gz|tar\.bz2|tar\.xz)$') {
        $folderName = [System.IO.Path]::GetFileNameWithoutExtension($folderName)
    }
    
    $destinationFolder = Join-Path $SourcePath $folderName
    
    # Check if archive has single top-level folder with same/similar name
    Write-ColorOutput "Analyzing archive structure..." "Yellow"
    $shouldFlatten = Test-SingleTopLevelFolder -ArchivePath $archive.FullName -ArchiveBaseName $folderName -SevenZipExe $workingSevenZip
    
    if ($shouldFlatten) {
        Write-ColorOutput "Detected single top-level folder with similar name - will flatten to avoid nesting" "Cyan"
    }
    
    # Check if folder already exists and create if needed
    if (Test-Path $destinationFolder) {
        Write-ColorOutput "Folder '$folderName' already exists. Extracting into existing folder..." "Yellow"
    } else {
        Write-ColorOutput "Creating folder: $folderName" "Green"
        try {
            New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-ColorOutput "Error creating folder '$folderName': $($_.Exception.Message)" "Red"
            $failCount++
            continue
        }
    }
    
    # Extract archive
    Write-ColorOutput "Extracting archive..." "Yellow"
    if (Expand-Archive -ArchivePath $archive.FullName -DestinationPath $destinationFolder -SevenZipExe $workingSevenZip -FlattenSingleFolder $shouldFlatten) {
        Write-ColorOutput "Successfully extracted: $($archive.Name)" "Green"
        $successCount++
    } else {
        $failCount++
    }
}

# Summary
Write-ColorOutput "`n=== Extraction Summary ===" "Cyan"
Write-ColorOutput "Successfully extracted: $successCount archive(s)" "Green"
if ($failCount -gt 0) {
    Write-ColorOutput "Failed to extract: $failCount archive(s)" "Red"
}

Write-ColorOutput "`nScript completed!" "Cyan"

if ($failCount -eq 0) {
    exit 0
} else {
    exit 1
}
