# The log path for this script.
$logPath = "C:\DDS\Logs\Audit.log"

function Test-IsElevated {
	# Check if running under a Pester test case
	$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$p = New-Object System.Security.Principal.WindowsPrincipal($id)
	$p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsElevated)) {
  Write-Host "Access Denied. Please run with Administrator privileges."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Access Denied. Please run with Administrator privileges."
  exit 2
}

# Check if the DhcpServer module is installed
if (-not (Get-Module -ListAvailable -Name DhcpServer -ErrorAction SilentlyContinue)) {
  Write-Host "The DhcpServer module is not installed. Please install the DHCP server feature and the DhcpServer module."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The DhcpServer module is not installed. Please install the DHCP server feature and the DhcpServer module."
  exit 2
}

Write-Host "Auditing the DHCP scope..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the DHCP scope..."

# Flag for alerting if a ticket needs to be generated.
$flag = $false

# Initialize the array and get all the active DHCPv4 scopes
$scopes = @()
$scopes = Get-DhcpServerv4Scope | Where-Object { $_.State -eq "Active" }

# Alert if there's more than active DHCP scope
if ($scopes.Count -gt 1) {
  Write-Host "Warning! More than 1 DHCP scope is active."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! More than 1 DHCP scope is active."
  
  $flag = $true
} elseif ($scopes.Count -lt 1) {
  Write-Host "No active DHCP scope was found."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No active DHCP scope was found."
}

# Go through each scope and if the scope is above the threshold that is set, set a flag.
foreach ($scope in $scopes) {
  $stats = Get-DhcpServerv4ScopeStatistics -ScopeId $scope.ScopeId
  $percentInUse = [math]::Round($stats.PercentageInUse, 2)
  $availableLeases = $stats.Free

  if ($availableLeases -le 15 -or $percentInUse -ge 90) {
    Write-Host "The DHCP scope $($scope.name) is low on leases. The scope is $percentInUse% in use with $availableLeases available leases."
	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The DHCP scope $($scope.name) is low on leases. The scope is $percentInUse% in use with $availableLeases available leases."
    
    $flag = $true
  }
}

# Tell Ninja to create the ticket.
if ($flag -eq $true) {
  Write-Host "The DHCP flag was tripped. Creating a ticket."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The DHCP flag was tripped. Creating a ticket."
  
  exit 1
}