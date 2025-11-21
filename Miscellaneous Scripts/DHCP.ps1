$cs = Get-CimInstance Win32_ComputerSystem

$computerName = "$($cs.Name).$($cs.Domain)"

$scopeID 

$filePath = "\\testserver2019\Installs\DHCP\DHCPdata.xml"

$domain = (Get-CimInstance Win32_ComputerSystem).Domain

$oldServer = "TestServer2019"
$oldServer += ".$domain"

$newServer = "TestServer2025"
$newServer += ".$domain"


Export-DhcpServer -File $filePath  -Leases -Force -ComputerName $oldServer –Verbose

Import-DhcpServer -File $filePath  -BackupPath C:\DHCP\ -Leases -ScopeOverwrite -Force -ComputerName $newServer –Verbose

get-dhcpserverv4scope | Set-DhcpServerv4Scope -State InActive

Get-DhcpServerv4Scope |  Set-DhcpServerv4OptionValue -ComputerName $newServer -DnsServer 192.168.150.10