# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

Write-Host "Suspending Bitlocker for the upcoming reboot..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Suspending Bitlocker for the upcoming reboot..."

# Pull the current state of Bitlocker
$cDriveBitlocker = Get-BitLockerVolume -MountPoint "C:"

# If the protection status is on, suspend Bitlocker for 1 reboot.
if ($cDriveBitlocker.ProtectionStatus -eq "On") {
	try {
	  Suspend-BitLocker -MountPoint "C:" -RebootCount 1
	} catch {
	  Write-Error "Failed to suspend Bitlocker for the upcoming reboot: $_"
	  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to suspend Bitlocker for the upcoming reboot: $_"
	  
	  Write-Error "The current status of Bitlocker is: VolumeStatus: $($cDriveBitlocker.VolumeStatus) | Protection Status: $($cDriveBitlocker.ProtectionStatus)"
	  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The current status of Bitlocker is: VolumeStatus: $($cDriveBitlocker.VolumeStatus) | Protection Status: $($cDriveBitlocker.ProtectionStatus)"

	  exit 1
	}
} else {
	Write-Host "Bitlocker is either already suspened or is not enabled at all. The current status of Bitlocker is: VolumeStatus: $($cDriveBitlocker.VolumeStatus) | Protection Status: $($cDriveBitlocker.ProtectionStatus)"
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Bitlocker is either already suspened or is not enabled at all. The current status of Bitlocker is: VolumeStatus: $($cDriveBitlocker.VolumeStatus) | Protection Status: $($cDriveBitlocker.ProtectionStatus)"
}

# Pull the current state of Bitlocker to ensure that it is indeed suspended.
$cDriveBitlocker = Get-BitLockerVolume -MountPoint "C:"

# If the protection status is still on, exit the script
if ($cDriveBitlocker.ProtectionStatus -eq "On") {
	Write-Error "Failed to suspend Bitlocker for the upcoming reboot: $_"
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to suspend Bitlocker for the upcoming reboot: $_"

	exit 1
}