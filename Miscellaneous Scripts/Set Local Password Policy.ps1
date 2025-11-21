# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

Write-Host "Attempting to set the Maximum Password Age to Unlimited in local security settings..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to set the Maximum Password Age to Unlimited in local security settings..."

# Pull the local security settings for maximum password age.
try {
	$pwPolicy = ((NET ACCOUNTS | Where-Object {$_ -like "Maximum password age (days)*"}) -split ":").trim()
} catch {
	# Should only error if somehow the local settings are bricked.
	Write-Host "No Maximum password age was found. Please manually investigate using the 'Net Accounts' command."
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No Maximum password age was found. Please manually investigate using the 'Net Accounts' command."

	exit 1
}

# Set the max password age to Unlimited if it's not already set to that value.
if ($pwPolicy[1] -ne "Unlimited") {
	Write-Host "The Maximum Password Age is currently set to $($pwPolicy[1]) days. Setting the value to 'Unlimited'..."
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The Maximum Password Age is currently set to $($pwPolicy[1]) days. Setting the value to 'Unlimited'..."

	NET ACCOUNTS /MAXPWAGE:UNLIMITED
} else {
	Write-Host "The Maximum Password Age is already set to $($pwPolicy[1])."
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The Maximum Password Age is already set to $($pwPolicy[1])."
}