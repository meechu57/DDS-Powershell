# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# For error tracking with USB controllers
$usbControllerErrors = 0

# For error tracking with USB devices
$usbDeviceErrors = 0

Write-Host "Auditing USB power settings..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing USB power settings..."

# Get the list of USB controllers on the device
$usbControllers = Get-CimInstance -Query 'SELECT * FROM MSPower_DeviceEnable WHERE InstanceName LIKE "USB\\%"' -Namespace root/WMI

# Dynamic power devices
$powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI

# All USB devices
$usbDevices = Get-CimInstance -ClassName Win32_PnPEntity -Filter 'PNPClass = "USB"'

# Looking to see if the power settings are enabled for the USB controllers
foreach ($i in $usbControllers) {
  # If true, power settings are enabled
  if ($i.Enable -eq $true) {
    $usbControllerErrors++
  }
}

# Looking to see if the power settings are enabled for the USB devices
foreach ($i in $usbDevices) {
  # Get just the USB devices from the dynamic power devices
  $powerSetting = $powerMgmt | Where-Object InstanceName -Like "*$($i.PNPDeviceID)*"
  
  # If true, power settings are enabled
  if ($powerSetting.Enable -eq $true) {
    $usbDeviceErrors++
  }
}

# If either of the variables are more than 0, 1 or more USB device or controller doesn't have their power option disabled.
if ($usbControllerErrors -ne 0 -or $usbDeviceErrors -ne 0) {
  Write-Host "$usbControllerErrors USB controller(s) and $usbDeviceErrors USB device(s) don't have their power settings disabled."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $usbControllerErrors USB controller(s) and $usbDeviceErrors USB device(s) don't have their power settings disabled."
  
  Ninja-Property-Set usbControllerConfigured $false
}
else {
  Write-Host "All USB controllers and USB devices have their power settings correctly configured."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All USB controllers and USB devices have their power settings correctly configured."
  
  Ninja-Property-Set usbControllerConfigured $true
}
