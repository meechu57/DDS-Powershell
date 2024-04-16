# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# Gets the currently set time zone
$timeZone = [System.TimeZoneInfo]::Local.id

Write-Host "Auditing the time zone..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the time zone..."

# Time zone should be set to EST
if ($timeZone -eq "Eastern Standard Time") {
  Write-Host "Time zone is set correctly. Current time zone is set to $($timeZone)"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Time zone is set correctly. Current time zone is set to $($timeZone)"
  
  Ninja-Property-Set timeZoneSet $true
}
else {
  Write-Host "Time zone is set incorrectly. Current time zone is set to $($timeZone)"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Time zone is set incorrectly. Current time zone is set to $($timeZone)"
  
  Ninja-Property-Set timeZoneSet $false
}
