# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Downloads and runs the installer for DSU if it's not on the server already.
if (-not(Test-Path "C:\Program Files\Dell\DELL System Update\DSU.exe") -and -not(Test-Path "C:\Program Files\Dell\DELL EMC System Update\DSU.exe")) {
  $uri = "https://dl.dell.com/FOLDER14217017M/1/Systems-Management_Application_RXKJ5_WN64_2.2.0.1_A00.EXE"
  $file = "$env:temp/Systems-Management_Application_RXKJ5_WN64_2.2.0.1_A00.EXE"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $uri -Method get -OutFile $file -UserAgent Chrome
  Unblock-File $file
  Start-Process -FilePath $file -ArgumentList "/s /i" -Wait
} 

# Wait for the install to finish (only needed for older servers)
Start-Sleep -Seconds 120

# Double check that DSU was actually installed.
if ((Test-Path "C:\Program Files\Dell\DELL System Update\DSU.exe") -or (Test-Path "C:\Program Files\Dell\DELL EMC System Update\DSU.exe")) {
  Ninja-Property-Set dsuQueued $false
  
} else {
  Write-Host "An error occurred when trying to install DSU. Please manually install and try again."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to install DSU. Please manually install and try again."
  
  exit 1
}

Write-Host "Starting DSU..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Starting DSU..."

# Start DSU
try {
  dsu --non-interactive --apply-upgrades
} catch {
  Write-Host "An error occurred when trying to run DSU. Please invenstigate and try again. Error: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to run DSU. Please invenstigate and try again. Error: $_"
}

# Convert the Script Variable to a local variable.
$reboot = $env:reboot

if ($reboot -eq "Yes") {
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
  }
  
  # Pull the current state of Bitlocker to ensure that it is indeed suspended.
  $cDriveBitlocker = Get-BitLockerVolume -MountPoint "C:"
  
  # If the protection status is still on, exit the script
  if ($cDriveBitlocker.ProtectionStatus -eq "On") {
  	Write-Error "Failed to suspend Bitlocker for the upcoming reboot: $_"
  	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to suspend Bitlocker for the upcoming reboot: $_"
  
  	exit 1
  }
  
  # Convert the Script Variable to a local variable.
  $time = $env:timeTillReboot
  
  # Reboot the server after the specified amount of time.
  try {
    Write-Host "Rebooting..."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Rebooting..."
    
    shutdown /r /t $time
  } catch {
    Write-Error "Failed to send the reboot command: $_"
  	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to send the reboot command: $_"
  
  	exit 1
  }
}