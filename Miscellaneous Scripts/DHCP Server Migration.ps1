# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# The FQDN of the new server.
$newServer = $env:newServerName
$newServer += "."
$newServer += (Get-CimInstance Win32_ComputerSystem).Domain

# Find the IP of the new server. If the new server cannot be found, exit the script.
try {
  $newServerIP = (Get-NetIPAddress -CimSession $newServer -AddressFamily IPv4 | where { $_.InterfaceAlias -notmatch 'Loopback'}).IPAddress 
} catch {
  Write-Host "$newServer was not found on the network. Please check the name that was input and try again."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $newServer was not found on the network. Please check the name that was input and try again."
  
  exit 1
}

# The location where the DHCPdata.xml file will be exported to.
$exportPath = $env:exportLocation

# Test the Export Location and create the DHCPdata.xml file if everything checks out.
if ((Test-Path -Path $exportPath) -eq $false) {
  Write-Host "Could not find the Export Location specified. Please check the pathway and try again."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Could not find the Export Location specified. Please check the pathway and try again."
  
  exit 1
} else {
  $exportPath += "\DHCPdata.xml"
  New-Item -Path $exportPath -Force | Out-Null
}

# Get the FQDN of the current server.
$cs = Get-CimInstance Win32_ComputerSystem
$currentServer = "$($cs.Name).$($cs.Domain)"

# Get the active DHCP scope(s).
$scope = Get-DhcpServerv4Scope | Where-Object {$_.State -eq "Active"}

# Check that an active scope was found. Exit if no active scopes.
if ($scope -eq $null) {
  Write-Host "Not active DHCP scope was found. Please try again with an active DHCP scope."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Not active DHCP scope was found. Please try again with an active DHCP scope."
  
  exit 1
}

Write-Host "Changing the scope option 'DNS Server' to $newServerIP."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Changing the scope option 'DNS Server' to $newServerIP."

# Update the DNS server before exporting.
$scope | Set-DhcpServerv4OptionValue -ComputerName $currentServer -DnsServer $newServerIP

Write-Host "Exporting the DHCP Server from $currentServer..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Exporting the DHCP Server from $currentServer..."

# Export the DHCP scope.
Export-DhcpServer -File $exportPath -Leases -Force -ComputerName $currentServer

Write-Host "Importing the DHCP Server on $newServer..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Importing the DHCP Server on $newServer..."

# Import the DHCP scope on the new server.
Import-DhcpServer -File $exportPath  -BackupPath "%temp%\DHCP" -Leases -ScopeOverwrite -Force -ComputerName $newServer -ErrorAction SilentlyContinue

Write-Host "Deactivating the old DHCP scope on $currentServer..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Deactivating the old DHCP scope on $currentServer..."

# Deactivate the DHCP scope on the current server.
$scope | Set-DhcpServerv4Scope -State InActive