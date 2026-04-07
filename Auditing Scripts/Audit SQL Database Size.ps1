# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"
# Script Variable
$display = $env:displayCurrentSizes
# SQL backup file path. Check for both locations and select the correct one. Delete the E:\ entry after DOE's server.
$possiblePaths = @("D:\SQL Backups", "D:\SQL Backup", "D:\SQL Backup Master", "E:\SQL Backup")
$SQLBackupFiles = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1


# Exit if the SQL Backup File path doens't exit.
if ($SQLBackupFiles -eq $null -or -not (Test-Path $SQLBackupFiles)) {
  Write-Host "No SQL Backups folder detected. Exiting script..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No SQL Backups folder detected. Exiting script..."
  exit 1
}

# Assembly needed to read the compressed files
Add-Type -Assembly "System.IO.Compression.FileSystem"

# Function to process a group of .zip files in a given location
function Process-ZipGroups {
  param (
    [string]$LocationLabel,
    [System.IO.FileInfo[]]$ZipFiles
  )

  # Group zip files by their name prefix
  $groups = $ZipFiles | Group-Object { [regex]::Match($_.Name, '^[^-]+').Value }

  if ($display -eq $true) { Write-Host "Folder: $LocationLabel" }

  foreach ($group in $groups) {
    # Get the latest .zip file in this name group
    $latestZip = $group.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $totalUncompressedSize = 0

    # Open the zip file in read mode
    $archive = [System.IO.Compression.ZipFile]::OpenRead($latestZip.FullName)

    # Get the uncompressed size of each entry
    foreach ($entry in $archive.Entries) {
      $totalUncompressedSize += $entry.Length
    }

    # Release the file lock
    $archive.Dispose()

    # Convert to readable sizes
    $totalUncompressedSizeMB = [math]::Round($totalUncompressedSize / 1MB, 2)
    $totalUncompressedSizeGB = [math]::Round($totalUncompressedSize / 1GB, 3)

    if ($display -eq $true) {
      Write-Host "----------------------------------------"
      Write-Host "  Prefix   : $($group.Name)"
      Write-Host "  File     : $($latestZip.Name)"
      Write-Host "  Created  : $($latestZip.LastWriteTime)"
      Write-Host "  Size     : $totalUncompressedSizeMB MB"
      Write-Host "  Size     : $totalUncompressedSizeGB GB"
    }

    # Warn if uncompressed size exceeds 9GB
    if ($totalUncompressedSize -gt 9GB) {
      Write-Warning "The [$($group.Name)] database size exceeds 9GB! Current size: $totalUncompressedSizeGB GB"
      exit 0
    }
    # Warn if uncompressed size exceeds 48GB
    if ($totalUncompressedSize -gt 48GB) {
      Write-Warning "The [$($group.Name)] database size exceeds 48GB! Current size: $totalUncompressedSizeGB GB"
      exit 0
    }
  }
}

# Check if there are any subfolders
$subFolders = Get-ChildItem -Path $SQLBackupFiles -Directory

if ($subFolders) {
  # If there are subfolders, sort through reach subfolder and pull the latest backup .zip file
  foreach ($folder in $subFolders) {
    $allZips = Get-ChildItem -Path $folder.FullName -Filter "*.zip"

    if (-not $allZips) {
      if ($display -eq $true) { Write-Host "[$($folder.Name)] No .zip files found, skipping." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No .zip files found in [$($folder.Name)], skipping."
      continue
    }

    Process-ZipGroups -LocationLabel $folder.Name -ZipFiles $allZips
  }
} else {
    # If there are no sub folders check backups in the main SQL Backups folder
    $allZips = Get-ChildItem -Path $SQLBackupFiles -Filter "*.zip"

    if (-not $allZips) {
      if ($display -eq $true) { Write-Host "No .zip files found in $SQLBackupFiles. Exiting script..." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No .zip files found in root backup folder. Exiting script..."
      exit 1
    }

    Process-ZipGroups -LocationLabel (Split-Path $SQLBackupFiles -Leaf) -ZipFiles $allZips
}