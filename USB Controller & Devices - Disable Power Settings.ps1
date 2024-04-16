# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# For error tracking.
$errors = 0

Write-Host "Configuring power settings for all USB devices and controllers."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring power settings for all USB devices and controllers."

try {
  # Set the power option for USB controllers
  Set-CimInstance -Query 'SELECT * FROM MSPower_DeviceEnable WHERE InstanceName LIKE "USB\\%"' -Namespace root/WMI -Property @{Enable = $false}
} catch {
  Write-Host "Failed to disable 'Allow the computer to turn off this device to save power' on all USB controllers: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable 'Allow the computer to turn off this device to save power' on all USB controllers.: $_"
  
  $errors++
}

try {
  # Dynamic power devices
  $powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI

  # All USB devices
  $usbDevices = Get-CimInstance -ClassName Win32_PnPEntity -Filter 'PNPClass = "USB"'

  $usbDevices | ForEach-Object {
  # Get the power management instance for this device, if there is one.
  $powerMgmt | Where-Object InstanceName -Like "*$($_.PNPDeviceID)*"
  } | Set-CimInstance -Property @{Enable = $false}
} catch {
  Write-Host "Failed to disable 'Allow the computer to turn off this device to save power' on all USB devices: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable 'Allow the computer to turn off this device to save power' on all USB devices: $_"
  
  $errors++
}

Write-Host "Finished configuring power settings for all USB devices and controllers with $errors errors."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Finished configuring power settings for all USB devices and controllers with $errors errors."



# Credit: https://www.reddit.com/r/PowerShell/comments/lr5iyk/comment/goladae/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
