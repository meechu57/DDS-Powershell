# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Pull the custom field and trim the end of the audit results.
$auditInput = Ninja-Property-Get auditResults
if ($auditInput -ne $null) {
  $auditInput = $auditInput.Trim()
  $auditInput = $auditInput.TrimEnd(',')
} else {
  $auditInput = "Compliant"
}

# Show what is going to be configured.
if ($auditInput -eq "Compliant") {
  Write-Host "This device is fully compliant!"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") This device is fully compliant!"
} elseif ($auditInput -eq "Compliant - With Override(s)") {
  Write-Host "This device is compliant but with manual override(s) set."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") This device is compliant but with manual override(s) set."
} elseif ($override -eq $true) {
  Write-Host "The override option was set. Configuring all settings."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The override option was set. Configuring all settings."
} else {
  Write-Host "The following settings will be configured: $auditInput"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The following settings will be configured: $auditInput"
}

# Convert the results to an array
$auditInput = $auditInput -split ", "

# Convert the script variables to local variables
$override = $env:overrideAuditResults
$verbose = $env:verbose

# Create custom objects for each auditing input
$logFiles = [PSCustomObject]@{
    Name = "Log Files"
    Value = 0
}
$firewall = [PSCustomObject]@{
    Name = "Windows Firewall(s)"
    Value = 0
}
$timeZone = [PSCustomObject]@{
    Name = "Time Zone"
    Value = 0
}
$services = [PSCustomObject]@{
    Name = "Services"
    Value = 0
}
$isoMounting = [PSCustomObject]@{
    Name = "ISO Mounting"
    Value = 0
}
$usb = [PSCustomObject]@{
    Name = "USB Controller"
    Value = 0
}
$autoRun = [PSCustomObject]@{
    Name = "Auto Run"
    Value = 0
}

# An array of all the above custom objects.
$auditingArray = @($logFiles, $firewall, $timeZone, $services, $isoMounting, $usb, $autoRun)

# Goes through the input array and if the value matches the name in the custom objects above, it will set the value to 1.
foreach ($input in $auditInput) {
  foreach ($setting in $auditingArray) {
    if ($setting.Name -eq $input) {
      $setting.Value = 1
    }
  }
}

if ($logFiles.Value -eq 1 -or $override -eq $true) {
  # Checks to see if the Scripts.log file exists and creates it if it doesn't
  if(!(Test-Path 'C:\DDS\Logs\Scripts.log')) {
    try {
      New-Item -ItemType File -Path "C:\DDS\Logs\Scripts.log" -Force
      
      if ($verbose -eq $true) { Write-Host "Added Scripts.log to the directory C:\DDS\Logs" }
    } catch {
      Write-Host "Unable to add Scripts.log to the directory C:\DDS\Logs"
    }
  }
  
  # Checks to see if the Maintenance.log file exists and creates it if it doesn't
  if(!(Test-Path 'C:\DDS\Logs\Maintenance.log')) {
    try {
      New-Item -ItemType File -Path "C:\DDS\Logs\Maintenance.log" -Force
      
      if ($verbose -eq $true) { Write-Host "Added Maintenance.log to the directory C:\DDS\Logs" }
    } catch {
      Write-Host "Unable to add Maintenance.log to the directory C:\DDS\Logs"
    }
  }
  
  # Checks to see if the Staging.log file exists and creates it if it doesn't
  if(!(Test-Path 'C:\DDS\Logs\Staging.log')) {
    try {
      New-Item -ItemType File -Path "C:\DDS\Logs\Staging.log" -Force
      
      if ($verbose -eq $true) { Write-Host "Added Staging.log to the directory C:\DDS\Logs" }
    } catch {
      Write-Host "Unable to add Staging.log to the directory C:\DDS\Logs"
    }
  }
  
  # Checks to see if the Audit.log file exists and creates it if it doesn't
  if(!(Test-Path 'C:\DDS\Logs\Audit.log')) {
    try {
      New-Item -ItemType File -Path "C:\DDS\Logs\Audit.log" -Force
      
      if ($verbose -eq $true) { Write-Host "Added Audit.log to the directory C:\DDS\Logs" }
    } catch {
      Write-Host "Unable to add Audit.log to the directory C:\DDS\Logs"
    }
  }
  
  # Checks to see if the Scheduled Automation.log file exists and creates it if it doesn't
  if(!(Test-Path "C:\DDS\Logs\Scheduled Automation.log")) {
    try {
      New-Item -ItemType File -Path "C:\DDS\Logs\Scheduled Automation.log" -Force
      
      if ($verbose -eq $true) { Write-Host "Added Scheduled Automation.log to the directory C:\DDS\Logs" }
    } catch {
      Write-Host "Unable to add Scheduled Automation.log to the directory C:\DDS\Logs"
    }
  }
  
  # Checks to see if the Defender.log file exists and creates it if it doesn't
  if(!(Test-Path 'C:\DDS\Logs\Defender.log')) {
    try {
      New-Item -ItemType File -Path "C:\DDS\Logs\Defender.log" -Force
      
      if ($verbose -eq $true) { Write-Host "Added Defender.log to the directory C:\DDS\Logs" }
    } catch {
      Write-Host "Unable to add Defender.log to the directory C:\DDS\Logs"
    }
  }
}

if ($firewall.Value -eq 1 -or $override -eq $true) {
  # Get the values of the 'Enabled' property for all three firewalls listed in the Get-NetFirewallProfile cmdlet.
  $firewallProfiles = Get-NetFirewallProfile | Select-Object -ExpandProperty Enabled
  
  # Check to see what the current state of the firewall is
  if ($firewallProfiles) {
    Write-Host "Disabling Windows Firewall..."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Windows Firewall..."
    
    # Firewall is already configured properly
    if ($firewallProfiles[0] -eq "False" -and $firewallProfiles[1] -eq "False" -and $firewallProfiles[2] -eq "False") {
      Write-Host "Windows Firewall is already disabled."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Windows Firewall is already disabled."
    }
    # Firewall is not configured properly. Try to disable it.
    else {
      # Turn off the Domain, Public, and Private firewalls
      try {
        NetSh Advfirewall set allprofiles state off
      } catch {
        Write-Host "Failed to disable Windows Firewall: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable Windows Firewall: $_"
      }
    }
  }
  else {
    Write-Host "An error occurred while finding the state of Windows Firewall."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while finding the state of Windows Firewall."
  }
}

if ($timeZone.Value -eq 1 -or $override -eq $true) {
  # Gets the currently set time zone
  $timeZone = (Get-TimeZone).id
  
  Write-Host "Setting the time zone..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Setting the time zone..."
  
  # Time zone should be set to EST
  if ($timeZone -ne "Eastern Standard Time") {
    # Sets timezone to EST
    try {
     Set-TimeZone -Id 'Eastern Standard Time'
     w32tm /resync /force
    } catch {
      Write-Host "Failed to set timezone to EST. Current time zone is $($timeZone)"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set timezone to EST. Current time zone is $($timeZone)"
    }
  }
  else {
    if ($verbose -eq $true) { Write-Host "Time zone is already set to Eastern Standard Time." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Time zone is already set to Eastern Standard Time."
  }
}

if ($services.Value -eq 1 -or $override -eq $true) {
  # For error tracking
  $errors = 0
  
  # Pulls the services to variables for use later
  $fdrpService = Get-Service -name FDResPub
  $ssdpService = Get-Service -name SSDPSRV
  $upnpService = Get-Service -name upnphost
  
  Write-Host "Configuring the FDResPub, SSDPSRV, and upnphost services..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the FDResPub, SSDPSRV, and upnphost services..."
  
  # Checks to make sure the service gets pulled correctly
  if ($fdrpService -eq $null) {
    if ($verbose -eq $true) { Write-Host "The FDResPub service could not be found." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The FDResPub service could not be found."
    
    $errors++
  } else {
    # If the service isn't set to Automatic, set the service to Automatic
    if ($fdrpService.StartType -ne 'Automatic') {
      try {
        Set-Service -Name FDResPub -StartupType Automatic
      } catch {
        Write-Host "Unable to set the startup type of FDResPub to Automatic: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Unable to set the startup type of FDResPub to Automatic: $_"
        
        $errors++
      }
    } else {
      if ($verbose -eq $true) { Write-Host "The startup type for FDResPub is already set to Automatic." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The startup type for FDResPub is already set to Automatic."
    }
    
    # If the service isn't running, start it
    if ($fdrpService.Status -ne 'Running') {
      try {
        Start-Service -Name FDResPub
      } catch {
        Write-Host "Unable to start the FDResPub service: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Unable to start the FDResPub service: $_"
        
        $errors++
      }
    } else {
      if ($verbose -eq $true) { Write-Host "The FDResPub service is already running." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The FDResPub service is already running."
    }
  }
  
  # Checks to make sure the service gets pulled correctly
  if ($ssdpService -eq $null) {
    if ($verbose -eq $true) { Write-Host "The SSDPSRV service could not be found." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The SSDPSRV service could not be found."
    
    $errors++
  } else {
    # If the service isn't set to Automatic, set the service to Automatic
    if ($ssdpService.StartType -ne 'Automatic') {
      try {
        Set-Service -Name SSDPSRV -StartupType Automatic
      } catch {
        Write-Host "Unable to set the startup type of SSDPSRV to Automatic: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Unable to set the startup type of SSDPSRV to Automatic: $_"
        
        $errors++
      }
    } else {
      if ($verbose -eq $true) { Write-Host "The startup type for SSDPSRV is already set to Automatic." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The startup type for SSDPSRV is already set to Automatic."
    }
    
    # If the service isn't running, start it
    if ($ssdpService.Status -ne 'Running') {
      try {
        Start-Service -Name SSDPSRV
      } catch {
        Write-Host "Unable to start the SSDPSRV service: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Unable to start the SSDPSRV service: $_"
        
        $errors++
      }
    } else {
      if ($verbose -eq $true) { Write-Host "The SSDPSRV service is already running." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The SSDPSRV service is already running."
    }
  }
  
  # Checks to make sure the service gets pulled correctly
  if ($upnpService -eq $null) {
    if ($verbose -eq $true) { Write-Host "The upnphost service could not be found." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The upnphost service could not be found."
    
    $errors++
  } else {
    # If the service isn't set to Automatic, set the service to Automatic
    if ($upnpService.StartType -ne 'Automatic') {
      try {
        Set-Service -Name upnphost -StartupType Automatic
      } catch {
        Write-Host "Unable to set the startup type of upnphost to Automatic: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Unable to set the startup type of upnphost to Automatic: $_"
        
        $errors++
      }
    } else {
      if ($verbose -eq $true) { Write-Host "The startup type for upnphost is already set to Automatic." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The startup type for upnphost is already set to Automatic."
    }
    
    # If the service isn't running, start it
    if ($upnpService.Status -ne 'Running') {
      try {
        Start-Service -Name upnphost
      } catch {
        Write-Host "Unable to start the upnphost service: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Unable to start the upnphost service: $_"
        
        $errors++
      }
    } else {
      if ($verbose -eq $true) { Write-Host "The upnphost service is already running." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The upnphost service is already running."
    }
  }
  
  if ($errors -eq 0) {
    Write-Host "Successfully configured the FDResPub, SSDPSRV, and upnphost services with 0 errors."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully configured the FDResPub, SSDPSRV, and upnphost services with 0 errors."
  } else {
    Write-Host "$errors errors occurred while configuring the FDResPub, SSDPSRV, and upnphost services. Manual investigation is required."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $errors errors occurred while configuring the FDResPub, SSDPSRV, and upnphost services. Manual investigation is required."
  }
}

if ($isoMounting.Value -eq 1 -or $override -eq $true) {
  # Registry path to disable ISO mounting
  $regPath = "HKCR\Windows.IsoFile\shell\mount"
  
  # Check to see if the registry key is already set
  $programmaticAccessReg = Get-ItemProperty -Path "Registry::$regPath" -Name ProgrammaticAccessOnly -ErrorAction SilentlyContinue
  
  Write-Host "Disabling ISO Mounting..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling ISO Mounting..."
  
  # If this is true, the key already exists. Otherwise create the key.
  if ($programmaticAccessReg) {
    if ($verbose -eq $true) { Write-Host "The ProgrammaticAccessOnly registry key already exists. ISO mounting is already disabled." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The ProgrammaticAccessOnly registry key already exists. ISO mounting is already disabled."
  } 
  else {
    try {
      # This will add the registry key 'ProgrammaticAccessOnly' under the given registry path
      reg add $regPath /v ProgrammaticAccessOnly /t REG_SZ /f
    } catch {
      Write-Host "Failed to set ISO mounting to not be the default action of an ISO: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set ISO mounting to not be the default action of an ISO: $_"
    }
  }
}

if ($usb.Value -eq 1 -or $override -eq $true) { 
  # For error tracking
  $errors = 0
  
  Write-Host "Configuring power settings for all USB devices and controllers."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring power settings for all USB devices and controllers."
  
  try {
    # Dynamic power devices
    $powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI

    # Get all USB devices with dynamic power options
    $usbDevices = Get-CimInstance -ClassName Win32_PnPEntity |
        Select-Object Name, @{ Name = "Enable"; Expression = { 
            $powerMgmt | Where-Object InstanceName -Like "*$($_.PNPDeviceID)*" | Select-Object -ExpandProperty Enable }} |
                Where-Object { $null -ne $_.Enable -and $_.Enable -eq $true } |  
                    Where-Object {$_.Name -like "*USB*" -and $_.Name -notlike "*Virtual*"}
    
    # Try to disable the power option on each USB devcie from above
    $powerMgmt | Where-Object { $_.InstanceName -Like "*$($usbDevice.PNPDeviceID)*" } | Set-CimInstance -Property @{Enable = $false}
  } catch {
    Write-Host "Failed to disable 'Allow the computer to turn off this device to save power' on all USB devices: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable 'Allow the computer to turn off this device to save power' on all USB devices: $_"
    
    $errors++
  }

  Write-Host "Finished configuring power settings for all USB devices and controllers with $errors errors."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Finished configuring power settings for all USB devices and controllers with $errors errors."
}

if ($autoRun.Value -eq 1 -or $override -eq $true) {
  Write-Host "Disabling Autorun and Autoplay on all drives..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Autorun and Autoplay on all drives..."
  
  # Get the current value of the NoDriveTypeAutorun key
  $autorunReg = Get-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer” -Name “NoDriveTypeAutorun” -ErrorAction SilentlyContinue
  # Set the value or create the NoDriveTypeAutorun key if it doesn't exist or isn't set correctly.
  if ($autorunReg -and $autorunReg.NoDriveTypeAutorun -ne 0xFF) {
    try {
      Set-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer” -Name “NoDriveTypeAutorun” -Value 0xFF -Force
    } catch {
      Write-Host "Failed to set the NoDriveTypeAutorun registry key: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the NoDriveTypeAutorun registry key: $_"
      
      exit 1
    }
  } else {
    try {
      New-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer” -Name “NoDriveTypeAutorun” -Value 0xFF -PropertyType DWORD -Force
    } catch {
      Write-Host "Failed to set the NoDriveTypeAutorun registry key: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the NoDriveTypeAutorun registry key: $_"
    }
  }
}