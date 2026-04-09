# The log path for this script.
$logPath = "C:\DDS\Logs\Audit.log"

# Get the current state of Bitlockers on the C drive.
$bitlocker = Get-BitLockerVolume -MountPoint "C:"

# If Bitlocker is enabled but is not currently on, this means it's suspended. Create a ticket if that's the case.
if ($bitlocker.VolumeStatus -eq "FullyEncrypted") {
  if ($bitlocker.ProtectionStatus -eq "On") {
    Write-Host "Bitlocker is properly configured on the C drive."
  } else {
    Write-Host "Bitlocker is currently suspended on the C drive, please investigate. The current state of Bitlocker: $($bitlocker.ProtectionStatus)"
    
    exit 1
  }
} else {
  Write-Host "Warning! Bitlocker is not enabled on the C drive."
}