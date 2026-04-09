# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

$screenTimeout = $env:screenTimeout

# Set Turn off display after to the script variable.
try {
  powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE $screenTimeout
  powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE $screenTimeout
} catch {
  Write-Host "Failed to adjust screen timeout: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to adjust screen timeout: $_"
}