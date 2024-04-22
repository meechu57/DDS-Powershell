# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# The registry path where HiberbootEnabled exists
$regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power"

# Gets the value of the HiberbootEnabled registry key
$hiberbootRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name HiberbootEnabled -ErrorAction SilentlyContinue

Write-Host "Auditing Fast Boot..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Fast Boot..."

if ($hiberbootRegKey -eq $null) {
  Write-Host "The HiberBootEnabled registry key doesn't exist. Fast boot may not be disabled. Manual investigation is required."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The HiberBootEnabled registry key doesn't exist. Fast boot may not be disabled. Manual investigation is required."
  
  Ninja-Property-Set fastBootDisabled $false
}
elseif ($hiberbootRegKey.HiberbootEnabled -eq 0) {
  Write-Host "The HiberBootEnabled registry key exists and is correctly set. Fast Boot is disabled."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The HiberBootEnabled registry key exists and is correctly set. Fast Boot is disabled."
  
  Ninja-Property-Set fastBootDisabled $true
}
else {
  Write-Host "The HiberBootEnabled registry key exists but is not correctly set. Fast boot may not be disabled. Manual investigation is required."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The HiberBootEnabled registry key but is not correctly set. Fast boot may not be disabled. Manual investigation is required."
  
  Ninja-Property-Set fastBootDisabled $false
}
