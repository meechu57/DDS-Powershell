# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

Write-Host "Auditing Autorun and Autoplay..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Autorun and Autoplay..."

# Get the current value of the NoDriveTypeAutorun key
$autorunReg = Get-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer” -Name “NoDriveTypeAutorun” -ErrorAction SilentlyContinue
# The value we're looking for
$value = 0xFF

# Set the value or create the NoDriveTypeAutorun key if it doesn't exist or isn't set correctly.
if ($autorunReg -and $autorunReg.NoDriveTypeAutorun -eq $value) {
    Write-Host "Autorun and Autoplay is disabled on all drives."
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Autorun and Autoplay is disabled on all drives."
} else {
	Write-Host "Autorun and Autoplay is not disabled on all drives."
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Autorun and Autoplay is not disabled on all drives."

	exit 1
}