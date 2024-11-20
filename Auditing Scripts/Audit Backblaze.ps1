# The log path for this script.
$logPath = "C:\DDS\Logs\Audit.log"

# All of the Backblaze buckets.
$buckets = @(
  "85West-Dental", "Anderson-Family-Dentistry", "Baker-Dental-Studio",
  "Beechtree-Family-Dentistry", "Belmont-Dentistry",
  "Big-Rapids", "Brian-Buurma", "Carroll-Family-Dentistry",
  "Chambers-Dental", "Clark-VanOverloop", "DDS-Integration2019",
  "Dentists-on-Eastcastle", "Dorr-Family-Dentistry", "Dyras-Dental",
  "Eric-Hull-DDS", "Erick-Perroud-DDS", "esmiles", "Family-Dentistry-Of-Caledonia-2024",
  "Forest-Hills-Endodontics", "Gaslight-Family-Dentistry", "Grady-Cosmetic-Dentistry",
  "Grand-River-Endo", "Grandville-DHC", "Grandville-Endo",
  "Greenville-Family-Dental", "HILARY-LANE-DDS-FAMILY-DENTISTRY", "Hastings-Family-Dental-Care",
  "Heather-H-Charchut", "Herrmann-DDS", "Hudsonville-Family-Dentistry",
  "Ivanrest-Family-Dentistry", "JCL-Perio", "Keefer-Family-Dentistry",
  "Kent-City-Dental-Center", "Knapp-Orthodontics", "Knowlton-Family-Dentistry",
  "Lange-Family-Dental-Care", "Langhorst-Family-Dentistry", "Lifetime-Eyecare",
  "Lowell-Dental-Care", "MI-Root-Family-Dental", "Mailloux-Dentistry",
  "Marshall-Family-Dentistry", "McDougal-Dental", "Meade-Zolman",
  "Michael-Miller-DDS", "Michael-P-Campeau-DDS", "Miller-Ortho",
  "Nichols-Family-Dentistry", "North-Park-Family-Dental", "Northview-Family-Dentistry",
  "OMSGGR-Alpine", "OMSGGR-Caledonia", "Paul-Winn-DDS",
  "posthumus-family-dentistry", "Powell-Orthodontics", "Ravenna-Family-Dentistry", "Reed-City",
  "Richard-A-Oppenlander", "River-Ridge-Dentistry", "Rivertown-Dental",
  "Smith-Dental-Team", "Snyder-Family-Dentistry", "Sparta-Dental-Care",
  "Standale-Dental", "Stanton-Family-Dental-Care", "Strobel-Family-Dentistry",
  "Van-Timmeren-Family-Dentistry", "VanHaren-Dentistry", "VerMeulen-DDS",
  "Vitek-Family-Dentistry", "weidenfeller", "West-Michigan-Endodontists", "West-Michigan-Eyecare-Associates",
  "West-Michigan-Pediatric-Dentistry", "Westshore-Endo-Holland", "Westshore-Endodontics-Norton-Shores"
)


function Get-MostRecentDateTime {
    param ( [array]$Bucket )
    
    # Extract the date and time columns, combine them, convert to DateTime, and find the most recent
    $mostRecent = $Bucket |
        ForEach-Object {
            # Split the string into columns by whitespace
            $columns = $_ -split '\s+'
            # Combine the 3rd (date) and 4th (time) columns
            $dateTimeString = "$($columns[2]) $($columns[3])"
            # Convert the string to a DateTime object
            [datetime]::Parse($dateTimeString)
        } | Sort-Object -Descending | Select-Object -First 1

    return $mostRecent
}

function Get-FullBackupCount {
    param ( [array]$Bucket )
    
    # Filter lines that end with '00-00.MRIMG' and count them
    $fullBackupCount = $Bucket | Where-Object { $_ -match '00-00\.MRIMG$' } | Measure-Object | Select-Object -ExpandProperty Count

    return $fullBackupCount
}

# Download the b2v3-windows.exe file.
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri "https://github.com/Backblaze/B2_Command_Line_Tool/releases/download/v4.1.0/b2v3-windows.exe" -OutFile "$env:temp/b2v3-windows.exe"
} catch {
  Write-Host "Failed to download the b2v3-windows.exe file: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to download the b2v3-windows.exe file: $_"

  exit 1
}

C:\Users\bradweiand\AppData\Local\Temp\b2v3-windows.exe account authorize 620624e105a9 00141484f95b992dac0e1e549e51187b3c2b17e587 | Out-Null

foreach ($bucket in $buckets) {
	$repositories = C:\Users\bradweiand\AppData\Local\Temp\b2v3-windows.exe ls $bucket
	$files = C:\Users\bradweiand\AppData\Local\Temp\b2v3-windows.exe ls $bucket -r --long

    # Creating a generic list to start assembling the report
    $report = New-Object System.Collections.Generic.List[string]
    $report.Add("$bucket`n")

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

        # Initialize a hash table to track incrementals for each full backup ID
        $incrementalCounts = @{}

        # Process each line in the data
        foreach ($line in $files) {
            # Split the line into parts and extract the filename
            $columns = $line -split '\s+'
            $fileName = $columns[-1] # Last column is the file path
        
            # Extract the backup ID and incrementals from the filename
            if ($fileName -match '^(.+)-(\d+)-\2\.MRIMG$') {
                $backupID = $matches[1]
                $incrementalNumber = [int]$matches[2]

                # Track counts of incrementals for each backup ID
                if (-not $incrementalCounts.ContainsKey($backupID)) {
                    $incrementalCounts[$backupID] = 0
                }

                # Only count incrementals (not the full backup itself)
                if ($incrementalNumber -gt 0) {
                    $incrementalCounts[$backupID]++
                }
            }
        }

        # Check if any backup ID exceeds the allowed number of incrementals
        foreach ($key in $incrementalCounts.Keys) {
            if ($incrementalCounts[$key] -gt 45) {
                $report.Add("WARNING: The backup '$key' currently has $($incrementalCounts[$key]) incremental backups. Please investigate.`n")
            }
        }
    }

    Write-Host "$report"
}

try {
    rm "C:\Users\bradweiand\AppData\Local\Temp\b2v3-windows.exe" -Force
} catch {
    Write-Host "Unable to remove the b2v3-windows.exe file."
}