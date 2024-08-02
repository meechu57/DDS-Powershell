# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

Write-Host "Setting the computer to 'Pending Reboot' state..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Setting the computer to 'Pending Reboot' state..."

# Registry keys and pathway
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
$keysToCheck = @(
    "c9f3440f-77ba-40bb-a006-1e67387c6e96",
    "dce6a540-cc87-4c55-8db6-63af55cfd9fd",
    "7270ec06-f01f-4cda-8db5-a29207141a43"
)

# Check if the RebootRequired key exists
if (Test-Path $regPath) {
  # Check for the three keys above
  foreach ($key in $keysToCheck) {
    $value = Get-ItemProperty -Path $regPath -Name $key -ErrorAction SilentlyContinue
    
    # Set the key to the correct value if it doesn't exist or isn't set properly
    if ($value -ne 1 -or $value -eq $null) {
      try {
        Set-ItemProperty -Path $regPath -Name $key -Value 1
      } catch {
        Write-Host "An error occurred when setting the value of the registry key $key `n $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when setting the value of the registry key $key `n $_"

        exit 1
      }
    }
  }
} # Create the RebootRequired key and subkeys if it doesn't exist 
else {
  # Create the RebootRequired key
  try {
    New-Item -Path $regPath -Force
  } catch {
    Write-Host "An error occurred when trying to create the RebootRequired key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to create the RebootRequired key: $_"

    exit 1
  }
  
  # Create the subkeys
  foreach ($key in $keysToCheck) {
    try {
      New-ItemProperty -Path $regPath -Name $key -PropertyType DWord -Value 1 -Force
    } catch {
      Write-Host "An error occurred when setting the value of the registry key $key `n $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when setting the value of the registry key $key `n $_"

      exit 1
    }
  }
}