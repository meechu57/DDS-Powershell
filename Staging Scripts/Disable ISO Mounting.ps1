# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

$regPath = "HKCR\Windows.IsoFile\shell\mount"

$programmaticAccessReg = Get-ItemProperty -Path "Registry::$regPath" -Name ProgrammaticAccessOnly -ErrorAction SilentlyContinue

Write-Host "Attempting to disable ISO Mounting..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to disable ISO Mounting..."

# If this is true, the key already exists. Otherwise create the key.
if ($programmaticAccessReg) {
  Write-Host "The ProgrammaticAccessOnly registry key already exists. ISO mounting is already disabled."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The ProgrammaticAccessOnly registry key already exists. ISO mounting is already disabled."
} 
else {
  try {
    # This will add the registry key 'ProgrammaticAccessOnly' under the given registry path
    reg add $regPath /v ProgrammaticAccessOnly /t REG_SZ /f
    
    Write-Host "Successfully set ISO mounting to not be the default action of an ISO."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully set ISO mounting to not be the default action of an ISO."
  } catch {
    Write-Host "Failed to set ISO mounting to not be the default action of an ISO: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set ISO mounting to not be the default action of an ISO: $_"
  }
}
