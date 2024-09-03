# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# The two registry locations where the software would be.
$uninstallKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\*'

# To track if the redistributable is installed.
$isInstalled = $false

# Pull the script variables.
$reboot = $env:rebootComputer
$newPW = $env:newBiosPassword
$currentPW = $env:currentBiosPassword

# Go through both registry locations.
foreach ($uKey in $uninstallKeys) {
  # Go through all of the registry keys in the hive.
  foreach ($key in (Get-ItemProperty $uKey)) {
    if ($key.Displayname -like "*Microsoft Visual C++ 2015-2022 Redistributable (x64)*") {
      Write-Host "C++ 2015-2022 Redistributable is already installed."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") C++ 2015-2022 Redistributable is already installed."
      
      $isInstalled = $true
    }
    if ($isInstalled) {
        break
    }
  }
}

# If the redistributable isn't installed, download and install it.
if ($isInstalled -eq $false) {
  # Temp directory to house the executable.
  if (!(Test-Path "C:\DDS\Temp")) {
    try {
      New-Item -ItemType Directory -Path "C:\DDS\Temp" -Force
    } catch {
      Write-Host "An error occurred creating the temp directory: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred creating the temp directory: $_"

      exit 1
    }
  } 
  
  Write-Host "Downloading vc_redist.x64.exe..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Downloading vc_redist.x64.exe..."
  
  # Downloads the redistributable to the temp folder.
  Invoke-WebRequest "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "C:\DDS\Temp\vc_redist.x64.exe"
  
  Write-Host "Installing vc_redist.x64.exe..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Installing vc_redist.x64.exe..."
  
  # Installs the redistributable.
  Start-Process -FilePath "C:\DDS\Temp\vc_redist.x64.exe" -ArgumentList "/q /norestart"
}

# Pulls the list of installed packages, selecting the names.
$packages = Get-PackageProvider -ListAvailable | Select-Object -ExpandProperty Name

if (!($packages -contains "NuGet")) {
  Write-Host "Installing NuGet..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Installing NuGet..."
  
  # Install NuGet
  try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers
  } catch {
    Write-Host "An error occured while installing NuGet: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occured while installing NuGet: $_"

    exit 1
  }
}

# Yoinked from another script. Unknown if this is needed as of now.
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted 

# Pulls the list of installed PowerShell modules, selecting the names.
$modules = Get-Module -ListAvailable | Select-Object -ExpandProperty Name

if (!($modules -contains "DellBIOSProvider")) {
  Write-Host "Installing DellBIOSProvider..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Installing DellBIOSProvider..."
  
  # Install and import DellBIOSProvider
  try {
    Install-Module -Name DellBIOSProvider -Force -Scope AllUsers
    
    Import-Module -name DellBIOSProvider
  } catch {
    Write-Host "An error occured while installing DellBIOSProvider: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occured while installing DellBIOSProvider: $_"

    exit 1
  }
} else {
    Import-Module -Name DellBIOSProvider
}

# Set the execution policy for this script.
Set-ExecutionPolicy -ExecutionPolicy remotesigned -Scope Process


Write-Host "Configuring BIOS settings..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring BIOS settings..."

# For error tracking.
$errors = 0

# Check if a BIOS pw is already set.
$pwSet = (Get-Item -Path DellSmbios:\Security\IsAdminPasswordSet).CurrentValue

if ($pwSet -eq "True") {
  if ($currentPW -eq $null) {
    Write-Host "There is currently a BIOS password set. Please input the password in the 'Current BIOS Password' script variable."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") There is currently a BIOS password set. Please input the password in the 'Current BIOS Password' script variable."

    exit 1
  }

  # Start configuring BIOS settings.
  try {
    Set-Item -Path DellSmbios:\PowerManagement\WakeOnLan "LanOnly" -Password $currentPW
  } catch {
    Write-Host "An error occurred while setting Wake On Lan: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting Wake On Lan: $_"

    $errors++
  }

  # Check if running on a laptop or desktop
  $battery = Get-CimInstance Win32_Battery
  if ($battery -eq $null -or $battery.name -like "*UPS*") {
   try {
      Set-Item -Path DellSmbios:\PowerManagement\BlockSleep "Enabled" -Password $currentPW
    } catch {
      Write-Host "An error occurred while setting Block Sleep: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting Block Sleep: $_"
  
      $errors++
    }
    try {
      Set-Item -Path DellSmbios:\PowerManagement\AcPwrRcvry "Last" -Password $currentPW
    } catch {
      Write-Host "An error occurred while setting AC Power Recovery: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting AC Power Recovery: $_"

      $errors++
    }

    try {
      Set-Item -Path DellSmbios:\PowerManagement\DeepSleepCtrl "Disabled" -Password $currentPW
    } catch {
      Write-Host "An error occurred while setting Deep Sleep Control: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting Deep Sleep Control: $_"

      $errors++
    }
  }

  try {
    Set-Item -Path DellSmbios:\Performance\CStatesCtrl "Disabled" -Password $currentPW
  }catch {
    Write-Host "An error occurred while setting C States Control: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting C States Control: $_"

    $errors++
  }

  if ($newPW) {
    try {
      Set-Item -Path DellSmbios:\Security\AdminPassword $newPW -Password $currentPW
    } catch {
      Write-Host "An error occurred while setting the BIOS password: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting the BIOS password: $_"
  
      $errors++
    }
  }
} elseif ($pwSet -eq "False") {
    # Start configuring BIOS settings.
    try {
      Set-Item -Path DellSmbios:\PowerManagement\WakeOnLan "LanOnly"
    }catch {
      Write-Host "An error occurred while setting Wake On Lan: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting Wake On Lan: $_"
  
      $errors++
    }

    # Check if running on a laptop or desktop
    $battery = Get-CimInstance Win32_Battery
    if ($battery -eq $null -or $battery.name -like "*UPS*") {
     try {
        Set-Item -Path DellSmbios:\PowerManagement\BlockSleep "Enabled"
      }catch {
        Write-Host "An error occurred while setting Block Sleep: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting Block Sleep: $_"
    
        $errors++
      }
      try {
        Set-Item -Path DellSmbios:\PowerManagement\AcPwrRcvry "Last"
      } catch {
        Write-Host "An error occurred while setting AC Power Recovery: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting AC Power Recovery: $_"

        $errors++
      }

      try {
        Set-Item -Path DellSmbios:\PowerManagement\DeepSleepCtrl "Disabled"
      } catch {
        Write-Host "An error occurred while setting Deep Sleep Control: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting Deep Sleep Control: $_"

        $errors++
      }
    }

    try {
      Set-Item -Path DellSmbios:\Performance\CStatesCtrl "Disabled"
    }catch {
      Write-Host "An error occurred while setting C States Control: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting C States Control: $_"
  
      $errors++
    }

    if ($env:newBiosPassword -eq $true) {
      try {
        Set-Item -Path DellSmbios:\Security\AdminPassword $env:newBiosPassword
      } catch {
        Write-Host "An error occurred while setting the BIOS password: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting the BIOS password: $_"
    
        $errors++
      }
    }
}

if ($errors -and $errors -ne 0) {
  Write-Host "Finished configuring BIOS settings with $errors errors."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Finished configuring BIOS settings with $errors errors."
} else {
  Write-Host "Finished configuring BIOS settings with 0 errors."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Finished configuring BIOS settings with 0 errors."
}

if ($reboot -and $reboot -eq $true) {
  Write-Host "Reboot option selected. Rebooting the comtpuer..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Reboot option selected. Rebooting the comtpuer..."
  
  shutdown /r
}