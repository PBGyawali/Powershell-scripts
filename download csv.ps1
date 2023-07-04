# Specify the URL of the file to download
$downloadUrl = "https://sample-videos.com/csv/Sample-Spreadsheet-10-rows.csv"

# Generate a unique file name based on the current date and time
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$fileName = "file_$timestamp.csv"

# Specify the destination folder to save the downloaded file
$destinationFolder = "c:\Downloads"

# Create the destination path
$destinationPath = Join-Path -Path $destinationFolder -ChildPath $fileName

# Create the destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
}

# Create a web client object to download the file
$client = New-Object System.Net.WebClient

try {
    # Download the file and save it to the destination path
    $client.DownloadFile($downloadUrl, $destinationPath)
    
    # Check if the downloaded file is a valid CSV file
    if ((Get-Item $destinationPath).Extension -ne ".csv") {
        throw "The downloaded file is not a CSV file."
    }
    
    # Display a success message
    Write-Host "File downloaded successfully. Saved as: $destinationPath"
} catch {
    # Display an error message if any exceptions occur
    Write-Host "Error downloading the file: $_"
}

# Clean up the web client object
$client.Dispose()

# Prompt the user to press Enter before closing the console window
Read-Host "Press Enter to exit..."
