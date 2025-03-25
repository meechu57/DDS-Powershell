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
    exit 2
}

# Check if the DhcpServer module is installed
if (-not (Get-Module -ListAvailable -Name DhcpServer -ErrorAction SilentlyContinue)) {
    Write-Host "The DhcpServer module is not installed. Please install the DHCP server feature and the DhcpServer module."
    exit 2
}

$flag = $false

# Initialize the array and get all the active DHCPv4 scopes
$scopes = @()
$scopes = Get-DhcpServerv4Scope | Where-Object { $_.State -eq "Active" }

# Alert if there's more than active DHCP scope
if ($scopes.Count -gt 1) {
    Write-Host "Warning! More than 1 DHCP scope is active."
}

# Go through each scope and if the scope is above the threshold that is set, send a flag.
foreach ($scope in $scopes) {
    $stats = Get-DhcpServerv4ScopeStatistics -ScopeId $scope.ScopeId
    $percentInUse = [math]::Round($stats.PercentageInUse, 2)
    $availableLeases = $stats.Free

    if ($availableLeases -le 15 -or $percentInUse -ge 90) {
        Write-Host "The DHCP scope $($scope.name) is low on leases. The scope is $percentInUse% in use with $availableLeases available leases."

        $flag = $true
    }
}