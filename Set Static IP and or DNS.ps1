# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

$ipAddress = "$env:ipAdress"
$subnetMask = $env:prefixLength
$defaultGateway = "$env:defaultGateway"
$primaryDNS = "$env:primaryDns"
$secondaryDNS = "$env:secondaryDns"

# Gets the list of active physical NICs
$networkAdapter = Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'}

# Abort if there's more than 1 NIC.
if ($networkAdapter.name.count -eq 1) {
  switch ($env:configuration){
    "Configure IP and DNS" {
      Write-Host "Configuring a static IP and DNS on the $($networkAdapter).name NIC."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring a static IP and DNS on the $($networkAdapter).name NIC."
      
      New-NetIPAddress -InterfaceIndex $networkAdapter.InterfaceIndex -IPAddress $ipAddress -PrefixLength $subnetMask -DefaultGateway $defaultGateway
      Set-DnsClientServerAddress -InterfaceIndex $networkAdapter.InterfaceIndex -ServerAddresses ($primaryDns, $secondaryDns)
   }
    "Configure DNS" {
      Write-Host "Configuring static DNS on the $($networkAdapter).name NIC."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring static DNS on the $($networkAdapter).name NIC."
      
      # Configure static DNS
      Set-DnsClientServerAddress -InterfaceIndex $networkAdapter.InterfaceIndex -ServerAddresses ($primaryDns, $secondaryDns)
   }
  }
}
else {
  Write-Host "More than one active NIC found, aborting script."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") More than one active NIC found, aborting script."
}
