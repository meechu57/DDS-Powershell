# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# The current list of GPOs that we are importing.
$allGPOs = @( "Folder Redirection", "Power Plan", "Time Server", "User Account Control", "User Profile Settings", "Windows Firewall" )

# Convert the script variables to local variables.
$backupLocation = $env:gpo_backupLocation
$overrideGPOs = $env:overrideExistingGpos
$importAllGPOs = $env:importAllGpos

# Convert the specific GPO script variables to custom variables with the value being the environment variable and the name being the GPO name.
$importFolderRedirection = [PSCustomObject]@{ Name = "Folder Redirection"; Value = $env:importFolderRedirectionGpo }
$importPowerPlan = [PSCustomObject]@{ Name = "Power Plan"; Value = $env:importPowerPlanGpo }
$importTimeServer = [PSCustomObject]@{ Name = "Time Server"; Value = $env:importTimeServerGpo }
$importUAC = [PSCustomObject]@{ Name = "User Account Control"; Value = $env:importUserAccountControlGpo }
$importUPS = [PSCustomObject]@{ Name = "User Profile Settings"; Value = $env:importUserProfileSettingsGpo }
$importFirewall = [PSCustomObject]@{ Name = "Windows Firewall"; Value = $env:importWindowsFirewallGpo }

# Combine all custom variables into an array
$importArray = @( $importFolderRedirection, $importPowerPlan, $importTimeServer, $importUAC, $importUPS, $importFirewall )

# The array where the GPOs that we'll be importing will go.
$GPOs = @()

# If we're importing all GPOs, use the variable from above. Otherwise, go through each GPO environment variable and configure the array to use only the GPOs that were requested.
if ($importAllGPOs) {
  $GPOs = $allGPOs
} else {
  foreach ($GPO in $importArray) {
    if ($GPO.Value) {
      $GPOs += $GPO.Name
    }
  }
}

Write-Host "Attempting to import the following GPOs under the $backupLocation pathway: $($GPOs -join ", ")"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to import the following GPOs under the $backupLocation pathway: $($GPOs -join ", ")"

# Go through each GPO and import it. If the Override Existing GPOs box isn't checked, the script will exit if any of the GPOs already exist.
if ($overrideGPOs -eq "No") {
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

Write-Host "Successfully imported all GPOs requested."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully imported all GPOs requested."