# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Check if the script was run as the default System User
function Test-IsSystem {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
}

# If it was we'll error out and enform the technician they should run it as the "Current Logged on User"
if (Test-IsSystem) {
  Write-Host "This script does not work when ran as system. Use Run As: 'Current Logged on User'."
  exit 1
}

Write-Host "Resetting the Eaglesoft AppData configuration folder..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Resetting the Eaglesoft AppData configuration folder..."

<# 
  Pulls the Eaglesoft Appdata configuration folder(s).
  Selects the folders that have previously been named '.old'.
  Deletes those folders.
#>
try {
  Get-ChildItem -Path "$($env:LOCALAPPDATA)\Patterson_Companies" | 
    Where-Object { $_.Name -like "*.old" } | 
      ForEach-Object { Remove-Item $_.FullName -Recurse -Force }
} catch {
  Write-Host "An error occurred while removing old AppData configuration folders: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while removing old AppData configuration folders: $_"
}

<# 
  Pulls the Eaglesoft Appdata configuration folder(s).
  Selects the folder that is currently being used.
  Adds '.old' to the end of the folder.
#>
try {
  Get-ChildItem -Path "$($env:LOCALAPPDATA)\Patterson_Companies" | 
    Where-Object { $_.Name -notlike "*.old" } | 
      ForEach-Object { Rename-Item $_.FullName -NewName ($_.Name + '.old') }
      
  Write-Host "Successfully reset the Eaglesoft AppData configuration folder."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully reset the Eaglesoft AppData configuration folder."
} catch {
  Write-Host "An error occurred while renaming the current AppData configuration folder: $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while renaming the current AppData configuration folder: $_"
}
