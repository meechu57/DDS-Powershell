# Add the ServerInstall.log file if it doesn't exist.
if(!(Test-Path 'C:\DDS\Logs\Serverinstall.log')) {
  try { New-Item -ItemType File -Path "C:\DDS\Logs\ServerInstall.log" -Force } 
  catch { Write-Host "Unable to add ServerInstall.log to the directory C:\DDS\Logs" }
}

$logPath = "C:\DDS\Logs\ServerInstall.log"

# Define the new server name
$newServerName = $env:newServerName

# Erroring out when ran on a non-domain controller
if (-not ($(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2)) {
  Write-Error -Message "The script needs to be run on a domain controller!"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The script needs to be run on a domain controller!"
  
  exit 1
}

# Check that Active Directory module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
  Write-Host "Active Directory module is not available. Please install it and try again."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Active Directory module is not available. Please install it and try again."
  
  exit 1
}

# Verify that the given name is a DC
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name
if ($DCs -notcontains $newServerName) {
  Write-Host "'$newServerName' was not listed as a DC. Please try again."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") '$newServerName' was not listed as a DC. Please try again."
  
  exit 1
}

Write-Host "Attempting to transfer all FSMO Roles to '$newServerName'..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to transfer all FSMO Roles to '$newServerName'..."

# Transfer FSMO roles
try{
  Move-ADDirectoryServerOperationMasterRole -Identity $newServerName -OperationMasterRole 0,1,2,3,4 -Confirm:$false
}catch{
  Write-Host "Failed to transfer all FSMO Roles to '$newServerName': $_"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to transfer all FSMO Roles to '$newServerName': $_"
  
  exit 1
}

# Check the results of the transfer and show any roles that weren't properly transferred.
$currentRoles = netdom query fsmo | Where-Object {$_ -match '^\S.*\s+\S+\.\S+' -and $_ -notmatch 'command completed'}
$newServerFQDN = ([System.Net.Dns]::GetHostByName($newServerName)).HostName
$wrongRoles = 0

# Show the current roles.
$currentRoles

# Check the roles and ensure they're all transferred to $newServerName.
foreach ($line in $currentRoles) {
  $parts = $line -split '\s{2,}'
  if ($parts.Count -ge 2) {
    $roleName   = $parts[0].Trim()
    $roleServer = $parts[-1].Trim()

    if ($roleServer -ne $newServerFQDN) {
      Write-Host "Warning! The $roleName is not currently held by $newServerName."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The $roleName is not currently held by $newServerName."
      $wrongRoles++
    }
  }
}

if ($wrongRoles -eq 0) {
  Write-Host "All FSMO roles were successfully transferred to '$newServerName'."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All FSMO roles were successfully transferred to '$newServerName'."
  
  # Show the current roles.
  $currentRoles
} else {
  Write-Host "Warning! The FSMO role transfer did not completely transfer all roles to '$newServerName'."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The FSMO role transfer did not completely transfer all roles to '$newServerName'."
  
  # Show the current roles.
  $currentRoles
}