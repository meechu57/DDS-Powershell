# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Registry path to the Schick Installed registry key
$regPath = "HKLM:\SOFTWARE\WOW6432Node\Eaglesoft\Chairside\Digital XRay"


# Set the SetDisableUXWUAccess DWord depending on the $env:enableOrDisable script variable.
if ($env:enableOrDisable -eq "Disable") {
  Write-Host "Disabling the Schick Sensor integration in Eaglesoft..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling the Schick Sensor integration in Eaglesoft..."
  try {
    New-ItemProperty -Path $regPath -Name "Schick Installed" -Value 0 -propertyType "DWord" -Force
  } catch {
    Write-Host "Failed to disable the Schick Sensor integration in Eaglesoft: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable the Schick Sensor integration in Eaglesoft: $_"
    
    exit 1
  }
} else {
  Write-Host "Enabling the Schick Sensor integration in Eaglesoft..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Enabling the Schick Sensor integration in Eaglesoft..."
  try {
    New-ItemProperty -Path $regPath -Name "Schick Installed" -Value 1 -propertyType "DWord" -Force
  } catch {
    Write-Host "Failed to enable the Schick Sensor integration in Eaglesoft: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to enable the Schick Sensor integration in Eaglesoft: $_"
    
    exit 1
  }
}