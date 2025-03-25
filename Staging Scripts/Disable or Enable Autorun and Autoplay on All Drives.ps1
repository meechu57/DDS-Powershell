# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

Write-Host "Disabling Autorun and Autoplay on all drives..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Autorun and Autoplay on all drives..."

# Convert the script variable to a local one.
$option = $env:disableOrEnable

# Get the current value of the NoDriveTypeAutorun key
$autorunReg = Get-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer” -Name “NoDriveTypeAutorun” -ErrorAction SilentlyContinue
# The value we're looking for
if ($option -eq "Disable") {
  # Set the value or create the NoDriveTypeAutorun key if it doesn't exist or isn't set correctly.
  if ($autorunReg -and $autorunReg.NoDriveTypeAutorun -ne 0xFF) {
    try {
      Set-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer” -Name “NoDriveTypeAutorun” -Value 0xFF -Force
    } catch {
      Write-Host "Failed to set the NoDriveTypeAutorun registry key: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the NoDriveTypeAutorun registry key: $_"
      
      exit 1
    }
  } elseif (-not $autorunReg) {
    try {
      New-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer” -Name “NoDriveTypeAutorun” -Value $value -PropertyType DWORD -Force
    } catch {
      Write-Host "Failed to set the NoDriveTypeAutorun registry key: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the NoDriveTypeAutorun registry key: $_"
      
      exit 1
    }
  }
} elseif ($option -eq "Enable") {
    if ($autorunReg) {
      try {
        Clear-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer” -Name “NoDriveTypeAutorun” -Force
      } catch {
        Write-Host "Failed to set the NoDriveTypeAutorun registry key: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the NoDriveTypeAutorun registry key: $_"
        
        exit 1
      }
    }
} else {
  Write-Host "Invalid option selected on the 'Disable or Enable' drop down menu."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Invalid option selected on the 'Disable or Enable' drop down menu."
  
  exit 1
}