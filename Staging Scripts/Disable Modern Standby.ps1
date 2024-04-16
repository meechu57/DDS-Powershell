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
  
# If PlatformAoAcOverride doesn't exist, it should be $null
Write-Host "Attempting to disable Modern Standby..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to disable Modern Standby..."

# Adds the PlatformAoAcOverride registry key to disable UAC
if ($overridgeRegKey -eq $null) {
  try {
    reg add $regPath /v PlatformAoAcOverride /t REG_DWORD /d 0 /f
    } catch {
    Write-Host "Failed to add the PlatformAoAcOverride Registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the PlatformAoAcOverride Registry key: $_"
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
    }
  }
  else {
    Write-Host "Modern Standby is already disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Modern Standby is already disabled."
  }
}
