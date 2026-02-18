# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Variable for tracking if a reboot is pending.
$pendingReboot = $false

# List of registry keys to check for a pending reboot.
$regKeysToCheck = @(
  [PSCustomObject]@{
      Key  = 'HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts'
      Name = 'CurrentRebootAttempts'
  },
  [PSCustomObject]@{
      Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending'
      Name = 'Component Based Servicing\PackagesPending'
  },
  [PSCustomObject]@{
      Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress'
      Name = 'Component Based Servicing\RebootInProgress'
  },
  [PSCustomObject]@{
      Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
      Name = 'Component Based Servicing\RebootPending'
  },
  [PSCustomObject]@{
      Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting'
      Name = 'WindowsUpdate\Auto Update\PostRebootReporting'
  },
  [PSCustomObject]@{
      Key  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
      Name = 'WindowsUpdate\Auto Update\RebootRequired'
  }
)

# Go through the registry keys to check if they exist.
foreach($regKey in $regKeysToCheck) 
{
  if(Test-Path -Path $regKey.Key) 
  {
    Write-Host "The '$($regKey.Name)' key exists."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The '$($regKey.Name)' key exists."
    
    $pendingReboot = $true
  }
}

if ($pendingReboot -eq $true) {
  Write-Host "A reboot is pending on $($env:COMPUTERNAME)."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A reboot is pending on $($env:COMPUTERNAME)."

  Write-Host "Suspending Bitlocker for the upcoming reboot..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Suspending Bitlocker for the upcoming reboot..."

  # Pull the current state of Bitlocker
  $cDriveBitlocker = Get-BitLockerVolume -MountPoint "C:"

  if ($cDriveBitlocker.VolumeStatus -eq "FullyEncrypted") {
    # If the protection status is on, suspend Bitlocker for 1 reboot.
    if ($cDriveBitlocker.ProtectionStatus -eq "On") {
      try {
        Suspend-BitLocker -MountPoint "C:" -RebootCount 1
      } catch {
        Write-Host "Failed to suspend Bitlocker for the upcoming reboot: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to suspend Bitlocker for the upcoming reboot: $_"
    
        Write-Host "The current status of Bitlocker is: VolumeStatus: $($cDriveBitlocker.VolumeStatus) | Protection Status: $($cDriveBitlocker.ProtectionStatus)"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The current status of Bitlocker is: VolumeStatus: $($cDriveBitlocker.VolumeStatus) | Protection Status: $($cDriveBitlocker.ProtectionStatus)"
  
        exit 1
      }
    } else {
      Write-Host "Bitlocker is either already suspened or is not enabled at all. The current status of Bitlocker is: VolumeStatus: $($cDriveBitlocker.VolumeStatus) | Protection Status: $($cDriveBitlocker.ProtectionStatus)"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Bitlocker is either already suspened or is not enabled at all. The current status of Bitlocker is: VolumeStatus: $($cDriveBitlocker.VolumeStatus) | Protection Status: $($cDriveBitlocker.ProtectionStatus)"
    }
  }

  # Pull the current state of Bitlocker to ensure that it is indeed suspended.
  $cDriveBitlocker = Get-BitLockerVolume -MountPoint "C:"

  # If the protection status is still on, exit the script
  if ($cDriveBitlocker.ProtectionStatus -eq "On") {
    Write-Host "Failed to suspend Bitlocker for the upcoming reboot: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to suspend Bitlocker for the upcoming reboot: $_"

    exit 1
  }
  
  # Convert the Script Variable to a local variable.
  $time = $env:timeTillReboot
  
  # Reboot the server after the specified amount of time.
  try {
    Write-Host "Restarting in $time seconds..."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Restarting in $time seconds..."
    
    shutdown /r /t $time
  } catch {
    Write-Host "Failed to send the reboot command: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to send the reboot command: $_"

    exit 1
  }
} else {
  Write-Host "No reboot is pending on $($env:COMPUTERNAME)."
}