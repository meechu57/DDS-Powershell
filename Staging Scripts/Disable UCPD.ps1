# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

Write-Host "Attempting to disable the User Choice Protection Driver..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to disable the User Choice Protection Driver..."

# Get the current state of the registry key
$UCPD = Get-ItemProperty -Path �HKLM:\SYSTEM\CurrentControlSet\Services\UCPD� -Name �Start� -ErrorAction SilentlyContinue

# Set the registry key if it exists. If the key doesn't exist, we shouldn't have to worry about it.
if ($UCPD -and $UCPD.Start -ne 4) {
	try {
		New-ItemProperty -Path �HKLM:\SYSTEM\CurrentControlSet\Services\UCPD� -Name �Start� -Value 4 -PropertyType DWORD -Force

		Write-Host "Successfully set the UCPD Start registry value. A reboot is required to apply the setting."
		Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully set the UCPD Start registry value. A reboot is required to apply the setting."
	} catch {
		Write-Host "Failed to set the UCPD Start registry key: $_"
		Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the UCPD Start registry key: $_"

		exit 1
	}
} elseif (-not $UCPD) {
	Write-Host "The UCPD driver doesn't exist. Exiting the script."
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver doesn't exist. Exiting the script."

	exit 1
}