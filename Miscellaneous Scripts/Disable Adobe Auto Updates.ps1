# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

Write-Host "Disabling Adobe auto updates..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Adobe auto updates..."

# Look for the scheduled task
$updateTask = Get-ScheduledTask -TaskName "Adobe Acrobat Update Task" -ErrorAction SilentlyContinue

# Delete the scheduled task if it exists.
if ($updateTask) {
	Unregister-ScheduledTask -TaskName "Adobe Acrobat Update Task" -Confirm:$false
} else {
	Write-Host "No Adobe Update scheduled task was found."
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No Adobe Update scheduled task was found."
}

# 32 and 64 bit exe pathways
$32BitExePath = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
$64BitExePath = "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"

# Only add the registry key if the 32 bit version of Adobe was found.
if (Test-Path $32BitExePath) {
  # Look for the bUpdater DWord registry value
  $updateReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\" -Name bUpdater -ErrorAction SilentlyContinue
  
  # Create or set the registry DWord if it doesn't exist or isn't properly set.
  if (-not $updateReg -or $updateReg.bUpdater -ne 0) {
  	try {
  		New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\" -Name bUpdater -Value 0 -PropertyType DWord -Force
  	} catch {
  		Write-Host "Failed to disable Adobe auto updates: $_"
  		Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable Adobe auto updates: $_"
  
  		exit 1
  	}
  } else {
  	Write-Host "The bUpdater registry DWord is already properly set."
  	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The bUpdater registry DWord is already properly set."
  }
} 
elseif (Test-Path $64BitExePath) {
  Write-Host "The 64 bit version of adobe was found. Skipping the 32 bit lock registry key."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The 64 bit version of adobe was found. Skipping the 32 bit lock registry key."
} 
else {
  Write-Host "Adobe could not be found in its usual install pathway. Adobe is not installed or an old version of Adobe is installed."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") 6Adobe could not be found in its usual install pathway. Adobe is not installed or an old version of Adobe is installed."
  
  exit 1
}

Write-Host "Adobe auto updates are now disabled."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe auto updates are now disabled."