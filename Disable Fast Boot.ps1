# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# The registry path where HiberbootEnabled exists
$regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power"

# Gets the value of the HiberbootEnabled registry key
$hiberbootRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name HiberbootEnabled -ErrorAction SilentlyContinue

Write-Host "Attempting to disable Fast Boot..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to disable Fast Boot..."

# If the registry key doesn't exist, create it and set it to 0.
if ($hiberbootRegKey -eq $null) {
  try {
    # Add the registry key and set it to 0.
    reg add $regPath /v HiberbootEnabled /t REG_DWORD /d 0 /f
    
    Write-Host "Successfully set the HiberbootEnabled registry key to 0 and disabled fast boot."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully set the HiberbootEnabled registry key to 0 and disabled fast boot."
  } catch {
    Write-Host "The HiberbootEnabled registry key doesn't exist. Failed to add the registry key and disable fast boot: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The HiberbootEnabled registry key doesn't exist. Failed to add the registry key and disable fast boot: $_"
  }
} 
else {
  # If the registry key isn't 0, set it to 0.
  if ($hiberbootRegKey.HiberbootEnabled -ne 0) {
    try {
      # Add the registry key and set it to 0.
      reg add $regPath /v HiberbootEnabled /t REG_DWORD /d 0 /f
      
      Write-Host "Successfully set the HiberbootEnabled registry key to 0 and disabled fast boot."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully set the HiberbootEnabled registry key to 0 and disabled fast boot."
    } catch {
      Write-Host "Failed to set the HiberbootEnabled registry key to 0 and disable fast boot: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the HiberbootEnabled registry key to 0 and disable fast boot: $_"
    }
  } 
  else {
    Write-Host "Fast boot is already disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Fast boot is already disabled."
  }
}
