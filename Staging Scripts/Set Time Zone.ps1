# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Gets the currently set time zone
$timeZone = (Get-TimeZone).id

Write-Host "Setting the time zone..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Setting the time zone..."

# Time zone should be set to EST
if ($timeZone -ne "Eastern Standard Time") {
  # Sets timezone to EST
  try {
   Set-TimeZone -Id 'Eastern Standard Time'
   
  } catch {
    Write-Host "Failed to set timezone to EST. Current time zone is $($timeZone): $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set timezone to EST. Current time zone is $($timeZone): $_"
    
    exit 1
  }
}
else {
  Write-Host "Time zone is already set to Eastern Standard Time."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Time zone is already set to Eastern Standard Time."
}