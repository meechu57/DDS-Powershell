# Get the manufacturer and model for the device
$manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
$model = (Get-WmiObject -Class Win32_ComputerSystem).Model

# Check to make sure this device is a Dell Server.
if ($manufacturer -notlike "*Dell*" -or $model -notlike "*PowerEdge*") {
  Write-Host "This device is not a Dell Server. Exiting the script."
  
  exit 1
}

# Get all licenses
$racadmOutput = racadm license view

# Initialize the array for each license
$license1 = @{}
$license2 = @{}
$license3 = @{}
$license4 = @{}

# An array of the arrays
$allLicenses = @($license1, $license2, $license3, $license4)

# Where the final license will go if one was found.
$idracLicense = $null

# Split output by lines
$lines = $racadmOutput -split "`n"

# Variables to track the current license section
$currentLicense = $null

foreach ($line in $lines) {
  $trimmedLine = $line.Trim()

  # Detect which license block we are in
  if ($trimmedLine -like "*License #1*") {
    $currentLicense = "License1"
    continue
  } elseif ($trimmedLine -like "*License #2*") {
    $currentLicense = "License2"
    continue
  } elseif ($trimmedLine -like "*License #3*") {
    $currentLicense = "License3"
    continue
  } elseif ($trimmedLine -like "*License #4*") {
    $currentLicense = "License4"
    continue
  }

  # If the line contains an '=', split it into key and value
  if ($trimmedLine -like "*=*") {
    $parts = $trimmedLine -split '=', 2
    $attribute = $parts[0].Trim()
    $value = $parts[1].Trim()

    # Add attributes to the correct license
    if ($currentLicense -eq "License1") {
      $license1[$attribute] = $value
    } elseif ($currentLicense -eq "License2") {
      $license2[$attribute] = $value
    } elseif ($currentLicense -eq "License3") {
      $license3[$attribute] = $value
    } elseif ($currentLicense -eq "License4") {
      $license4[$attribute] = $value
    }
  }
}

# Go through each license and look for one that is active.
foreach ($license in $allLicenses) {
  if ($license) {
    if ($license.Status -eq "OK") {
      $idracLicense = $license.'License Description'
      break
    }
  }
}

# Show the license if one was found.
if ($idracLicense) {
  Write-Host "An iDRAC license was found.`n`nThis server has the following license: $idracLicense"
} else {
  Write-Host "No iDRAC license was found."
  
  exit 1
}