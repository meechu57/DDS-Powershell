# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# The registry path where PlatformAoAcOverride exists
$regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Power"

# Gets the value of the PlatformAoAcOverride registry key
$overridgeRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name PlatformAoAcOverride -ErrorAction SilentlyContinue

# Check for a non-backup battery. If a laptop battery is detected, exit the script.
$battery = Get-CimInstance Win32_Battery

if ($battery -and $battery.name -notlike "*UPS*") {
  Write-Host "Laptop detected, exiting the script..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Laptop detected, exiting the script..."
  
  exit 1
}
  
# If PlatformAoAcOverride doesn't exist, it should be $null
Write-Host "Disabling Modern Standby..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Modern Standby..."

# Adds the PlatformAoAcOverride registry key to disable Modern Standby
if ($overridgeRegKey -eq $null) {
  try {
    reg add $regPath /v PlatformAoAcOverride /t REG_DWORD /d 0 /f
    } catch {
    Write-Host "Failed to add the PlatformAoAcOverride Registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the PlatformAoAcOverride Registry key: $_"
    
    exit 1
  }
} else {
  # if PlatformAoAcOverride does exist and isn't 0 for some reason, this should force the value back to 0
  if ($overridgeRegKey.PlatformAoAcOverride -ne 0) {
    try {
      reg add $regPath /v PlatformAoAcOverride /t REG_DWORD /d 0 /f
      
      Write-Host "The PlatformAoAcOverride Registry key already existed but was incorrectly set. The value is now 0."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The PlatformAoAcOverride Registry key already existed but was incorrectly set. The value is now 0."
    } catch {
      Write-Host "Failed to add the PlatformAoAcOverride Registry key: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the PlatformAoAcOverride Registry key: $_"
      
      exit 1
    }
  }
  else {
    Write-Host "Modern Standby is already disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Modern Standby is already disabled."
  }
}