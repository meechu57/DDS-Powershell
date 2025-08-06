# The log path for this script.
$logPath = "C:\DDS\Logs\Audit.log"

# Convert the script variable to a local variable.
$verbose = $env:verbose

# The end result array.
$results = @()

Write-Host "Running the weekly auditing..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Running the weekly auditing..."

function Audit-LogFiles {
  # For error tracking
  $errors = 0

  Write-Host "Auditing Log files..."
  
  # Looking for the script. If it doesn't exist, track the error.
  if (Test-Path 'C:\DDS\Logs\Scripts.log') {
    if ($verbose -eq $true) { Write-Host "The Scripts.log file exists." }
  } else {
    Write-Host "Couldn't find the Scripts.log file. Manual investigation is required."
    $errors++
  }
  
  # Looking for the script. If it doesn't exist, track the error.
  if (Test-Path 'C:\DDS\Logs\Maintenance.log') {
    if ($verbose -eq $true) { Write-Host "The Maintenance.log file exists." }
  } else {
    Write-Host "Couldn't find the Maintenance.log file. Manual investigation is required."
    $errors++
  }
   
  # Looking for the script. If it doesn't exist, track the error.
  if (Test-Path 'C:\DDS\Logs\Staging.log') {
    if ($verbose -eq $true) { Write-Host "The Staging.log file exists." }
  } else {
    Write-Host "Couldn't find the Staging.log file. Manual investigation is required."
    $errors++
  }
   
  # Looking for the script. If it doesn't exist, track the error.
  if (Test-Path 'C:\DDS\Logs\Audit.log') {
    if ($verbose -eq $true) { Write-Host "The Audit.log file exists." }
  } else {
    Write-Host "Couldn't find the Audit.log file. Manual investigation is required."
    $errors++
  }
  
  # Looking for the script. If it doesn't exist, track the error.
  if (Test-Path "C:\DDS\Logs\Scheduled Automation.log") {
    if ($verbose -eq $true) { Write-Host "The Scheduled Automation.log file exists." }
  } else {
    Write-Host "Couldn't find the Scheduled Automation.log file. Manual investigation is required."
    $errors++
  }
  
  # If errors are 0, all files exist. If more than 0, more than one log doesn't exist.
  if ($errors -eq 0) {
    Write-Host "All log files exist."
    return $true
  } else {
    Write-Host "$errors log file(s) don't exist. Manual investigation is required."
    return $false
  }
}

function Audit-WindowsFirewall {
  # For error tracking
  $errors = 0
  
  # Get the values of the 'Enabled' property for all three firewalls listed in the Get-NetFirewallProfile cmdlet.
  $firewalls = Get-NetFirewallProfile | Select-Object Name, Enabled
  
  # Ensure that we grabbed the values above correctly
  if ($firewalls) {
    Write-Host "Auditing Windows Firewall..."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Windows Firewall..."
  
    # Check to see if any of the values in $firewalls are 'True'
    foreach ($firewall in $firewalls) {
      if ($firewall.enabled -ne "False") {
        if ($verbose -eq $true) { Write-Host "The $($firewall.Name) firewall is enabled." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The $($firewall.Name) firewall is enabled."

        $errors++
      }
    }
  
    # If all three firewalls are disabled
    if ($errors -eq 0) {
      Write-Host "All firewalls are disabled."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All firewalls are disabled."
    
      return $true
    }
    # If any of the firewalls are enabled
    else {
      Write-Host "$($errors) firewall(s) are enabled. Manual investigation required."
      Add-Content -Path $logPath -Value "$($errors) firewall(s) are enabled. Manual investigation required."
    
      return $false
    }
  }
}

function Audit-TimeZone {
  # Gets the currently set time zone
  $timeZone = [System.TimeZoneInfo]::Local.id
  
  Write-Host "Auditing Time Zone..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Time Zone..."
  
  # Time zone should be set to EST
  if ($timeZone -eq "Eastern Standard Time") {
    Write-Host "Time zone is set correctly."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Time zone is set correctly"
    
    return $true
  }
  else {
    Write-Host "Time zone is set incorrectly. Current time zone is set to $($timeZone)"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Time zone is set incorrectly. Current time zone is set to $($timeZone)"
    
    return $false
  }
}

function Audit-Services {
  Write-Host "Auditing Services..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Services..."

  # Pulls the services to variables for use later
  $fdrpService = Get-Service -name FDResPub
  $ssdpService = Get-Service -name SSDPSRV
  $upnpService = Get-Service -name upnphost
  
  # For error tracking
  $errors = 0
  
  # Test to make sure the service gets pulled correctly
  if ($fdrpService -eq $null) {
    if ($verbose -eq $true) { Write-Host "The FDResPub service could not be found." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The FDResPub service could not be found."
    
    $errors++
  } 
  else {
    # If the service isn't set to Automatic or isn't running, it isn't configured properly
    if ($fdrpService.StartType -ne 'Automatic' -or $fdrpService.Status -ne 'Running') {
      if ($verbose -eq $true) { Write-Host "The FDResPub service is not configured properly. Manual investigation is required." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The FDResPub service is not configured properly. Manual investigation is required."
      
      $errors++
    }
  }
  
  # Test to make sure the service gets pulled correctly
  if ($ssdpService -eq $null) {
    if ($verbose -eq $true) { Write-Host "The SSDPSRV service could not be found." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The SSDPSRV service could not be found."
    
    $errors++
  } 
  else {
    # If the service isn't set to Automatic or isn't running, it isn't configured properly
    if ($ssdpService.StartType -ne 'Automatic' -or $ssdpService.Status -ne 'Running') {
      if ($verbose -eq $true) { Write-Host "The SSDPSRV service is not configured properly. Manual investigation is required." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The SSDPSRV service is not configured properly. Manual investigation is required."
      
      $errors++
    }
  }
  
  # Test to make sure the service gets pulled correctly
  if ($upnpService -eq $null) {
    if ($verbose -eq $true) { Write-Host "The upnphost service could not be found." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The upnphost service could not be found."
    
    $errors++
  } 
  else {
    # If the service isn't set to Automatic or isn't running, it isn't configured properly
    if ($upnpService.StartType -ne 'Automatic' -or $upnpService.Status -ne 'Running') {
      if ($verbose -eq $true) { Write-Host "The upnphost service is not configured properly. Manual investigation is required." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The upnphost service is not configured properly. Manual investigation is required."
      
      $errors++
    }
  }
  
  # If the error counter is 0, we're in the clear. If the above auditing caught any errors, the value will be greater than 0.
  if ($errors -eq 0) {
    Write-Host "All services are properly configured."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All services are properly configured."
    
    return $true
  } else {
    Write-Host "Errors were found in the configuration of the services. Number of services improperly configured: $errors."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Errors were found in the configuration of the services. Number of services improperly configured: $errors."
    
    return $false
  }
}

function Audit-IsoMounting {
  # Registry pathway for ISO Mounting
  $regPath = "HKCR\Windows.IsoFile\shell\mount"
  
  # Gets the value of the ProgrammaticAccessOnly registry key
  $programmaticAccessReg = Get-ItemProperty -Path "Registry::$regPath" -Name ProgrammaticAccessOnly -ErrorAction SilentlyContinue
  
  Write-Host "Auditing ISO Mounting..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing ISO Mounting..."
  
  if ($programmaticAccessReg -eq $null) {
    Write-Host "ISO Mounting is not disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") ISO Mounting is not disabled."
    
    return $false
  } 
  else {
    Write-Host "ISO Mounting is disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") ISO Mounting is disabled."
    
    return $true
  }
}

function Audit-NicConfiguration {
  # Get the NICs
  $NICs = [PSCustomObject]@{
    Value = Get-NetAdapter | Where-Object {$_.InterfaceDescription -notmatch 'Remote' -and $_.InterfaceDescription -notmatch 'Microsoft Network Adapter Multiplexor Driver' -and $_.InterfaceDescription -notmatch 'Virtual'}
    InactiveCount = 0
    SlowSpeedCount = 0
    PowerSavingCount = 0
    Output = ""
  }

  foreach ($NIC in $NICs.Value) {
    if ($NIC.status -eq "Up") {
      $speed = (($NIC.LinkSpeed) -split " ")
      if ($speed[1] -ne "Gbps") {
        Write-Host "The NIC '$($NIC.Name)' is running at less than 1 Gbps."
        $NICs.SlowSpeedCount++
      }
    } else {
      Write-Host "The NIC '$($NIC.Name)' is not active."
      $NICs.InactiveCount++
    }

    $powerSaving = (Get-NetAdapterPowerManagement -Name $NIC.Name -ErrorAction SilentlyContinue).AllowComputerToTurnOffDevice # Should be "Disabled"
    if ($powerSaving -eq $null -or $powerSaving -ne "Disabled") { 
      Write-Host "Allow Computer to Turn Off Device is not disabled on NIC: $($NIC.Name)"
      $NICs.PowerSavingCount++
    } 
  }

  if ($NICs.InactiveCount -ne 0) {
    $NICs.Output += " | Inactive NICs: $($NICs.InactiveCount)"
  }

  if ($NICs.SlowSpeedCount -ne 0) {
    $NICs.Output += " | NICs with low speeds: $($NICs.SlowSpeedCount)"
  }

  if ($NICs.PowerSavingCount -ne 0) {
    $NICs.Output += " | NICs with power saving enabled: $($NICs.PowerSavingCount)"
  }

  if ($NICs.InactiveCount -eq 0 -and $NICs.SlowSpeedCount -eq 0 -and $NICs.PowerSavingCount -eq 0) {
    $NICs.Output = "Compliant"
  }

  $NICs.Output = ($NICs.Output).TrimStart(" ", "|", " ")
    
  $nicTeam = [PSCustomObject]@{
    Value = (Get-NetAdapter | Where-Object {$_.InterfaceDescription -eq "Microsoft Network Adapter Multiplexor Driver"})
    State = $false
    Output = ""
  }
    
  if ($nicTeam.Value -ne $null -and $($nicTeam.Value).Status -eq "Up") {
    $nicTeam.State = $true
  } elseif ($nicTeam.Value -ne $null -and $($nicTeam.Value).Status -ne "Up") {
    $nicTeam.State = $false
    Write-Host "A NIC Team was found but it's currently in a 'Down' state."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A NIC Team was found but it's currently in a 'Down' state."
  } else {
    $nicTeam.State = $false
  }

  if ($nicTeam.State -eq $true) {
    $nicTeam.Output = "Active"
  } else {
    $nicTeam.Output = "No NIC Team"
  } 

  # Get the iDRAC config
  $iDRAC = [PSCustomObject]@{
    Value = racadm getniccfg
    State = $false
    IP = ""
    Port = ""
    Output = ""
  }

  if ($iDRAC.Value[0] -like "ERROR*") {
    Write-Host "No iDRAC license was found on the server. The iDRAC port is not in use."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No iDRAC license was found on the server. The iDRAC port is not in use."
  } else {
    $iDRAC.State = $true
    $iDRAC.IP = (($iDRAC.Value -match '^IP Address\s+=\s+([\d\.]+)$') -split '=')[1].Trim()
    $iDRAC.Port = (($iDRAC.Value -match '^NIC Selection\s+=\s+(.*)$') -split '=')[1].Trim()
    $DHCP = (($iDRAC.Value | Where-Object {$_ -like "DHCP Enabled*"}) -split '=')[1].Trim()

    if ($DHCP -eq 1) {
      Write-Host "WARNING! DHCP is enabled on the iDRAC Port: $($iDRAC.Port)"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! DHCP is enabled on the iDRAC Port: $($iDRAC.Port)"
    }
  }

  if ($iDRAC.State -eq $true) {
    $iDRAC.Output = "Active | IP: $($iDRAC.IP) | Port: $($iDRAC.Port)"
  } else {
    $iDRAC.Output = "Not Active"
  }
  
  $output = "NICs:`n$($NICs.Output)`nNIC Team: $($nicTeam.Output)`niDRAC: $($iDRAC.Output)"

  return $output
}

function Audit-UsbSettings {
  # For error tracking with USB controllers
  $usbControllerErrors = 0
  
  # For error tracking with USB devices
  $usbDeviceErrors = 0
  
  Write-Host "Auditing USB power settings..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing USB power settings..."
  
  # For error tracking
  $usbErrors = 0

  # Dynamic power devices
  $powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI

  # Get all USB devices with dynamic power options
  $usbDevices = Get-CimInstance -ClassName Win32_PnPEntity |
      Select-Object Name, @{ Name = "Enable"; Expression = { 
          $powerMgmt | Where-Object InstanceName -Like "*$($_.PNPDeviceID)*" | Select-Object -ExpandProperty Enable }} |
              Where-Object { $null -ne $_.Enable -and $_.Enable -eq $true } |  
                  Where-Object {$_.Name -like "*USB*" -and $_.Name -notlike "*Virtual*"}

  # Looking to see if the power settings are enabled for the USB devices/controllers
  foreach ($i in $usbDevices) {
    if ($i.Name -notlike "*USB GbE*") {
      if ($verbose -eq $true) { Write-Host "The following USB device isn't properly configured: $($i.Name)" }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The following USB device isn't properly configured: $($i.Name)"

      $usbErrors++
    }
  }
  
  # If either of the variables are more than 0, 1 or more USB device or controller doesn't have their power option disabled.
  if ($usbErrors -ne 0) {
    Write-Host "$usbErrors USB controller/USB device(s) don't have their power settings disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $usbErrors USB controller/USB device(s) don't have their power settings disabled."
    
    return $false
  }
  else {
    Write-Host "All USB controllers and USB devices have their power settings correctly configured."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All USB controllers and USB devices have their power settings correctly configured."
    
    return $true
  }
}

function Audit-AutoRun {
  # Get the current value of the NoDriveTypeAutorun key
  $autorunReg = Get-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer” -Name “NoDriveTypeAutorun” -ErrorAction SilentlyContinue

  # Set the value or create the NoDriveTypeAutorun key if it doesn't exist or isn't set correctly.
  if ($autorunReg -and $autorunReg.NoDriveTypeAutorun -eq 0xFF) {
    Write-Host "Autorun and Autoplay is disabled on all drives."
	  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Autorun and Autoplay is disabled on all drives."
  	
  	return $true
  } else {
  	Write-Host "Autorun and Autoplay is not disabled on all drives."
  	Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Autorun and Autoplay is not disabled on all drives."
  
  	return $false
  }
}

# Create custom objects for each function
$logFilesCreated = [PSCustomObject]@{
  Name = "Log Files"
  Value = Audit-LogFiles
}
$windowsFirewallDisabled = [PSCustomObject]@{
  Name = "Windows Firewall(s)"
  Value = Audit-WindowsFirewall
}
$timeZoneSet = [PSCustomObject]@{
  Name = "Time Zone"
  Value = Audit-TimeZone
}
$servicesConfigured = [PSCustomObject]@{
  Name = "Services"
  Value = Audit-Services
}
$isoMountingDisabled = [PSCustomObject]@{
  Name = "ISO Mounting"
  Value = Audit-IsoMounting
}
$networkAdapterConfigured = [PSCustomObject]@{
  Name = "Network Adapter"
  Value = Audit-NicConfiguration
}
$usbControllerConfigured = [PSCustomObject]@{
  Name = "USB Controller"
  Value = Audit-UsbSettings
}
$autoRunConfigured = [PSCustomObject]@{
  Name = "Auto Run"
  Value = Audit-AutoRun
}

# An array of all the above custom objects.
$auditingArray = @( $logFilesCreated, $windowsFirewallDisabled, $timeZoneSet, $servicesConfigured, $isoMountingDisabled, $usbControllerConfigured, $autoRunConfigured )

# Goes through the above array and if the value is false, add that setting to the end results string.
foreach ($function in $auditingArray) {
  if ($function.Value -eq $false) {
    $results += $function.Name
  }
}

# Get the Maintenance Override custom field & convert it to an array.
$maintenanceOverride = Ninja-Property-Get maintenanceOverride
$maintenanceOverride = $maintenanceOverride -split ", "
# Results array.
$overrideResults = @()

switch ($maintenanceOverride) {
  "dec97021-fa02-4adc-821c-abff6e69fefd" { $overrideResults += "Log Files" }
  "cc84545c-b5a4-42b5-a2ec-1a8469e36e09" { $overrideResults += "Modern Standby" }
  "10040f90-d273-45dc-8de3-8d4ef8007939" { $overrideResults += "UAC" }
  "35ec96d4-d9ca-448f-9113-412a032a01c6" { $overrideResults += "Power Options" }
  "49d6dcb4-1a25-42e0-afa6-d4abaa1af4a0" { $overrideResults += "Windows Firewall(s)" }
  "06c04c9e-259b-4db1-a876-60889f7519e7" { $overrideResults += "Time Zone" }
  "328fe778-9fc5-4b8f-bed0-3481693ff6ed" { $overrideResults += "Services" }
  "4c89cf44-45f8-4556-b9d6-413d639e5152" { $overrideResults += "Fast Boot" }
  "efc1cc8c-167b-44a2-b528-bfc43836dfa8" { $overrideResults += "ISO Mounting" }
  "caebe517-0874-45ac-b405-687b9225817e" { $overrideResults += "Network Adapter" }
  "1d70991b-e9c6-4e74-abea-18e2e1e1d471" { $overrideResults += "USB Controller" }
  "ff066c00-21ed-4862-948c-adaba98792b6" { $overrideResults += "Adobe" }
  "e3f52540-7f21-4dc5-9e4d-95e82d7372e4" { $overrideResults += "UCPD" }
  "9ff1a03d-74aa-4245-8f47-26394654d36d" { $overrideResults += "Auto Run" }
  Default { $overrideResults += "Unknown Input" }
}

if ($overrideResults -contains "Unknown Input") {
  Write-Host "Something went wrong with the Maintenance Override custom field. Exiting the script."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Something went wrong with the Maintenance Override custom field. Exiting the script."
  
  exit 1
} else {
  # Remove the audit inputs from the results
  if ($overrideResults -ne $null) {
    Write-Host "The following results will be excluded due to the Maintenance Overrides: $overrideResults"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The following results will be excluded due to the Maintenance Overrides: $overrideResults"
    
    $results = $results | Where-Object { $_ -notin $overrideResults }
  }
}

# Join the array into a string.
$results = $results -join ", "

# Shows what was caught in audit. If nothing was caught, set the results to 'Compliant'.
if ($results -eq "") {
  Write-Host "All audits passed. No issues found."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All audits passed. No issues found."
  if ($overrideResults -ne $null) {
    $results = "Compliant - With Override(s)"
  } else {
    $results = "Compliant"
  }
} else {
  Write-Host "The following settings are not configured properly: $results"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The following settings are not configured properly: $results"
}

# Add the NIC Configuration results
$results += "`n`n$($networkAdapterConfigured.Value)"

# Set the custom field.
Ninja-Property-Set serverAuditResults $results