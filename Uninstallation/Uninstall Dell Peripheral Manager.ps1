# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Gets the directory for Dell Peripheral Manager
$dpmDirectory = "C:\Program Files\Dell\Dell Peripheral Manager\Uninstall.exe"

# Check if the directory is found
if ($dpmDirectory) {
  Write-Host "Uninstalling Dell Peripheral Manager..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling Dell Peripheral Manager..."
  
  # Uninstall the software
  try {
    Start-Process -FilePath $dpmDirectory -ArgumentList "/S"
  } catch {
    Write-Host "Failed to uninstall Dell Peripheral Manager."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to uninstall Dell Peripheral Manager."
  }
}
