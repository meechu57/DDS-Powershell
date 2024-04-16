# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# The registry path where EnableLUA exists
$regPath = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

# Gets the value of the EnableLUA registry key
$uacRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name EnableLUA -ErrorAction SilentlyContinue

Write-Host "Attempting to disable UAC..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to disable UAC..."

# If the EnableLUA registry key doesn't exist or isn't set to 0, try to add the registry key and set the value to 0.
if ($uacRegKey -eq $null -or $uacRegKey.EnableLUA -ne 0) {
  try {
    reg add $regPath /v EnableLUA /t REG_DWORD /d 0 /f
    
    Write-Host "Successfully added the EnableLUA Registry key and disabled UAC."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully added the EnableLUA Registry key and disabled UAC."
  } catch {
    Write-Host "Failed to add the EnableLUA Registry key and disable UAC."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the EnableLUA Registry key and disable UAC."
  }
} else {
  Write-Host "UAC is already disabled."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") UAC is already disabled."
}
