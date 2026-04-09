# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Pulls the list of all video controllers.
$videoControllers = (Get-WmiObject Win32_VideoController).Name

if ($videoControllers -contains "NVIDIA Quadro P1000") {
  # The link to download the driver
  $downloadLink = "https://us.download.nvidia.com/Windows/Quadro_Certified/582.41/582.41-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe"
  # For checking what's currently installed
  $targetVersion = "582.16"
  $currentVersion = "Not Installed"
  $uninstallKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
  
  # Go through all the registry keys and look for "NVIDIA Graphics Driver"
  foreach ($key in (Get-ItemProperty $uninstallKeys)) {
    # If there's already a graphics driver, pull the current version.
    if ($key.DisplayName -like "NVIDIA Graphics Driver*") {
      $currentVersion = $key.DisplayVersion
    }
  }
  
  # If the currently installed graphics driver isn't the version we're looking for, install the new driver.
  if ($currentVersion -ne $targetVersion) {
    # Download the NVIDIA Driver.
    try {
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
      Invoke-WebRequest -Uri $downloadLink -OutFile "$env:temp/QuadroP1000Driver.exe"
    } catch {
      Write-Host "Failed to download the NVIDIA Driver: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to download the NVIDIA Driver: $_"
    
      exit 1
    }
    
    # Install the NVIDIA Driver.
    Start-Process -Wait -FilePath "$env:temp/QuadroP1000Driver.exe" -ArgumentList "/s"
  } else {
    Write-Host "The most current graphics driver is already installed. Current version: $currentVersion"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The most current graphics driver is already installed. Current version: $currentVersion"
  }
} else {
  Write-Host "No GPU detected. Exiting the script..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No GPU detected. Exiting the script..."
}