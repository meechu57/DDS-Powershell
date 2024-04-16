# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# The registry path where EnableLUA exists
$regPath = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

# Gets the value of the EnableLUA registry key
$uacRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name EnableLUA -ErrorAction SilentlyContinue

Write-Host "Auditing UAC..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing UAC..."

# If UAC is properly disabled, the EnableLUA registry key will be set to 0.
if ($uacRegKey -eq $null -or $uacRegKey.EnableLUA -ne 0) {
  Write-Host "UAC is not disabled."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") UAC is not disabled."
  
  Ninja-Property-Set uacDisabled $false
} 
else {
  Write-Host "UAC is disabled."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") UAC is disabled."
  
  Ninja-Property-Set uacDisabled $true
}
