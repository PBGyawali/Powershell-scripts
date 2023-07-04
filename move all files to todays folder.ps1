# Get the current date
$currentDate = Get-Date -Format "yyyyMMdd"

# Get the current folder where the script is located
$currentFolder = Split-Path -Path $MyInvocation.MyCommand.Path

# Create the destination folder using the current date
$destinationFolder = Join-Path -Path $currentFolder -ChildPath $currentDate

# Create the destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
    New-Item -Path $destinationFolder -ItemType Directory | Out-Null
}

# Get all the files in the current folder
$files = Get-ChildItem -Path $currentFolder -File

# Move each file to the destination folder
$files | ForEach-Object {
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $_.Name
    Move-Item -Path $_.FullName -Destination $destinationPath -Force
}

Write-Host "All files moved to $destinationFolder"
