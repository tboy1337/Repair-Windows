# Video File Organizer Script
# This script organizes .mp4 and .mkv files by creating folders with the same name as the file
# and moving the video file into that folder, unless it's already in a folder with the same name

# Get the current directory where the script is run from
$rootPath = Get-Location

Write-Host "Starting video file organization in: $rootPath" -ForegroundColor Green
Write-Host "Scanning for .mp4 and .mkv files in all subfolders..." -ForegroundColor Yellow

# Get all .mp4 and .mkv files recursively
$videoFiles = Get-ChildItem -Path $rootPath -Recurse -Include "*.mp4", "*.mkv" -File

if ($videoFiles.Count -eq 0) {
    Write-Host "No .mp4 or .mkv files found." -ForegroundColor Yellow
    exit
}

Write-Host "Found $($videoFiles.Count) video file(s) to process." -ForegroundColor Cyan

foreach ($file in $videoFiles) {
    # Get the file name without extension for the folder name
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    
    # Get the directory where the file is currently located
    $currentDirectory = $file.Directory
    
    # Check if the file is already in a folder with the same name
    if ($currentDirectory.Name -eq $fileNameWithoutExtension) {
        Write-Host "SKIP: '$($file.Name)' is already in folder '$($currentDirectory.Name)'" -ForegroundColor Gray
        continue
    }
    
    # Create the target folder path
    $targetFolderPath = Join-Path -Path $currentDirectory.FullName -ChildPath $fileNameWithoutExtension
    
    try {
        # Check if the target folder already exists
        if (-not (Test-Path -Path $targetFolderPath)) {
            # Create the folder
            New-Item -Path $targetFolderPath -ItemType Directory -Force | Out-Null
            Write-Host "CREATED: Folder '$fileNameWithoutExtension' in '$($currentDirectory.FullName)'" -ForegroundColor Green
        } else {
            Write-Host "EXISTS: Folder '$fileNameWithoutExtension' already exists" -ForegroundColor Yellow
        }
        
        # Move the file to the target folder
        $targetFilePath = Join-Path -Path $targetFolderPath -ChildPath $file.Name
        
        # Check if a file with the same name already exists in the target folder
        if (Test-Path -Path $targetFilePath) {
            Write-Host "WARNING: File '$($file.Name)' already exists in target folder. Skipping move." -ForegroundColor Red
        } else {
            Move-Item -Path $file.FullName -Destination $targetFilePath -Force
            Write-Host "MOVED: '$($file.Name)' to '$targetFolderPath'" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "ERROR: Failed to process '$($file.Name)': $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nVideo file organization complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
