# Pull the currently logged in or last logged in user's SID.
$computerName = $env:COMPUTERNAME
$userName = (Get-WmiObject -Class win32_process -ComputerName $computerName | Where-Object name -Match explorer).getowner().user
$SID = (Get-WmiObject win32_useraccount | Select name,sid | Where-object {$_.name -like "$userName*"}).SID

if ($SID.count -gt 1) {
	Write-Host "More than 1 SID found. Finding the active SID."
	foreach ($ID in $SID) {
		if (Test-Path registry::HKEY_USERS\$ID) {
			$SID = $ID
			break
		}
	}
}