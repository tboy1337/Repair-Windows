$ErrorActionPreference = "Stop"

$extensions = @(
    "*.py", "*.txt", "*.md", "*.yml", "*.yaml", "*.json", "*.ini", 
    "*.cfg", "*.conf", "*.html", "*.css", "*.js", "*.ps1", "*.sh"
)

$excludeDirs = @(
    ".git", "__pycache__", "*.egg-info", "build", "dist", "venv", "env"
)

# Build exclude pattern for directories
$excludePattern = ($excludeDirs | ForEach-Object { "\\$_\\" }) -join "|"

# Find all text files to convert
$files = @()
foreach ($ext in $extensions) {
    $files += Get-ChildItem -Path . -Filter $ext -Recurse | Where-Object {
        $path = $_.FullName -replace "\\", "/"
        $path -notmatch $excludePattern
    }
}

$converted = 0
$errors = @()

foreach ($file in $files) {
    try {
        Write-Host "Converting $($file.FullName)"
        
        # Read file content
        $content = Get-Content -Path $file.FullName -Raw
        
        # Skip binary or empty files
        if ($null -eq $content) { continue }
        
        # Convert to CRLF (Windows line endings)
        $content = $content -replace "`r`n", "`n" -replace "`r", "`n" -replace "`n", "`r`n"
        
        # Write content back to file
        [System.IO.File]::WriteAllText($file.FullName, $content)
        
        $converted++
    } catch {
        $errors += "$($file.FullName): $_"
    }
}

Write-Host "`nConversion complete. $converted files processed."

if ($errors.Count -gt 0) {
    Write-Host "`nThe following errors occurred:"
    $errors | ForEach-Object { Write-Host "- $_" }
} 