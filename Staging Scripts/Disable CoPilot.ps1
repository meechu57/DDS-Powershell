# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

Write-Host "Attempting to disable Copilot..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to disable Copilot..."

# Pathway for the WindowsCopilot key. Also pulls the TurnOffWindowsCopilot to see if it already is set.
$regPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
$copilotRegKey =  Get-ItemProperty -Path $regPath -Name TurnOffWindowsCopilot -ErrorAction SilentlyContinue

# Check to see if the key is already properly set.
if ($copilotRegKey.TurnOffWindowsCopilot -eq 1) {
	Write-Host "Copilot is already disabled."
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Copilot is already disabled."
} else {
	# Create the WindowsCopilot registry key if it doesn't exist.
	if (-not (Test-Path $regPath)) {
		try {
			New-Item -Path $regPath -force
		} catch {
			Write-Host "An error occured when attempting to at the WindowsCopilot registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occured when attempting to at the WindowsCopilot registry key: $_"

			exit 1
		}
	}

	# Set the TurnOffWindowsCopilot DWORD if it doesn't exist or isn't properly set.
	if (-not $copilotRegKey -or $copilotRegKey.TurnOffWindowsCopilot -ne 1) {
		try {
			New-ItemProperty -Path $regPath -Name TurnOffWindowsCopilot -PropertyType DWORD -Value 1 -Force
		} catch {
			Write-Host "An error occured when attempting to at the TurnOffWindowsCopilot registry DWORD: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occured when attempting to at the TurnOffWindowsCopilot registry DWORD: $_"
			
			exit 1
		}
	}

	# Check that the DWORD was set properly.
	$copilotRegKey =  Get-ItemProperty -Path $regPath -Name TurnOffWindowsCopilot -ErrorAction SilentlyContinue

	if ($copilotRegKey.TurnOffWindowsCopilot -eq 1) {
		Write-Host "Successfully disabled Copilot."
		Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully disabled Copilot."
	} else {
		Write-Host "Copilot was not disabled. Please check manually check for any errors."
		Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Copilot was not disabled. Please check manually check for any errors."

		exit 1
	}
}