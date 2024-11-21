# The log path for this script.
$logPath = "C:\DDS\Logs\Audit.log"

# Gets the time and date of the most recent backup.
function Get-MostRecentDateTime {
  param ( [array]$Bucket )
  
  # Extract the date and time columns, combine them, convert to DateTime, and find the most recent.
  $mostRecent = $Bucket |
    ForEach-Object {
      # Split the string into columns by whitespace.
      $columns = $_ -split '\s+'
      # Combine the 3rd (date) and 4th (time) columns.
      $dateTimeString = "$($columns[2]) $($columns[3])"
      # Convert the string to a DateTime object.
      [datetime]::Parse($dateTimeString)
    } | Sort-Object -Descending | Select-Object -First 1

  return $mostRecent
}

# Gets the total count of the full backups for the bucket.
function Get-FullBackupCount {
  param ( [array]$Bucket )
  
  # Filter lines that end with '00-00.MRIMG' and count them
  $fullBackupCount = $Bucket | Where-Object { $_ -match '00-00\.MRIMG$' } | Measure-Object | Select-Object -ExpandProperty Count

  return $fullBackupCount
}

# Download the b2v3-windows.exe file.
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri "https://github.com/Backblaze/B2_Command_Line_Tool/releases/download/v4.1.0/b2v3-windows.exe" -OutFile "C:\DDS\b2v3-windows.exe"
  New-Item "C:\DDS\Backblaze_Audit.txt" -Force | Out-Null
} catch {
  Write-Host "Failed to download the b2v3-windows.exe file: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to download the b2v3-windows.exe file: $_"

  exit 1
}

# Convert the script variables
$id = $env:masterAccountId
$key = $env:masterApplicationKey

# Get into our account.
C:\DDS\b2v3-windows.exe account authorize 620624e105a9 00141484f95b992dac0e1e549e51187b3c2b17e587 | Out-Null

# Pull the list of buckets.
$buckets = C:\DDS\b2v3-windows.exe bucket list | Where-Object {$_ -notlike "*b2-snapshots*" -and $_ -notlike "*Baxter*"} | ForEach-Object { ($_ -split ' ')[4] }

# Go through each bucket and check for repositories, full backups, missing backups, and too many incremental backups.
foreach ($bucket in $buckets) {
  # Pull the repositories and files for the bucket.
	$repositories = C:\DDS\b2v3-windows.exe ls $bucket
	$files = C:\DDS\b2v3-windows.exe ls $bucket -r --long

  # Creating a generic list to start assembling the report.
  $report = New-Object System.Collections.Generic.List[string]
  $report.Add("$bucket`n")

  # Check on the number of repositores. Notify if there are multiple repositories with the same name. Example: Repository1-Mar2024 & Repository1-April2024
	if ($repositories) {
    $report.Add("Number of repositories: $($repositories.count)`n")
    
    $repositoryErrors = $false
		for ($i=1; $i -lt 5; $i++) {
			if (($repositories | Where-Object { $_ -match "^Repository$i-" }).count -gt 1) {
        $report.Add("WARNING: Repository$i has more than 1 folder in Backblaze. Please investigate.`n")
        $repositoryErrors = $true
			}
		}
	}
  if ($files) {
    # Get the number of full backups in the bucket.
    $fullBackups = Get-FullBackupCount -Bucket $files
    if ($fullBackups) {
      $report.Add("Number of full backups: $fullBackups`n")
      if (($repositories.Count * 2 -ne $fullBackups) -and ($repositoryErrors -eq $false)) {
        $report.Add("WARNING: This bucket doesn't have the expected number of full backups. Please investigate.`n")
      }
    }

    # Gets the current date, minus two days.
    $goodDate = (Get-Date).AddDays(-2)
    $lastBackupDate = Get-MostRecentDateTime -Bucket $files

    if ($lastBackupDate -lt $goodDate) {
      $report.Add("Date of last backup: $lastBackupDate`n")
      $report.Add("WARNING: The last backup was uploaded more than two days ago. Please investigate.`n")
    } else {
      $report.Add("Date of last backup: $lastBackupDate`n")
    }

    # Initialize a hash table to track incrementals for each full backup ID.
    $incrementalCounts = @{}

    # Process each line in the data.
    foreach ($line in $files) {
      # Split the line into parts and extract the filename.
      $columns = $line -split '\s+'
      $fileName = $columns[-1] # Last column is the file path.
  
      # Extract the backup ID and incrementals from the filename.
      if ($fileName -match '^(.+)-(\d+)-\2\.MRIMG$') {
        $backupID = $matches[1]
        $incrementalNumber = [int]$matches[2]

        # Track counts of incrementals for each backup ID.
        if (-not $incrementalCounts.ContainsKey($backupID)) {
          $incrementalCounts[$backupID] = 0
        }

        # Only count incrementals (not the full backup itself).
        if ($incrementalNumber -gt 0) {
          $incrementalCounts[$backupID]++
        }
      }
    }

    # Check if any backup ID exceeds the allowed number of incrementals.
    foreach ($key in $incrementalCounts.Keys) {
      if ($incrementalCounts[$key] -gt 45) {
        $report.Add("WARNING: The backup '$key' currently has $($incrementalCounts[$key]) incremental backups. Please investigate.`n")
      }
    }
  }
  
  # Show the report for the bucket and add it to the text file.
  Write-Host "$report"
  Add-Content -Path "C:\DDS\Backblaze_Audit.txt" -Value "$report"
}

# Clean up after ourselves.
try {
  rm "C:\DDS\b2v3-windows.exe" -Force
} catch {
  Write-Host "Unable to remove the b2v3-windows.exe file."
}