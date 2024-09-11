<# 
  This script will pull the current scheme GUID and turn off sleep after, allow hybrid sleep, 
  hibernate after, allow wake timers, and USB selective suspend. It will do so on both AC and DC power.
#>

# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Assigning these as variables for readability purposes
$usbSubGUID = '2a737441-1930-4402-8d77-b2bebba308a3'
$usbSelectiveSuspend = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'
$hubSelectiveSuspend = '0853a681-27c8-4100-a2fd-82013e970683'
$usbLinkPowerManagement = 'd4e98f31-5ffe-4ce1-be31-1b38b384c009'

# Look for a non-battery backup battery. This means that the device is a laptop.
$battery = Get-CimInstance Win32_Battery
$isLaptop = 0

if ($battery -and $battery.name -notlike "*UPS*") {
  Write-Host "Laptop detected."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Laptop detected."
  
  $isLaptop = 1
}

# For error tracking
$errors = 0

Write-Host "Setting power options..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Setting power options..."
  
# Set sleep settings to "Never"
try {
  powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
  powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
} catch {
  Write-Host "Failed to set sleep settings to Never: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set sleep settings to Never: $_"
  
  $error++
}

# Set hibernate after settings to "Off"
try {
  powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
  powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
} catch {
  Write-Host "Failed to set hibernate after to off: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set hibernate after to off: $_"
  
  $error++
}

if ($isLaptop -eq 0) {
  # Disable hibernation
  try {
    powercfg -h off
  } catch {
    Write-Host "Failed to disable hibernation: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable hibernation: $_"
    
    $error++
  }
}

# Disable hybrid sleep
try {
  powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 0
  powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 0
} catch {
  Write-Host "Failed to disable hybrid sleep: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable hybrid sleep: $_"
  
  $error++
}

# Disable wake timer
try {
  powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
  powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
} catch {
  Write-Host "Failed to disable wake timer: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable wake timer: $_"
  
  $error++
}

# Disable USB selective suspend timeout
try {
  powercfg /setacvalueindex SCHEME_CURRENT $usbSubGUID $usbSelectiveSuspend 0
  powercfg /setdcvalueindex SCHEME_CURRENT $usbSubGUID $usbSelectiveSuspend 0
} catch {
  Write-Host "Failed to disable USB selective suspend timeout: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable USB selective suspend timeout: $_"
  
  $error++
}

# Disable Hub selective suspend timeout
try {
  powercfg /setacvalueindex SCHEME_CURRENT $usbSubGUID $hubSelectiveSuspend 0
  powercfg /setdcvalueindex SCHEME_CURRENT $usbSubGUID $hubSelectiveSuspend 0
} catch {
  Write-Host "Failed to disable USB selective suspend timeout: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable USB selective suspend timeout: $_"
  
  $error++
}

# Disable USB 3 Link Power Mangement
try {
  powercfg /setacvalueindex SCHEME_CURRENT $usbSubGUID $usbLinkPowerManagement 0
  powercfg /setdcvalueindex SCHEME_CURRENT $usbSubGUID $usbLinkPowerManagement 0
} catch {
  Write-Host "Failed to disable USB 3 Link Power Mangement: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable USB 3 Link Power Mangement: $_"
  
  $error++
}

# Set Turn off display after to 90 mins (in seconds)
if ($env:setScreenTimeout) {
  $timeout = $env:screenTimeoutValue
  try {
    powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE $timeout
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE $timeout
  } catch {
    Write-Host "Failed to adjust screen timeout: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to adjust screen timeout: $_"
    
    $error++
  } 
}

# Disable Turn off hard disk after
try {
  powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0
  powercfg /setdcvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0
} catch {
  Write-Host "Failed to disable Turn off hard disk idle: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable Turn off hard disk idle: $_"
  
  $error++
}

# Show any the number of errors that occurred (if any)
if ($errors -ne 0) {
  Write-Host "$errors error(s) were encountered while setting power options."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $errors error(s) were encountered while setting power options."
  
  exit 1
} else {
  Write-Host "Power Options successfully set."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Options successfully set."  
}