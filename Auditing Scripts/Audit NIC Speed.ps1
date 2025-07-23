# The log path for this script.
$logPath = "C:\DDS\Logs\Audit.log"

Write-Host "Auditing the configuration of the NIC(s)..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the configuration of the NIC(s)..."

# Get the physical NIC(s) that are connected to ethernet.
$NICs = Get-NetAdapter | Where-Object {$_.Name -notlike "Wi-Fi"} | Where-Object {$_.status -eq "Up"}

$errors = 0

# Configure all NIC(s).
foreach ($NIC in $NICs) {
	$linkSpeed = $NICs.LinkSpeed
	$speedAndDuplex = Get-NetAdapterAdvancedProperty -Name $NICs.Name -RegistryKeyword "*SpeedDuplex"
	if ($linkSpeed -ne "1 Gbps") {
		Write-Host "The NIC $($NIC.name) is not currently running at 1 Gbps."

		$errors++
	}
	
	if ($speedAndDuplex.RegistryValue -ne 0) {

	}
}

if ($errors -ne 0) {
	Write-Host "Some NICs are running below 1 Gbps. Please investigate."
} else {
	Write-Host "All NICs are running at expected speeds."
}