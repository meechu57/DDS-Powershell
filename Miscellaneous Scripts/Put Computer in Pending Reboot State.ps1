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

# Check if the RebootRequired key exists
if (Test-Path $regPath) {
  Write-Host "The computer is already in a pending reboot state."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The computer is already in a pending reboot state."
} # Create the RebootRequired key and subkeys if it doesn't exist 
else {
  # Create the RebootRequired key
  try {
    New-Item -Path $regPath -Force | Out-Null
  } catch {
    Write-Host "An error occurred when trying to create the RebootRequired key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to create the RebootRequired key: $_"

    exit 1
  }
}