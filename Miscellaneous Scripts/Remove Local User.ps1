# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

$usernames = @($env:userToRemove1, $env:userToRemove2, $env:userToRemove3, $env:userToRemove4, $env:userToRemove5)
$localUsers = Get-LocalUser

Write-Host "Attempting to remove the following user(s): $usernames"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to remove the following user(s): $usernames"

foreach ($username in $usernames) {
  foreach ($user in $localUsers) {
    if ($user.name -eq $username) {
      try {
        Remove-LocalUser -Name $username
        
        Write-Host "Successfully removed the $username user."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully removed the $username user."
      } catch {
        Write-Host "An error occured when trying to remove the $username user. The user may not have been removed."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occured when trying to remove the $username user. The user may not have been removed."
      }
    }
  }
}
