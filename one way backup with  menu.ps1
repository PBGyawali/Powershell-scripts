###############################################################################
##script:           Sync-Folders.ps1
##
##Description:      Syncs/copies contents of one dir to another. Uses MD5
#+                  checksums to verify the version of the files and if they
#+                  need to be synced.
##Created by:       Prakhar Gyawali
##Creation Date:    July 9, 2023
###############################################################################

# Import the required namespaces for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# FUNCTIONS
function Get-FileMD5 {
    Param([string]$file)
    $md5 = [System.Security.Cryptography.HashAlgorithm]::Create("MD5")
    $IO = New-Object System.IO.FileStream($file, [System.IO.FileMode]::Open)
    $StringBuilder = New-Object System.Text.StringBuilder
    $md5.ComputeHash($IO) | % { [void] $StringBuilder.Append($_.ToString("x2")) }
    $hash = $StringBuilder.ToString() 
    $IO.Dispose()
    return $hash
}

function Is-DirectoryEmpty {
    Param([string]$dir)
    $items = Get-ChildItem -Path $dir
    return ($items.Length -eq 0)
}

# VARIABLES
$DebugPreference = "continue"

# Parameters
$Source_DIR = 'c:\Source\'
$DST_DIR = 'C:\Destination\'


# Create the GUI Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Synced Files"
$form.Size = New-Object System.Drawing.Size(800, 400)


# Create a ListView control to display synced files
$listView = New-Object System.Windows.Forms.ListView
$listView.Dock = [System.Windows.Forms.DockStyle]::Top
$listView.View = [System.Windows.Forms.View]::Details
$listView.CheckBoxes = $true
$listView.Columns.Add("Source File", 200)
$listView.Columns.Add("Destination File", 200)
$form.Controls.Add($listView)

# Create a panel to hold the buttons
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$form.Controls.Add($buttonPanel)

# Create a Start Sync button
$syncButton = New-Object System.Windows.Forms.Button
$syncButton.Text = "Start Sync"
$syncButton.Size = New-Object System.Drawing.Size(70, 10)
$syncButton.Dock = [System.Windows.Forms.DockStyle]::Right
$buttonPanel.Controls.Add($syncButton)

# Create a Select All button
$selectAllButton = New-Object System.Windows.Forms.Button
$selectAllButton.Text = "Select All"
$selectAllButton.Size = New-Object System.Drawing.Size(70, 10)
$selectAllButton.Dock = [System.Windows.Forms.DockStyle]::Left
$buttonPanel.Controls.Add($selectAllButton)


# Create a Select None button
$selectNoneButton = New-Object System.Windows.Forms.Button
$selectNoneButton.Text = "Select None"
$selectNoneButton.Size = New-Object System.Drawing.Size(70, 10)
$selectNoneButton.Dock = [System.Windows.Forms.DockStyle]::Left
$buttonPanel.Controls.Add($selectNoneButton)

# Create a Refresh button
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "Refresh"
$refreshButton.Size = New-Object System.Drawing.Size(100, 30)
$refreshButton.Dock = [System.Windows.Forms.DockStyle]::Right
$buttonPanel.Controls.Add($refreshButton)



# Add event handler for the Select All button click
$selectAllButton.Add_Click({
    foreach ($item in $listView.Items) {
        $item.Checked = $true
    }
})

# Add event handler for the Select None button click
$selectNoneButton.Add_Click({
    foreach ($item in $listView.Items) {
        $item.Checked = $false
    }
})


# Add event handler for the sync button click
$syncButton.Add_Click({
    $selectedFiles = $listView.CheckedItems
    foreach ($file in $selectedFiles) {
        $source = $file.SubItems[0].Text
        $destination = $file.SubItems[1].Text
        Write-Host "Syncing $source to $destination"
        
        $destDir = Split-Path $destination -Parent
        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir | Out-Null
        }
        Copy-Item -Path $source -Destination $destination -Force

        
    }
})


# Add event handler for the refresh button click
$refreshButton.Add_Click({
    $listView.Items.Clear()
    
            # SCRIPT MAIN
        $SourceDirs = Get-ChildItem -Recurse $Source_DIR | Where-Object { $_.PSIsContainer -eq $true } # Get the directories in the source dir.

        $SourceDirs | ForEach-Object { # Loop through the source dir directories
            $source = $_.FullName # Current source dir directory
            Write-Debug $source
            $destination = $source -replace $Source_DIR.Replace('\', '\\'), $DST_DIR # Current destination dir directory
            if (Test-Path $destination) { # If directory exists in destination folder, check if it needs to be synced
                if ($_ -is [System.IO.DirectoryInfo]) { # If the item is a directory
                    $items = Get-ChildItem -Path $source
                    if ($items.Length -eq 0) { # If the directory is empty, it will be synced.
                        Write-Debug "Directory is empty and will be synced."
                        $cpy = $true
                    }
                    else { # If the directory is not empty and already exists in the destination dir, it will be skipped.
                        Write-Debug "Directory already exists in destination folder and will be skipped."
                        $cpy = $false
                    }
                }
                else { # If the item is a file
                    $sourceMD5 = Get-FileMD5 -file $source
                    Write-Debug "Source file hash: $sourceMD5"
                    $destMD5 = Get-FileMD5 -file $destination
                    Write-Debug "Destination file hash: $destMD5"
                    if ($sourceMD5 -eq $destMD5) { # If the MD5 hashes match, the files are the same
                        Write-Debug "File hashes match. File already exists in destination folderand will be skipped."
                        $cpy = $false
                    }
                    else { # If the MD5 hashes are different, copy the file and overwrite the older version in the destination dir
                        Write-Debug "File hashes don't match. File will be copied to destination folder."
                        $cpy = $true
                    }
                }
            }
            else { # If the directory doesn't exist in the destination dir, it will be synced.
                Write-Debug "Directory doesn't exist in destination folder and will be created and synced."
                $cpy = $true
            }
            Write-Debug "Copy is $cpy"
            if ($cpy -eq $true) { # Sync the directory if it needs to be synced.
                Write-Debug "Adding $source to the list of items to be synced."
                $item = New-Object System.Windows.Forms.ListViewItem
                $item.Text = $source + '\'
                $item.SubItems.Add($destination + '\')
                [void]$listView.Items.Add($item)
            }
        }

        $SourceFiles = Get-ChildItem -Recurse $Source_DIR | Where-Object { $_.PSIsContainer -eq $false } # Get the files in the source dir.

        $SourceFiles | ForEach-Object { # Loop through the source dir files
            $source = $_.FullName # Current source dir file
            Write-Debug $source
            $destination = $source -replace $Source_DIR.Replace('\', '\\'), $DST_DIR # Current destination dir file
            if (Test-Path $destination) { # If file exists in destination folder, check MD5 hash
                $sourceMD5 = Get-FileMD5 -file $source
                Write-Debug "Source file hash: $sourceMD5"
                $destMD5 = Get-FileMD5 -file $destination
                Write-Debug "Destination file hash: $destMD5"
                if ($sourceMD5 -eq $destMD5) { # If the MD5 hashes match, the files are the same
                    Write-Debug "File hashes match. File already exists in destination folder and will be skipped."
                    $cpy = $false
                }
                else { # If the MD5 hashes are different, copy the file and overwrite the older version in the destination dir
                    $cpy = $true
                    Write-Debug "File hashes don't match. File will be copied to destination folder."
                }
            }
            else { # If the file doesn't exist in the destination dir, it will be copied.
                Write-Debug "File doesn't exist in destination folder and will be copied."
                $cpy = $true
            }
            Write-Debug "Copy is $cpy"
            if ($cpy -eq $true) { # Copy the file if it needs to be synced.
                Write-Debug "Adding $source to the list of items to be synced."
                $item = New-Object System.Windows.Forms.ListViewItem
                $item.Text = $source
                $item.SubItems.Add($destination)
                [void]$listView.Items.Add($item)
            }
        }
})

$form.Add_Shown({
# Automatically click the Refresh button when the form is first shown
$refreshButton.PerformClick()
})


# Show the GUI form
[void]$form.ShowDialog()