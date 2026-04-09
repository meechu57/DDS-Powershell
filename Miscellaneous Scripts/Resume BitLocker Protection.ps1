# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Check BitLocker status for C drive
$bitlocker = Get-BitLockerVolume -MountPoint "C:"

# If the Bitlocker is suspended on the C drive, resume it.
if ($bitlocker.ProtectionStatus -eq "Off") {
  Write-Host "BitLocker is currently suspended on the C drive. Resuming Bitlocker protection..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") BitLocker is currently suspended on the C drive. Resuming Bitlocker protection..."
  
  Resume-BitLocker -MountPoint "C:"
} elseif ($bitlocker.ProtectionStatus -eq "On") {
  Write-Host "BitLocker protection is already enabled on the C drive."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") BitLocker is currently suspended on the C drive. Resuming Bitlocker protection..."
}
else {
  Write-Host "Unexpected BitLocker status on C: ($($bitlocker.ProtectionStatus))."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Unexpected BitLocker status on C: ($($bitlocker.ProtectionStatus))."
}