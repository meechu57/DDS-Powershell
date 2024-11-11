# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Yoinked this from https://gist.github.com/techdecline/3abd31a502addda67cd3b477e0fd2a23
# Edited a few formatting things but everything else is from the link.
function Get-Gplink {
<# 
.SYNOPSIS
return and decode content of gplink attribut
.DESCRIPTION
This function purpose is to list the gplink attribut of an OU, Site or DomainDNS.
It will return the following information for each linked GPOs:
  - Target: DN of the targeted object
  - GPOID: GUID of the GPO
  - GPOName: Friendly Name of the GPO
  - GPODomain: Originating domain of the GPO
  - Enforced: <Yes|No>
  - Enabled:  <Yes|No>
  - Order: Link order of the GPO on the OU,Site,DomainDNS (does not report inherited order)
.PARAMETER Path: Give de Distinguished Name of object you want to list the gplink
.INPUTS
DN of the object with GLINK attribut
.OUTPUTS
Target: DC=fourthcoffee,DC=com
GPOID: 31B2F340-016D-11D2-945F-00C04FB984F9
GPOName: Default Domain Policy
GPODomain: fourthcoffee.com
Enforced: <YES - NO>
Enabled: <YES - NO>
Order: 1
.EXAMPLE
get-gplink -path "dc=fourthcoffee,dc=com"
This command will list the GPOs that are linked to the DomainDNS object "dc=fourthcoffee,dc=com" 
.EXAMPLE
get-gplink -path "dc=child,dc=fourthcoffee,dc=com" -server childdc.child.fourthcoffee.com
This command will list the GPOs that are linked to the DomainDNS object "dc=child,dc=fourthcoffee,dc=com". You need to specify a
target DC of the domain child.fourthcoffee.com in order for the command to work.
.EXAMPLE
Get-Gplink -site "CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=fourthcoffee,DC=com"
This command will list the GPOs that are linked to site "Default-First-Site-Name"
.EXAMPLE
get-gplink -path "dc=fourthcoffee,dc=com" | export-csv "gplink.csv"
This command will list the GPOs that are linked to the DomainDNS object "dc=fourthcoffee,dc=com" and export them to a csv file.
The csv file can be used as an input to the cmdlet new-gplink 
.EXAMPLE
get-adobject -filter {(objectclass -eq "DomainDNS") -or (objectclass -eq "OrganizationalUnit")} | foreach {get-gplink -path $_.distinguishedname} | export-csv "gplinksall.csv"
This command will list all objects of type "DomainDNS" and "OrganizationalUnit" that have GPOs linked and will list those GPOs, their status and link order.
#>

[cmdletBinding()]
param ([string]$path,[string]$server,[string]$site)

# Import AD and GPO modules
Import-Module activedirectory
Import-Module grouppolicy
# Get the DN to te configuration partition
$configpart = (Get-ADRootDSE).configurationNamingContext

# Get content of attribut gplink on site object or OU
if ($site) {
  $gplink = Get-ADObject -Filter {distinguishedname -eq $site} -searchbase $configpart -Properties gplink
  $target = $site
}
elseif ($path) {
  switch ($server) {
      "" {$gplink=Get-ADObject -Filter {distinguishedname -eq $path} -Properties gplink}
      default {$gplink=Get-ADObject -Filter {distinguishedname -eq $path} -Properties gplink -server $server     
    }
  }
  $target=$path
}

# If DN is not valid return "Invalide DN" error
if ($gplink -eq $null) {
  Write-Host "Either Invalide DN in the current domain, specify a DC of the target DN domain or no GPOlinked to this DN"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Either Invalide DN in the current domain, specify a DC of the target DN domain or no GPOlinked to this DN"
}

# Test if glink is not null or only containes white space before continuing. 
if (!((($gplink.gplink) -like "") -or (($gplink.gplink) -like " "))) {
  # Set variale $o to define link order
  $o = 0    

  # Split the gplink string in order to seperate the diffent GPO linked
  $split = $gplink.gplink.split("]")

  # Do a reverse for to get the proper link order
  for ($s = $split.count-1;$s -gt -1;$s--) {
    # Since the last character in the gplink string is a "]" the last split is empty we need to ignore it
    if ($split[$s].length -gt 0) {
      $o++
      $order = $o            
      $gpoguid = $split[$s].substring(12,36)
      $gpodomainDN = ($split[$s].substring(72)).split(";")
      $domain = ($gpodomaindn[0].substring(3)).replace(",DC=",".")
      $checkdc = (get-addomaincontroller -domainname $domain -discover).name
      
      # Test if the $gpoguid is a valid GUID in the domain if not we return a "Oprhaned GpLink or External GPO" in the $gponname
      $mygpo = get-gpo -guid $gpoguid -domain $domain -server "$($checkdc).$($domain)" 2> $null
        
      if ($mygpo -ne $null ) {
       $gponame = $MyGPO.displayname
       $gpodomain = $domain	
      }	
      else {
        $gponame = "Orphaned GPLink" 
        $gpodomain = $domain   
      }
      
      # Test the last 2 charaters of the split do determine the status of the GPO link
      if (($split[$s].endswith(";0"))) {
        $enforced = "No"
        $enabled = "Yes"
      }
      elseif (($split[$s].endswith(";1"))) {
        $enabled = "No"
        $enforced = "No"
      }
      elseif (($split[$s].endswith(";2"))) {
        $enabled = "Yes"
        $enforced = "Yes"
      }
      elseif (($split[$s].endswith(";3"))) {
        $enabled = "No"
        $enforced = "Yes"
      }
      
      # Create an object representing each GPOs, its links status and link order
      $return = New-Object psobject 
      $return | Add-Member -membertype NoteProperty -Name "Target" -Value $target 
      $return | Add-Member -membertype NoteProperty -Name "GPOID" -Value $gpoguid
      $return | Add-Member -membertype NoteProperty -Name "DisplayName" -Value $gponame
      $return | Add-Member -membertype NoteProperty -Name "Domain" -Value $gpodomain
      $return | Add-Member -membertype NoteProperty -Name "Enforced" -Value $enforced
      $return | Add-Member -membertype NoteProperty -Name "Enabled" -Value $enabled
      $return | Add-Member -membertype NoteProperty -Name "Order" -Value $order
      $return
      }
    }
  }
}

# Tests if the device the script is running on is a dmona controller.
function Test-IsDomainController {
  return $(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2
}

# Erroring out when ran on a non-domain controller
if (-not (Test-IsDomainController)) {
  Write-Host "The script needs to be run on a domain controller!"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The script needs to be run on a domain controller!"
  
  exit 1
}

# The current list of GPOs that we are importing.
$allGPOs = @( "Folder Redirection", "Power Plan", "Time Server", "User Account Control", "User Profile Settings", "Windows Firewall" )

# Convert the script variables to local variables.
$backupLocation = $env:gpo_backupLocation
$overrideGPOs = $env:overrideExistingGpos
$importAllGPOs = $env:importAllGpos
$linkGPOs = $env:linkGpos

if (-not (Test-Path $backupLocation)) {
  Write-Host "Invalid backup location pathway. Please input another location"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Invalid backup location pathway. Please input another location"
  
  exit 1
}

# Convert the specific GPO script variables to custom variables with the value being the environment variable and the name being the GPO name.
$importFolderRedirection = [PSCustomObject]@{ Name = "Folder Redirection"; Value = $env:importFolderRedirectionGpo }
$importPowerPlan = [PSCustomObject]@{ Name = "Power Plan"; Value = $env:importPowerPlanGpo }
$importTimeServer = [PSCustomObject]@{ Name = "Time Server"; Value = $env:importTimeServerGpo }
$importUAC = [PSCustomObject]@{ Name = "User Account Control"; Value = $env:importUserAccountControlGpo }
$importUPS = [PSCustomObject]@{ Name = "User Profile Settings"; Value = $env:importUserProfileSettingsGpo }
$importFirewall = [PSCustomObject]@{ Name = "Windows Firewall"; Value = $env:importWindowsFirewallGpo }

# Combine all custom variables into an array
$importArray = @( $importFolderRedirection, $importPowerPlan, $importTimeServer, $importUAC, $importUPS, $importFirewall )

# The array where the GPOs that we'll be importing will go.
$GPOs = @()

# If we're importing all GPOs, use the variable from above. Otherwise, go through each GPO environment variable and configure the array to use only the GPOs that were requested.
if ($importAllGPOs -eq $true) {
  $GPOs = $allGPOs
} else {
  foreach ($GPO in $importArray) {
    if ($GPO.Value -eq $true) {
      $GPOs += $GPO.Name
    }
  }
}

Write-Host "Attempting to import the following GPOs under the $backupLocation pathway: $($GPOs -join ", ")"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to import the following GPOs under the $backupLocation pathway: $($GPOs -join ", ")"

# If the Override Existing GPOs box is set to no, the script will exit if any of the GPOs already exist.
if ($overrideGPOs -eq "No") {
	foreach ($GPO in $GPOs) {
    $existingGPO = Get-GPO -Name $GPO -ErrorAction SilentlyContinue
    
    if ($existingGPO) {
      Write-Host "The $GPO GPO already exists. Please rename or delete the GPO and try agin."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The $GPO GPO already exists. Please rename or delete the GPO and try agin."
      
      exit 1 
		}
	}
}

# Go through each GPO, import it, and link it.
if ($linkGPOs -eq $true) {
  Write-Host "Linking the requested GPOs..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Linking the requested GPOs..."
  
  # Get the domain for the target when linking the GPO
  $domain = "DC=$($(Get-CimInstance Win32_ComputerSystem).Domain -split "\." -join ",DC=")"
  
  # Get all linked domains in the main domain
  $linkedGPOs = (Get-Gplink -path $domain).DisplayName
  
  foreach ($GPO in $GPOs) {
    if ($GPO -eq "Time Server") {
      # Include the Domain Controllers OU in the target for Time Server
      $target = "OU=Domain Controllers," + $domain
      # Get the GPOs linked under Domain Controllers
      $dcGPOs = (Get-Gplink -path $domain).DisplayName
      
      if ($dcGPOs -contains "Time Server") {
        Write-Host "The $GPO GPO is already linked. The GPO will be imported and the existing link will still exist."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The $GPO GPO is already linked. The GPO will be imported and the existing link will still exist."
        
        try {
          Import-GPO -BackupGpoName $GPO -TargetName $GPO -path $backupLocation -CreateIfNeeded
        } catch {
          Write-Host "Failed to import the $GPO GPO: $_"
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to import the $GPO GPO: $_"
          
          exit 1
        }
      } else {
        try {
          Import-GPO -BackupGpoName $GPO -TargetName $GPO -path $backupLocation -CreateIfNeeded
          
          Write-Host "Linking the $GPO GPO..."
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Linking the $GPO GPO..."
          New-GPLink -Name $GPO -Target $target
        } catch {
          Write-Host "Failed to import the $GPO GPO: $_"
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to import the $GPO GPO: $_"
          
          exit 1
        }
      }
    } else {
      if ($linkedGPOs -contains $GPO) {
        Write-Host "The $GPO GPO is already linked. The GPO will be imported and the existing link will still exist."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The $GPO GPO is already linked. The GPO will be imported and the existing link will still exist."
        
        try {
          Import-GPO -BackupGpoName $GPO -TargetName $GPO -path $backupLocation -CreateIfNeeded
        } catch {
          Write-Host "Failed to import the $GPO GPO: $_"
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to import the $GPO GPO: $_"
          
          exit 1
        }
      } else {
        try {
          Import-GPO -BackupGpoName $GPO -TargetName $GPO -path $backupLocation -CreateIfNeeded
          
          Write-Host "Linking the $GPO GPO..."
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Linking the $GPO GPO..."
          New-GPLink -Name $GPO -Target $domain
        } catch {
          Write-Host "Failed to import the $GPO GPO: $_"
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to import the $GPO GPO: $_"
          
          exit 1
        }
      }
    }
  }
} 
else {
  # Go through each GPO and import it.
  foreach ($GPO in $GPOs) {
    try {
      Import-GPO -BackupGpoName $GPO -TargetName $GPO -path $backupLocation -CreateIfNeeded
    } catch {
      Write-Host "Failed to import the $GPO GPO: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to import the $GPO GPO: $_"
      
      exit 1
    }
  }
}

Write-Host "Successfully imported all GPOs requested."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully imported all GPOs requested." 