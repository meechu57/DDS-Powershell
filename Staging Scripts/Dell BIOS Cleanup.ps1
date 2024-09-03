# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# For error tracking.
$errors = 0

# Uninstall DellBIOSProvider
try {
  Write-Host "Removing DellBIOSProvider..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Removing DellBIOSProvider..."
  
  Uninstall-Module -Name DellBIOSProvider -Verbose
} catch {
  Write-Host "An error occurred while uninstalling DellBIOSProvider: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while uninstalling DellBIOSProvider: $_"
  
  $errors++
}

# Removes DellBIOSProvider from the PS Modules folder if the uninstall-module didn't fully work.
if (Test-Path "C:\Program Files\WindowsPowerShell\Modules\DellBIOSProvider") {
  try {
    Remove-Item -Path "C:\Program Files\WindowsPowerShell\Modules\DellBIOSProvider" -Recurse -Force
  } catch {
    Write-Host "An error occurred while removing the DellBIOSProvider folder: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while removing the DellBIOSProvider folder: $_"
    
    $errors++
  }
}

# Removes the temp folder created during installation.
if (Test-Path "C:\DDS\Temp") {
  try {
    Remove-Item -Path "C:\DDS\Temp" -Recurse -Force
  } catch {
    Write-Host "An error occurred while removing the DDS Temp folder: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while removing the DDS Temp folder: $_"
    
    $errors++
  }
}

Write-Host "Finished cleaning up with $errors errors."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Finished cleaning up with $errors errors."
