# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# Registry pathway for ISO Mounting
$regPath = "HKCR\Windows.IsoFile\shell\mount"

# Gets the value of the ProgrammaticAccessOnly registry key
$programmaticAccessReg = Get-ItemProperty -Path "Registry::$regPath" -Name ProgrammaticAccessOnly -ErrorAction SilentlyContinue

Write-Host "Auditing the configuration of ISO Mounting..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the configuration of ISO Mounting..."

if ($programmaticAccessReg -eq $null) {
  Write-Host "ISO mounting is not disabled."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") ISO mounting is not disabled."
  
  Ninja-Property-Set isoMountingDisabled $false
} 
else {
  Write-Host "ISO mounting is disabled."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") ISO mounting is disabled."
  
  Ninja-Property-Set isoMountingDisabled $true
}
