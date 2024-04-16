# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# The registry path where PlatformAoAcOverride exists
$regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Power"

# Gets the value of the PlatformAoAcOverride registry key
$overridgeRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name PlatformAoAcOverride -ErrorAction SilentlyContinue

Write-Host "Auditing Modern Standby..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Modern Standby..."

# If the registry key doesn't exist, it'll be null.
if ($overridgeRegKey -eq $null) {
  Write-Host "The registry key for Modern Standby doesn't exist."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The registry key for Modern Standby doesn't exist."
  
  Ninja-Property-Set modernStandbyDisabled $false
} 
# If the registry key does exist isn't 0, Modern Standby isn't disabled.
else { 
  if ($overridgeRegKey.PlatformAoAcOverride -eq 0) {
    Write-Host "Modern Standby is disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Modern Standby is disabled."
    
    Ninja-Property-Set modernStandbyDisabled $true
  } 
  else {
    Write-Host "Modern Standby is not disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Modern Standby is not disabled."
    
    Ninja-Property-Set modernStandbyDisabled $false
  }
}
