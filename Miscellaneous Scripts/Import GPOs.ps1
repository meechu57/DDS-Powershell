# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# The current list of GPOs that we are importing.
$GPOs = @("Folder Redirection", "Power Plan", "Time Server", "User Account Control", "User Profile Settings", "Windows Firewall")

# Convert the script variables to local variables.
$backupLocation = $env:gpo_backupLocation
$overrideGPOs = $env:overrideExistingGpos

Write-Host "Attempting to import the provided GPOs under the $backupLocation pathway..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to import the provided GPOs under the $backupLocation pathway..."

# Go through each GPO and import it. If the Override Existing GPOs box isn't checked, the script will exit if any of the GPOs already exist.
if (-not $overrideGPOs) {
	foreach ($GPO in $GPOs) {
    $existingGPO = Get-GPO -Name $GPO -ErrorAction SilentlyContinue
    
    if ($existingGPO) {
		  Write-Host "The $GPO GPO already exists. Please rename or delete the GPO and try agin."
		  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The $GPO GPO already exists. Please rename or delete the GPO and try agin."
      
		  exit 1 
		}
	}
}

# Go through each GPO and import it. If the Override Existing GPOs box isn't checked, the script will exit if any of the GPOs already exist.
foreach ($GPO in $GPOs) {
	try {
		Import-GPO -BackupGpoName $GPO -TargetName $GPO -path $backupLocation -CreateIfNeeded
	} catch {
		Write-Host "Failed to import the $GPO GPO: $_"
		Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to import the $GPO GPO: $_"
    
		exit 1
	}
}