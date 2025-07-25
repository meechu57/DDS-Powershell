# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

function Enable-PendingReboot {
    Write-Host "Setting the computer to 'Pending Reboot' state..."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Setting the computer to 'Pending Reboot' state..."

    # Registry keys and pathway
    $rebootRequiredRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    $keysToCheck = @(
        "c9f3440f-77ba-40bb-a006-1e67387c6e96",
        "dce6a540-cc87-4c55-8db6-63af55cfd9fd",
        "7270ec06-f01f-4cda-8db5-a29207141a43"
    )

    # Check if the RebootRequired key exists
    if (Test-Path $rebootRequiredRegPath) {
      # Check for the three keys above
      foreach ($key in $keysToCheck) {
        $value = Get-ItemProperty -Path $rebootRequiredRegPath -Name $key -ErrorAction SilentlyContinue
    
        # Set the key to the correct value if it doesn't exist or isn't set properly
        if ($value -ne 1 -or $value -eq $null) {
          try {
            Set-ItemProperty -Path $rebootRequiredRegPath -Name $key -Value 1
          } catch {
            Write-Host "An error occurred when setting the value of the registry key $key `n $_"
            Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when setting the value of the registry key $key `n $_"

            exit 1
          }
        }
      }
    } # Create the RebootRequired key and subkeys if it doesn't exist 
    else {
      # Create the RebootRequired key
      try {
        New-Item -Path $rebootRequiredRegPath -Force
      } catch {
        Write-Host "An error occurred when trying to create the RebootRequired key: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to create the RebootRequired key: $_"

        exit 1
      }
  
      # Create the subkeys
      foreach ($key in $keysToCheck) {
        try {
          New-ItemProperty -Path $rebootRequiredRegPath -Name $key -PropertyType DWord -Value 1 -Force
        } catch {
          Write-Host "An error occurred when setting the value of the registry key $key `n $_"
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when setting the value of the registry key $key `n $_"

          exit 1
        }
      }
    }
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
$modernStandby = [PSCustomObject]@{
    Name = "Modern Standby"
    Value = 0
}
$uac = [PSCustomObject]@{
    Name = "UAC"
    Value = 0
}
$powerOptions = [PSCustomObject]@{
    Name = "Power Options"
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
$fastBoot = [PSCustomObject]@{
    Name = "Fast Boot"
    Value = 0
}
$isoMounting = [PSCustomObject]@{
    Name = "ISO Mounting"
    Value = 0
}
$nic = [PSCustomObject]@{
    Name = "Network Adapter"
    Value = 0
}
$usb = [PSCustomObject]@{
    Name = "USB Controller"
    Value = 0
}
$adobe = [PSCustomObject]@{
    Name = "Adobe"
    Value = 0
}
$ucpd = [PSCustomObject]@{
    Name = "UCPD"
    Value = 0
}
$autoRun = [PSCustomObject]@{
    Name = "Auto Run"
    Value = 0
}

# An array of all the above custom objects.
$auditingArray = @($logFiles, $modernStandby, $uac, $powerOptions,  $firewall, $timeZone, $services, $fastBoot, $isoMounting, $nic, $usb, $adobe, $ucpd, $autoRun)

# Goes through the input array and if the value matches the name in the custom objects above, it will set the value to 1.
foreach ($input in $auditInput) {
  foreach ($setting in $auditingArray) {
    if ($setting.Name -eq $input) {
      $setting.Value = 1
    }
  }
}

# Check for a non-battery backup battery. If one is detected, the device is a laptop.
$isLaptop = 0
$battery = Get-CimInstance Win32_Battery

if ($battery -and $battery.name -notlike "*UPS*") {
  if ($verbose -eq $true) { Write-Host "Laptop detected." }
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Laptop detected."
  
  $isLaptop = 1
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

if ($modernStandby.Value -eq 1 -and !$isLaptop) {
  # The registry path where PlatformAoAcOverride exists
  $regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Power"
  
  # Gets the value of the PlatformAoAcOverride registry key
  $overridgeRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name PlatformAoAcOverride -ErrorAction SilentlyContinue
    
  # If PlatformAoAcOverride doesn't exist, it should be $null
  Write-Host "Disabling Modern Standby..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Modern Standby..."
  
  # Adds the PlatformAoAcOverride registry key to disable UAC
  if ($overridgeRegKey -eq $null) {
    try {
      reg add $regPath /v PlatformAoAcOverride /t REG_DWORD /d 0 /f
      } catch {
      Write-Host "Failed to add the PlatformAoAcOverride Registry key: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the PlatformAoAcOverride Registry key: $_"
    }
  } else {
    # if PlatformAoAcOverride does exist and isn't 0 for some reason, this should force the value back to 0
    if ($overridgeRegKey.PlatformAoAcOverride -ne 0) {
      try {
        reg add $regPath /v PlatformAoAcOverride /t REG_DWORD /d 0 /f
        
        if ($verbose -eq $true) { Write-Host "The PlatformAoAcOverride Registry key already existed but was incorrectly set. The value is now 0." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The PlatformAoAcOverride Registry key already existed but was incorrectly set. The value is now 0."
      } catch {
        Write-Host "Failed to add the PlatformAoAcOverride Registry key: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the PlatformAoAcOverride Registry key: $_"
      }
    }
    else {
      if ($verbose -eq $true) { Write-Host "Modern Standby is already disabled." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Modern Standby is already disabled."
    }
  }
  
  # Put the device in a pending reboot state.
  Enable-PendingReboot
}

if ($uac.Value -eq 1 -or $override -eq $true) {
  # The registry path where EnableLUA exists
  $regPath = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
  
  # Gets the value of the EnableLUA registry key
  $uacRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name EnableLUA -ErrorAction SilentlyContinue
  
  Write-Host "Disabling UAC..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling UAC..."
  
  # If the EnableLUA registry key doesn't exist or isn't set to 0, try to add the registry key and set the value to 0.
  if ($uacRegKey -eq $null -or $uacRegKey.EnableLUA -ne 0) {
    try {
      reg add $regPath /v EnableLUA /t REG_DWORD /d 0 /f
    } catch {
      Write-Host "Failed to add the EnableLUA Registry key and disable UAC."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the EnableLUA Registry key and disable UAC."
    }
  } else {
    if ($verbose -eq $true) { Write-Host "UAC is already disabled." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") UAC is already disabled."
  }
}

if ($powerOptions.Value -eq 1 -or $override -eq $true) {
  # Assigning these as variables for readability purposes
  $usbSubGUID = '2a737441-1930-4402-8d77-b2bebba308a3'
  $usbSelectiveSuspend = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'
  $hubSelectiveSuspend = '0853a681-27c8-4100-a2fd-82013e970683'
  $usbLinkPowerManagement = 'd4e98f31-5ffe-4ce1-be31-1b38b384c009'
  
  # For error tracking
  $errors = 0
  
  Write-Host "Setting power options..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Setting power options..."
    
  # Set sleep settings to "Never"
  try {
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
  } catch {
    Write-Host "Failed to set sleep settings to Never: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set sleep settings to Never: $_"
    
    $error++
  }
  
  # Set hibernate after settings to "Off"
  try {
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
  } catch {
    Write-Host "Failed to set hibernate after to off: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set hibernate after to off: $_"
    
    $error++
  }
  
  if ($isLaptop -eq 0) {
    # Disable hibernation
    try {
      powercfg -h off
    } catch {
      Write-Host "Failed to disable hibernation: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable hibernation: $_"
      
      $error++
    }
  }
  
  # Disable hybrid sleep
  try {
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 0
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 0
  } catch {
    Write-Host "Failed to disable hybrid sleep: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable hybrid sleep: $_"
    
    $error++
  }
  
  # Disable wake timer
  try {
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
  } catch {
    Write-Host "Failed to disable wake timer: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable wake timer: $_"
    
    $error++
  }
  
  # Disable USB selective suspend timeout
  try {
    powercfg /setacvalueindex SCHEME_CURRENT $usbSubGUID $usbSelectiveSuspend 0
    powercfg /setdcvalueindex SCHEME_CURRENT $usbSubGUID $usbSelectiveSuspend 0
  } catch {
    Write-Host "Failed to disable USB selective suspend timeout: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable USB selective suspend timeout: $_"
    
    $error++
  }
  
  # Disable Hub selective suspend timeout
  try {
    powercfg /setacvalueindex SCHEME_CURRENT $usbSubGUID $hubSelectiveSuspend 0
    powercfg /setdcvalueindex SCHEME_CURRENT $usbSubGUID $hubSelectiveSuspend 0
  } catch {
    Write-Host "Failed to disable USB selective suspend timeout: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable USB selective suspend timeout: $_"
    
    $error++
  }
  
  # Disable USB 3 Link Power Mangement
  try {
    powercfg /setacvalueindex SCHEME_CURRENT $usbSubGUID $usbLinkPowerManagement 0
    powercfg /setdcvalueindex SCHEME_CURRENT $usbSubGUID $usbLinkPowerManagement 0
  } catch {
    Write-Host "Failed to disable USB 3 Link Power Mangement: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable USB 3 Link Power Mangement: $_"
    
    $error++
  }
  
  # Disable Turn off hard disk after
  try {
    powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0
  } catch {
    Write-Host "Failed to disable Turn off hard disk idle: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable Turn off hard disk idle: $_"
    
    $error++
  }
  
  # Show any the number of errors that occurred (if any)
  if ($errors -ne 0) {
    Write-Host "$errors error(s) were encountered while setting power options."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $errors error(s) were encountered while setting power options."
  } else {
    Write-Host "Power Options successfully set."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Options successfully set."  
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

if ($fastBoot.Value -eq 1 -or $override -eq $true) {
  # The registry path where HiberbootEnabled exists
  $regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
  
  # Gets the value of the HiberbootEnabled registry key
  $hiberbootRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name HiberbootEnabled -ErrorAction SilentlyContinue
  
  Write-Host "Disabling Fast Boot..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Fast Boot..."
  
  # If the registry key doesn't exist, create it and set it to 0.
  if ($hiberbootRegKey -eq $null) {
    try {
      # Add the registry key and set it to 0.
      reg add $regPath /v HiberbootEnabled /t REG_DWORD /d 0 /f
    } catch {
      Write-Host "The HiberbootEnabled registry key doesn't exist. Failed to add the registry key and disable fast boot: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The HiberbootEnabled registry key doesn't exist. Failed to add the registry key and disable fast boot: $_"
    }
  } 
  else {
    # If the registry key isn't 0, set it to 0.
    if ($hiberbootRegKey.HiberbootEnabled -ne 0) {
      try {
        # Add the registry key and set it to 0.
        reg add $regPath /v HiberbootEnabled /t REG_DWORD /d 0 /f
      } catch {
        Write-Host "Failed to set the HiberbootEnabled registry key to 0 and disable fast boot: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the HiberbootEnabled registry key to 0 and disable fast boot: $_"
      }
    } 
    else {
      Write-Host "Fast boot is already disabled."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Fast boot is already disabled."
    }
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

if ($nic.Value -eq 1 -or $override -eq $true) {
  # For error tracking
  $errors = 0
  
  Write-Host "Configuring the NIC(s)..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the NIC(s)..."
  
  # Get the physical NIC(s)
  $NICs = Get-NetAdapter -Physical
  
  # Configure all NIC(s)
  foreach ($NIC in $NICs) {
    $IPv6 = (Get-NetAdapterBinding -Name $NIC.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue).Enabled # Should be false
    $WoMP = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Wake on Magic Packet" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $WoP = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Wake on pattern match" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $EEE = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Energy Efficient Ethernet" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $AdvEEE = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Advanced EEE" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $GE = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Green Ethernet" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $ULPM = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Ultra Low Power Mode" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $powerWoMP = (Get-NetAdapterPowerManagement -Name $NIC.Name -ErrorAction SilentlyContinue).WakeOnMagicPacket # Should be "Disabled"
    $powerWoP = (Get-NetAdapterPowerManagement -Name $NIC.Name -ErrorAction SilentlyContinue).WakeOnPattern # Should be "Disabled"
    $powerSaving = (Get-NetAdapterPowerManagement -Name $NIC.Name -ErrorAction SilentlyContinue).AllowComputerToTurnOffDevice # Should be "Disabled"
    
    # Configure IPv6
    if ($IPv6 -eq $null) { 
      if ($verbose -eq $true) { Write-Host "IPv6 is not an option on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") IPv6 is not an option on NIC $($NIC.name)."
    } elseif ($IPv6 -eq $false) {
      if ($verbose -eq $true) { Write-Host "IPv6 is already disabled on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") IPv6 is already disabled on NIC $($NIC.name)."
    } else { # Set IPv6 to disabled
      try {
        if ($verbose -eq $true) { Write-Host "Disabling IPv6 on NIC $($NIC.name)..." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling IPv6 on NIC $($NIC.name)..."
        
        Set-NetAdapterBinding -Name $NIC.Name -ComponentID ms_tcpip6 -Enabled $false
      } catch {
        Write-Host "An error occurred while configuring IPv6 on NIC $($NIC.name): $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring IPv6 on NIC $($NIC.name): $_"
        
        $errors++
      }
    }
    
    # Configure Wake on Magic Packet
    if ($WoMP -eq $null) { 
      if ($verbose -eq $true) { Write-Host "Wake on Magic Packet is not an option on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is not an option on NIC $($NIC.name)."
    } elseif ($WoMP -eq 0) {
      if ($verbose -eq $true) { Write-Host "Wake on Magic Packet is already disabled on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is already disabled on NIC $($NIC.name)."
    } else { # Set Wake on Magic Packet to disabled
      try {
        if ($verbose -eq $true) { Write-Host "Disabling Wake on Magic Packet on NIC $($NIC.name)..." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Wake on Magic Packet on NIC $($NIC.name)..."
        
        Set-NetAdapterAdvancedProperty -Name $NIC.name -DisplayName "Wake on Magic Packet" -RegistryValue 0
      } catch {
        Write-Host "An error occurred while configuring Wake on Magic Packet on NIC $($NIC.name): $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring Wake on Magic Packet on NIC $($NIC.name): $_"
        
        $errors++
      }
    }
    
    # Configure Wake on Pattern
    if ($WoP -eq $null) { 
      if ($verbose -eq $true) { Write-Host "Wake on Pattern is not an option on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern is not an option on NIC $($NIC.name)."
    } elseif ($WoP -eq 0) {
      if ($verbose -eq $true) { Write-Host "Wake on Pattern is already disabled on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern is already disabled on NIC $($NIC.name)."
    } else { # Set Wake on Pattern to disabled
      try {
        if ($verbose -eq $true) { Write-Host "Disabling Wake on Pattern on NIC $($NIC.name)..." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Wake on Pattern on NIC $($NIC.name)..."
        
        Set-NetAdapterAdvancedProperty -Name $NIC.name -DisplayName "Wake on pattern match" -RegistryValue 0
      } catch {
        Write-Host "An error occurred while configuring Wake on Pattern on NIC $($NIC.name): $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring Wake on Pattern on NIC $($NIC.name): $_"
        
        $errors++
      }
    }
    
    # Configure Energy Efficient Ethernet
    if ($EEE -eq $null) { 
      if ($verbose -eq $true) { Write-Host "EEE is not an option on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") EEE is not an option on NIC $($NIC.name)."
    } elseif ($EEE -eq 0) {
      if ($verbose -eq $true) { Write-Host "EEE is already disabled on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") EEE is already disabled on NIC $($NIC.name)."
    } else { # Set Energy Efficient Ethernet to disabled
      try {
        if ($verbose -eq $true) { Write-Host "Disabling Energy Efficient Ethernet on NIC $($NIC.name)..." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Energy Efficient Ethernet on NIC $($NIC.name)..."
        
        Set-NetAdapterAdvancedProperty -Name $NIC.name -DisplayName "Energy Efficient Ethernet" -RegistryValue 0
      } catch {
        Write-Host "An error occurred while configuring Energy Efficient Ethernet on NIC $($NIC.name): $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring Energy Efficient Ethernet on NIC $($NIC.name): $_"
        
        $errors++
      }
    }
    
    # Configure Advanced EEE
    if ($AdvEEE -eq $null) { 
      if ($verbose -eq $true) { Write-Host "Advanced EEE is not an option on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Advanced EEE is not an option on NIC $($NIC.name)."
    } elseif ($AdvEEE -eq 0) {
      if ($verbose -eq $true) { Write-Host "Advanced EEE is already disabled on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Advanced EEE is already disabled on NIC $($NIC.name)."
    } else { # Set Advanced EEE to disabled
      try {
        if ($verbose -eq $true) { Write-Host "Disabling Advanced EEE on NIC $($NIC.name)..." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Advanced EEE on NIC $($NIC.name)..."
        
        Set-NetAdapterAdvancedProperty -Name $NIC.name -DisplayName "Advanced EEE" -RegistryValue 0
      } catch {
        Write-Host "An error occurred while configuring Advanced EEE on NIC $($NIC.name): $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring Advanced EEE on NIC $($NIC.name): $_"
        
        $errors++
      }
    }
    
    # Configure Green Ethernet
    if ($GE -eq $null) { 
      if ($verbose -eq $true) { Write-Host "Green Ethernet is not an option on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Green Ethernet is not an option on NIC $($NIC.name)."
    } elseif ($GE -eq 0) {
      if ($verbose -eq $true) { Write-Host "Green Ethernet is already disabled on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Green Ethernet is already disabled on NIC $($NIC.name)."
    } else { # Set Green Ethernet to disabled
      try {
        if ($verbose -eq $true) { Write-Host "Disabling Green Ethernet on NIC $($NIC.name)..." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Green Ethernet on NIC $($NIC.name)..."
        
        Set-NetAdapterAdvancedProperty -Name $NIC.name -DisplayName "Green Ethernet" -RegistryValue 0
      } catch {
        Write-Host "An error occurred while configuring Green Ethernet on NIC $($NIC.name): $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring Green Ethernet on NIC $($NIC.name): $_"
        
        $errors++
      }
    }
    
    # Configure Ultra Low Power Mode
    if ($ULPM -eq $null) { 
      if ($verbose -eq $true) { Write-Host "Ultra Low Power Mode is not an option on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ultra Low Power Mode is not an option on NIC $($NIC.name)."
    } elseif ($ULPM -eq 0) {
      if ($verbose -eq $true) { Write-Host "Ultra Low Power Mode is already disabled on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ultra Low Power Mode is already disabled on NIC $($NIC.name)."
    } else { # Set Ultra Low Power Mode to disabled
      try {
        if ($verbose -eq $true) { Write-Host "Disabling Ultra Low Power Mode on NIC $($NIC.name)..." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Ultra Low Power Mode on NIC $($NIC.name)..."
        
        Set-NetAdapterAdvancedProperty -Name $NIC.name -DisplayName "Ultra Low Power Mode" -RegistryValue 0
      } catch {
        Write-Host "An error occurred while configuring Ultra Low Power Mode on NIC $($NIC.name): $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring Ultra Low Power Mode on NIC $($NIC.name): $_"
        
        $errors++
      }
    }
    
    # Configure Power Management
    if ($powerWoMP -eq "Disabled") {
      if ($verbose -eq $true) { Write-Host "Wake on Magic Packet is already disabled on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is already disabled on NIC $($NIC.name)."
    } else {
      try {
        if ($verbose -eq $true) { Write-Host "Disabling Wake on Magic Packet on NIC $($NIC.name)..." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Wake on Magic Packet on NIC $($NIC.name)..."
        
        $NIC |? {
          $_.AllowComputerToTurnOffDevice = 'Disabled'
          $_.DeviceSleepOnDisconnect = 'Disabled'
        }
        $NIC | Set-NetAdapterPowerManagement
      } catch {
        Write-Host "An error occurred while disabling Wake on Magic Packet on NIC $($NIC.name): $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while disabling Wake on Magic Packet on NIC $($NIC.name): $_"
        
        $errors++
      }
    }
    
    # Set Power Saving
    if ($powerSaving -eq "Disabled") {
      if ($verbose -eq $true) { Write-Host "Power Saving is already disabled on NIC $($NIC.name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Saving is already disabled on NIC $($NIC.name)."
    } else {
      try {
        if ($verbose -eq $true) { Write-Host "Disabling Power Saving on NIC $($NIC.name)..." }
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Power Saving on NIC $($NIC.name)..."
        
        Set-NetAdapterPowerManagement -Name $NIC.name -AllowComputerToTurnOffDevice Disabled
      } catch {
        Write-Host "An error occurred while disabling Power Saving on NIC $($NIC.name): $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while disabling Power Saving on NIC $($NIC.name): $_"
        
        $errors++
      }
    }
    
    # Increment the error count if necessary
    if ($errors -gt 0) {
      Write-Host "There were errors configuring the NIC $($NIC.name)."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") There were errors configuring the NIC $($NIC.name)."
    } else {
      Write-Host "The NIC $($NIC.name) was successfully configured."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The NIC $($NIC.name) was successfully configured."
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

if ($adobe.Value -eq 1 -or $override -eq $true) {
  # Path where the Adobe .exe file exists
  $32BitExePath = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
  $64BitExePath = "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
  
  # Registry path where the RUNASADMIN data is set
  $regPath = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
  
  # Pulls the registry keys to see if it was created previously
  $32BitAdminRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name $32BitExePath -ErrorAction SilentlyContinue
  $64BitAdminRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name $64BitExePath -ErrorAction SilentlyContinue
  
  Write-Host "Configuring Adobe to run as admin..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring Adobe to run as admin..."
  
  # Verify that Adobe is actually installed before proceeding.
  # Check for the 32-bit version of Adobe.
  if (Test-Path $32BitExePath) { 
    # If the registry key doesn't exist, create it.
    if ($32BitAdminRegKey -eq $null -or $32BitAdminRegKey.$32BitExePath -ne "RUNASADMIN") {
      try {
       reg add $regPath /v $32BitExePath /t REG_SZ /d "RUNASADMIN" /f 
      } catch {
        Write-Host "Failed to add the RUNASADMIN registry key: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the RUNASADMIN registry key: $_"
      }
      
      # Pull the registry key again
      $32BitAdminRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name $32BitExePath -ErrorAction SilentlyContinue
      
      # Verify that the registry key was added properly
      if ($32BitAdminRegKey.$32BitExePath -eq "RUNASADMIN") {
        Write-Host "Successfully enabled Adobe to run as administrator for all users."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully enabled Adobe to run as administrator for all users."
      } else {
        Write-Host "Failed to enable Adobe to run as administrator for all users."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to enable Adobe to run as administrator for all users."
      }
    }
    else {
      Write-Host "Adobe is already configured to run as admin."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe is already configured to run as admin."
    }
  } # Check for the 64-bit version of Adobe.
  elseif(Test-Path $64BitExePath) {
      # If the registry key doesn't exist, create it.
    if ($64BitAdminRegKey -eq $null -or $64BitAdminRegKey.$64BitExePath -ne "RUNASADMIN") {
      try {
       reg add $regPath /v $64BitExePath /t REG_SZ /d "RUNASADMIN" /f 
      } catch {
        Write-Host "Failed to add the RUNASADMIN registry key: $_"
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the RUNASADMIN registry key: $_"
      }
  
      # Pull the registry key again
      $64BitAdminRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name $64BitExePath -ErrorAction SilentlyContinue
  
      # Verify that the registry key was added properly
      if ($64BitAdminRegKey.$64BitExePath -eq "RUNASADMIN") {
        Write-Host "Successfully enabled Adobe to run as administrator for all users."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully enabled Adobe to run as administrator for all users."
      } else {
        Write-Host "Failed to enable Adobe to run as administrator for all users."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to enable Adobe to run as administrator for all users."
      }
    }
    else {
      Write-Host "Adobe is already configured to run as admin."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe is already configured to run as admin."
    }
  }
  else {
    Write-Host "Adobe is not installed or is not installed under the usual file path."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe is not installed or is not installed under the usual file path."
  }
}

if ($ucpd.Value -eq 1 -or $override -eq $true) {
  Write-Host "Disabling the User Choice Protection Driver..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling the User Choice Protection Driver..."

  # Get the current state of the registry key
  $UCPDRegistry = Get-ItemProperty -Path �HKLM:\SYSTEM\CurrentControlSet\Services\UCPD� -Name �Start� -ErrorAction SilentlyContinue

  # Set the registry key if it exists. If the key doesn't exist, we shouldn't have to worry about it.
  if ($UCPDRegistry -and $UCPDRegistry.Start -ne 4) {
    try {
	    New-ItemProperty -Path �HKLM:\SYSTEM\CurrentControlSet\Services\UCPD� -Name �Start� -Value 4 -PropertyType DWORD -Force
    } catch {
	    Write-Host "Failed to set the UCPD Start registry key: $_"
	    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the UCPD Start registry key: $_"
    }
  } elseif (-not $UCPDRegistry) {
    if ($verbose -eq $true) { Write-Host "The UCPD driver doesn't exist." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver doesn't exist."
  }

  # Get the current state of the scheduled task.
  $UCPDTask = Get-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "UCPD velocity" -ErrorAction SilentlyContinue

  # Disable the scheduled task if it exists.
  if ($UCPDTask -and $UCPDTask.State -ne "Disabled" ) {
    try {
	    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "UCPD velocity" -ErrorAction Continue
    } catch {
	    Write-Host "Failed to disable the UCPD velocity scheduled task: $_"
	    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to disable the UCPD velocity scheduled task: $_"
    } 
  } elseif (-not $UCPDTask) {
    if ($verbose -eq $true) { Write-Host "The UCPD driver scheduled task doesn't exist." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver scheduled task doesn't exist."
  }

  Enable-PendingReboot
}

if ($autoRun.Value -eq 1 -or $override -eq $true) {
  Write-Host "Disabling Autorun and Autoplay on all drives..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Autorun and Autoplay on all drives..."
  
  # Get the current value of the NoDriveTypeAutorun key
  $autorunReg = Get-ItemProperty -Path �HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer� -Name �NoDriveTypeAutorun� -ErrorAction SilentlyContinue
  # Set the value or create the NoDriveTypeAutorun key if it doesn't exist or isn't set correctly.
  if ($autorunReg -and $autorunReg.NoDriveTypeAutorun -ne 0xFF) {
    try {
      Set-ItemProperty -Path �HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer� -Name �NoDriveTypeAutorun� -Value 0xFF -Force
    } catch {
      Write-Host "Failed to set the NoDriveTypeAutorun registry key: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the NoDriveTypeAutorun registry key: $_"
      
      exit 1
    }
  } else {
    try {
      New-ItemProperty -Path �HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer� -Name �NoDriveTypeAutorun� -Value 0xFF -PropertyType DWORD -Force
    } catch {
      Write-Host "Failed to set the NoDriveTypeAutorun registry key: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the NoDriveTypeAutorun registry key: $_"
    }
  }
}