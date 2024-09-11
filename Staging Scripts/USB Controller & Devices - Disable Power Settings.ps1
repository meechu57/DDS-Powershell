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

Write-Host "Configuring power settings for all USB devices and controllers..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring power settings for all USB devices and controllers..."

try {
  # Dynamic power devices
  $powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI

  # Get all USB devices with dynamic power options
  $usbDevices = Get-CimInstance -ClassName Win32_PnPEntity |
      Select-Object Name, @{ Name = "Enable"; Expression = { 
          $powerMgmt | Where-Object InstanceName -Like "*$($_.PNPDeviceID)*" | Select-Object -ExpandProperty Enable }} |
              Where-Object { $null -ne $_.Enable -and $_.Enable -eq $true } |  
                  Where-Object {$_.Name -like "*USB*" -and $_.Name -notlike "*Virtual*"}
  
  # Try to disable the power option on each USB devcie from above
  $powerMgmt | Where-Object { $_.InstanceName -Like "*$($usbDevice.PNPDeviceID)*" } | Set-CimInstance -Property @{Enable = $false}
} catch {
  Write-Host "Failed to disable 'Allow the computer to turn off this device to save power' on all USB devices: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable 'Allow the computer to turn off this device to save power' on all USB devices: $_"
  
  $errors++
}

# Show any errors.
if ($errors -and $errors -eq 0) {
  Write-Host "Finished configuring power settings for all USB devices and controllers with 0 errors."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Finished configuring power settings for all USB devices and controllers with 0 errors."
} else {
  Write-Host "Finished configuring power settings for all USB devices and controllers with $errors errors."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Finished configuring power settings for all USB devices and controllers with $errors errors."
  
  exit 1
}