# Link to GitHub article https://github.com/21bshwjt/SysVol-D4-PowerShell

# Add the ServerInstall.log file if it doesn't exist.
if(!(Test-Path 'C:\DDS\Logs\Serverinstall.log')) {
  try { New-Item -ItemType File -Path "C:\DDS\Logs\ServerInstall.log" -Force } 
  catch { Write-Host "Unable to add ServerInstall.log to the directory C:\DDS\Logs" }
}
$logPath = "C:\DDS\Logs\ServerInstall.log"

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


# Check to make sure the script is being ran on the PDC.
if (([System.Net.Dns]::GetHostByName($env:computerName)).HostName -ne (Get-ADDomain).PDCEmulator) {
  Write-Host "Please run the script on the server with the PDC role. PDC: $((Get-ADDomain).PDCEmulator)"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Please run the script on the server with the PDC role. PDC: $((Get-ADDomain).PDCEmulator)"

  exit 1
}

# Step 1
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name

$DCs | ForEach-Object -Process {
  try {
    Invoke-Command -ComputerName $PSItem -ScriptBlock {
      Set-Service -Name 'DFSR' -StartupType Manual -Verbose
      Stop-Service -Name 'DFS Replication' -Force -Verbose
    } -ErrorAction Stop
  } catch {
    Write-Error "Failed to modify DFSR service on $PSItem | Error: $_"
  }
}

Start-Sleep -Seconds 3

# Step 2
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name
$GetoBj = Foreach ($DC in $DCs) {
  Invoke-Command -ComputerName $DC {
    [PSCustomObject]@{
      DomainController = ($env:COMPUTERNAME).ToUpper()
      ServiceName      = (Get-Service -Name DFSR).Name
      Status           = (Get-Service -Name DFSR).Status
      StartType        = (Get-Service -Name DFSR).StartType
    }
  }
}
$GetoBj | Select-Object -Property DomainController, ServiceName, Status, StartType

Start-Sleep -Seconds 3

# Step 4
$PDCNameFull = (Get-ADDomain).PDCEmulator
$PDCName     = $PDCNameFull -split '\.' | Select-Object -First 1
$domain      = (Get-ADDomain).DistinguishedName
$dn          = "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$PDCName,OU=Domain Controllers,$domain"

Set-ADObject -Identity $dn -Replace @{
  "msDFSR-Enabled" = $False
  "msDFSR-options" = 1
} -Verbose

Start-Sleep -Seconds 3

# Step 5
$domain = (Get-ADDomain).DistinguishedName
$DCs    = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name

foreach ($DC in $DCs) {
  $dn = "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,OU=Domain Controllers,$domain"
  Set-ADObject -Identity $dn -Replace @{
    "msDFSR-Enabled" = $False
  } -Verbose
}

Start-Sleep -Seconds 3

# Step 6
repadmin /syncall /A /e /P /d /q

Start-Sleep -Seconds 3

# Step 7
$PDCNameFull = (Get-ADDomain).PDCEmulator
$PDCName     = $PDCNameFull -split '\.' | Select-Object -First 1

Invoke-Command -ComputerName $PDCName {
  Start-Service -Name 'DFS Replication' -Verbose
}

Start-Sleep -Seconds 3

# Step 9
$PDCNameFull = (Get-ADDomain).PDCEmulator
$PDCName     = $PDCNameFull -split '\.' | Select-Object -First 1
$domain      = (Get-ADDomain).DistinguishedName
$dn          = "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$PDCName,OU=Domain Controllers,$domain"

Set-ADObject -Identity $dn -Replace @{
  "msDFSR-Enabled" = $True
} -Verbose

Start-Sleep -Seconds 3

# Step 10
repadmin /syncall /A /e /P /d /q

Start-Sleep -Seconds 3

# Step 11
DFSRDIAG POLLAD

Start-Sleep -Seconds 3

# Step 13
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name

$DCs | ForEach-Object -Process {
  Invoke-Command -ComputerName $PSItem {
    Start-Service -Name 'DFS Replication' -Verbose
  }
}

Start-Sleep -Seconds 3

# Step 14
$domain = (Get-ADDomain).DistinguishedName
$DCs    = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name

foreach ($DC in $DCs) {
  $dn = "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,OU=Domain Controllers,$domain"
  Set-ADObject -Identity $dn -Replace @{
    "msDFSR-Enabled" = $True
  } -Verbose
}

Start-Sleep -Seconds 3

# Step 15
$servers     = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name
$PDCNameFull = (Get-ADDomain).PDCEmulator
$PDCName     = $PDCNameFull -split '\.' | Select-Object -First 1

# Exclude PDC from the list
$servers = $servers | Where-Object { $_ -ne $PDCName }

$servers | ForEach-Object -Process {
  Invoke-Command -ComputerName $PSItem { DFSRDIAG POLLAD -Verbose }
}

Start-Sleep -Seconds 3

# Step 16
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name

$DCs | ForEach-Object -Process {
  Invoke-Command -ComputerName $PSItem {
    Set-Service -Name 'DFSR' -StartupType Automatic -Verbose
  }
}

Start-Sleep -Seconds 3

# Step 17
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name

$GetoBj = foreach ($DC in $DCs) {
  try {
    Invoke-Command -ComputerName $DC -ScriptBlock {
      [PSCustomObject]@{
        DomainController = $env:COMPUTERNAME.ToUpper()
        ServiceName      = (Get-Service -Name DFSR -ErrorAction Stop).Name
        Status           = (Get-Service -Name DFSR -ErrorAction Stop).Status
        StartType        = (Get-Service -Name DFSR -ErrorAction Stop).StartType
      }
    }
  } catch {
    [PSCustomObject]@{
      DomainController = $DC.ToUpper()
      ServiceName      = "DFSR"
      Status           = "Error: $($Error[0].Exception.Message)"
      StartType        = "Unknown"
    }
  }
}
$GetoBj | Select-Object -Property DomainController, ServiceName, Status, StartType

Start-Sleep -Seconds 3

# Step 18
$servers = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name

foreach ($server in $servers) {
  try {
    $result = Get-WmiObject -Namespace "root\microsoftdfs" -Class "dfsrreplicatedfolderinfo" `
      -ComputerName $server -Filter "replicatedfoldername='SYSVOL share'" |
      Select-Object @{Name = 'DomainController'; Expression = { $_.MemberName } }, ReplicationGroupName, ReplicatedFolderName, State
    if ($result) {
      $result
    } else {
      Write-Warning "No DFSR info found on $server for 'SYSVOL share'."
    }
  } catch {
    Write-Warning "Error querying $server : $_"
  }
}

Start-Sleep -Seconds 3

# Step 19
$domain = (Get-ADDomain).DistinguishedName
$DCs    = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name

$Objs = Foreach ($DC in $DCs) {
  Get-ADObject -Filter { Name -eq "SYSVOL Subscription" } `
    -SearchBase "CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,OU=Domain Controllers,$domain" `
    -Properties DistinguishedName, msDFSR-Enabled, msDFSR-options |
    Select-Object DistinguishedName, msDFSR-Enabled, msDFSR-options
}

foreach ($Obj in $Objs) {
  $msDFSR_options = $Obj.'msDFSR-options'
  if ([string]::IsNullOrWhiteSpace($msDFSR_options)) { $msDFSR_options = "<not set>" }

  [PSCustomObject]@{
    DomainController = ($Obj.DistinguishedName -split ",")[3].Substring(3)
    "msDFSR-Enabled" = $Obj.'msDFSR-Enabled'
    "msDFSR-options" = $msDFSR_options
  }
}