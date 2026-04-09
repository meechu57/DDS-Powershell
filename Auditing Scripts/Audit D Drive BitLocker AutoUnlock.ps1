# Get the current state of Bitlockers on the C drive.
$bitlocker = Get-BitLockerVolume -MountPoint "D:"

# If Bitlocker is enabled on the D drive but AutoUnlock is not enabled, create a ticket.
if ($bitlocker.VolumeStatus -eq "FullyEncrypted") {
  if ($bitlocker.autounlockenabled -eq "True") {
    Write-Host "Bitlocker is properly configured on the D drive."
  } else {
    Write-Host "AutoUnlock is not enabled on the D drive's BitLocker. The current state of AutoUnlock: $($bitlocker.autounlockenabled)"
    
    exit 1
  }
} else {
  Write-Host "Warning! Bitlocker is not enabled on the D drive."
}