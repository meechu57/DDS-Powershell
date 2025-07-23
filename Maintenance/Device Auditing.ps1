# The log path for this script.
$logPath = "C:\DDS\Logs\Audit.log"

# Convert the script variable to a local variable.
$verbose = $env:verbose

# The end result array.
$results = @()

Write-Host "Running the weekly auditing..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Running the weekly auditing..."

# Check for a non-battery backup battery. If one is detected, the device is a laptop.
$isLaptop = 0
$battery = Get-CimInstance Win32_Battery

if ($battery -and $battery.name -notlike "*UPS*") {
  Write-Host "Laptop detected..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Laptop detected..."
  
  $isLaptop = 1
}

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

function Audit-ModernStandby {
  # The registry path where PlatformAoAcOverride exists
  $regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Power"
  
  # Gets the value of the PlatformAoAcOverride registry key
  $overridgeRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name PlatformAoAcOverride -ErrorAction SilentlyContinue
  
  Write-Host "Auditing Modern Standby..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Modern Standby..."
  
  # If the registry key doesn't exist, it'll be null.
  if ($overridgeRegKey -eq $null -and $isLaptop -eq 0) {
    Write-Host "Modern Standby is not disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Modern Standby is not disabled."
    
    return $false
  } # If the registry key does exist isn't 0, Modern Standby isn't disabled.
  else { 
    if ($overridgeRegKey.PlatformAoAcOverride -eq 0) {
      Write-Host "Modern Standby is disabled."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Modern Standby is disabled."
      
      return $true
    } 
    else {
      if ($isLaptop) {
        Write-Host "Laptop detected. Modern Standby is enabled and set correctly."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Laptop detected. Modern Standby is enabled and set correctly."
        
        return $true
      } else {
        Write-Host "Modern Standby is not disabled."
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Modern Standby is not disabled."
        
        return $false
      }
    }
  }
}

function Audit-UAC {
  # The registry path where EnableLUA exists
  $regPath = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
  
  # Gets the value of the EnableLUA registry key
  $uacRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name EnableLUA -ErrorAction SilentlyContinue
  
  Write-Host "Auditing UAC..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing UAC..."
  
  # If UAC is properly disabled, the EnableLUA registry key will be set to 0.
  if ($uacRegKey -eq $null -or $uacRegKey.EnableLUA -ne 0) {
    Write-Host "UAC is not disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") UAC is not disabled."
    
    return $false
  } 
  else {
    Write-Host "UAC is disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") UAC is disabled."
    
    return $true
  }
}

function Audit-PowerOptions {
  # Assigning these as variables for readability purposes
  $usbSubGUID = '2a737441-1930-4402-8d77-b2bebba308a3'
  $usbSelectiveSuspend = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'
  $hubSelectiveSuspend = '0853a681-27c8-4100-a2fd-82013e970683'
  $usbLinkPowerManagement = 'd4e98f31-5ffe-4ce1-be31-1b38b384c009'
  
  # Power options to verify
  $subSleep = @('STANDBYIDLE', 'HYBRIDSLEEP', 'HIBERNATEIDLE', 'RTCWAKE')
  $usb = @($usbSelectiveSuspend, $hubSelectiveSuspend, $usbLinkPowerManagement)
  $subSleepVerification = $null
  $usbVerification = $null
  $diskVerification = $null
  $hibernateVerification = $null
  
  # Start of verification in the log
  Write-Host "Auditing Power Options..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Power Options..." 
  
  # Verify the results of the SUB_SLEEP GUID
  foreach ($i in $subSleep) {
    $index = powercfg /qh SCHEME_CURRENT SUB_SLEEP $i | Select-String -Pattern "Power Setting Index: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
    if ($index[0] -ne '0x00000000' -or $index[1] -ne '0x00000000') {
      if ($verbose -eq $true) { Write-Host "WARNING! The $i power setting was not set correctly. Manual investigation required." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! The $i power setting was not set correctly. Manual investigation required."
      
      $subSleepVerification = $false
      break
    } else {
     $subSleepVerification = $true
   }
  }
  
  $usbErrors = 0
  # Verify the results of the USB GUID
  foreach ($i in $usb) {
   $index = powercfg /qh SCHEME_CURRENT $usbSubGUID $i | Select-String -Pattern "Power Setting Index: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
   if ($index[0] -ne '0x00000000' -or $index[1] -ne '0x00000000') {
      if ($verbose -eq $true) { Write-Host "WARNING! One of the USB setting was not set correctly. Manual investigation required." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! One of the USB setting was not set correctly. Manual investigation required."
     
      $usbErrors++
   }
  }
  if ($usbErrors -eq 0) {
    $usbVerification = $true
  } else {
    $usbVerification = $false
  }
  
  # Verify the results of VIDEOIDLE
  $index = powercfg /qh SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | Select-String -Pattern "Power Setting Index: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
  if ($index[0] -ne '0x00001518' -or $index[1] -ne '0x00001518') {
    if ($verbose -eq $true) { Write-Host "WARNING! The VIDEOIDLE power setting was not set to 90 minutes. You may want to change this!" }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! The VIDEOIDLE power setting was not set to 90 minutes. You may want to change this!"
  }
  
  # Verify the results of DISKIDLE
  $index = powercfg /qh SCHEME_CURRENT SUB_DISK DISKIDLE | Select-String -Pattern "Power Setting Index: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
  if ($index[0] -ne '0x00000000' -or $index[1] -ne '0x00000000') {
    if ($verbose -eq $true) { Write-Host "WARNING! The DISKIDLE power setting was not set correctly. Manual investigation required." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! The DISKIDLE power setting was not set correctly. Manual investigation required."
    
    $diskVerification = $false
  } else {
    $diskVerification = $true
  }
  
  # Verify the results of Hibernation
  $regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Power"
  $hibernateRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name HibernateEnabled -ErrorAction SilentlyContinue
  if ($hibernateRegKey.HibernateEnabled -ne 0 -and $isLaptop -eq 0) {
    if ($verbose -eq $true) { Write-Host "WARNING! Hibernation is not disabled. Manual investigation required." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! Hibernation is not disabled. Manual investigation required."
    
    $hibernateVerification = $false
  } else {
    $hibernateVerification = $true
  }
  
  # Verify the overall results
  if ($subSleepVerification -eq $true -and $usbVerification -eq $true -and $diskVerification -eq $true -and $hibernateVerification -eq $true) {
    Write-Host "All power options are successfully set."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All power options are successfully set." 
    
    return $true
  } else {
    Write-Host "One or more power setting was not set properly. Manual investigation required."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") One or more power setting was not set properly. Manual investigation required."
    
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

function Audit-FastBoot {
  # The registry path where HiberbootEnabled exists
  $regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
  
  # Gets the value of the HiberbootEnabled registry key
  $hiberbootRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name HiberbootEnabled -ErrorAction SilentlyContinue
  
  Write-Host "Auditing Fast Boot..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Fast Boot..."
  
  if ($hiberbootRegKey -eq $null) {
    Write-Host "Fast boot is not disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Fast boot is not disabled."
    
    return $false
  }
  elseif ($hiberbootRegKey.HiberbootEnabled -eq 0) {
    Write-Host "Fast Boot is disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Fast Boot is disabled."
    
    return $true
  }
  else {
    Write-Host "Fast boot is not disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Fast boot is not disabled."
    
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
  # Get the physical NIC(s). Ignore wireless NICs.
  $NICs = Get-NetAdapter -Physical | Where-Object {$_.Name -notmatch "Wi-Fi|Wireless"}

  # For error tracking. Should only be incremented if any of the below variables are Null.
  $errors = 0

  Write-Host "Auditing the configuration of the NIC(s)..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the configuration of the NIC(s)..."

  # Configure all NIC(s)
  foreach ($NIC in $NICs) {
    $IPv6 = (Get-NetAdapterBinding -Name $NIC.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue).Enabled # Should be false
    $WoMP = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Wake on Magic Packet" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $WoP = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Wake on pattern match" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $EEE = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Energy Efficient Ethernet" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $AdvEEE = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Advanced EEE" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $GE = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Green Ethernet" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $ULPM = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Ultra Low Power Mode" -ErrorAction SilentlyContinue).RegistryValue # Should be 0
    $speed = (Get-NetAdapterAdvancedProperty -Name $NIC.Name -DisplayName "Speed & Duplex").RegistryValue # Should be 0
    $powerWoMP = (Get-NetAdapterPowerManagement -Name $NIC.Name -ErrorAction SilentlyContinue).WakeOnMagicPacket # Should be "Disabled"
    $powerWoP = (Get-NetAdapterPowerManagement -Name $NIC.Name -ErrorAction SilentlyContinue).WakeOnPattern # Should be "Disabled"
    $powerSaving = (Get-NetAdapterPowerManagement -Name $NIC.Name -ErrorAction SilentlyContinue).AllowComputerToTurnOffDevice # Should be "Disabled"
    $linkSpeed = (Get-NetAdapter -Name $NIC.Name).LinkSpeed # Should be '1 Gbps'
    
    # Should be false for IPv6 to be disabled on the NIC
    if($IPv6 -eq $false) {
      if ($verbose -eq $true) { Write-Host "IPv6 is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") IPv6 is correctly configured on NIC: $($NIC.Name)."
    } elseif ($IPv6 -eq $null -or $IPv6 -eq "Unsupported") {
      if ($verbose -eq $true) { Write-Host "IPv6 is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") IPv6 is not an option on NIC: $($NIC.Name)."
    } elseif ($IPv6 -ne $false) {
      if ($verbose -eq $true) { Write-Host "IPv6 is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") IPv6 is not disabled on NIC: $($NIC.Name)."
      $errors++
    }
    
    # Should be set to 0 for Wake on Magic Packet to be disabled on the NIC.
    if ($WoMP -eq 0) {
      if ($verbose -eq $true) { Write-Host "Wake on Magic Packet is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is correctly configured on NIC: $($NIC.Name)."
    } elseif ($WoMP -eq $null -or $WoMP -eq "Unsupported") {
      if ($verbose -eq $true) { Write-Host "Wake on Magic Packet is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is not an option on NIC: $($NIC.Name)."
    } elseif ($WoMP -ne 0) {
      if ($verbose -eq $true) { Write-Host "Wake on Magic Packet is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is not disabled on NIC: $($NIC.Name)."
      $errors++
    }
    
    # Should be set to 0 for Wake on Pattern Match to be disabled on the NIC.
    if ($WoP -eq 0) {
      if ($verbose -eq $true) { Write-Host "Wake on Pattern Match is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern Match is correctly configured on NIC: $($NIC.Name)."
    } elseif ($WoP -eq $null -or $WoP -eq "Unsupported") {
      if ($verbose -eq $true) { Write-Host "Wake on Pattern Match is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern Match is not an option on NIC: $($NIC.Name)."
    } elseif ($WoP -ne 0) {
      if ($verbose -eq $true) { Write-Host "Wake on Pattern Match is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern Match is not disabled on NIC: $($NIC.Name)."
      $errors++
    }
    
    # Should be set to 0 for Energy Efficient Ethernet to be disabled on the NIC.
    if ($EEE -eq 0) {
      if ($verbose -eq $true) { Write-Host "Energy Efficient Ethernet is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Energy Efficient Ethernet is correctly configured on NIC: $($NIC.Name)."
    } elseif ($EEE -eq $null -or $EEE -eq "Unsupported") {
      if ($verbose -eq $true) { Write-Host "Energy Efficient Ethernet is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Energy Efficient Ethernet is not an option on NIC: $($NIC.Name)."
    } elseif ($EEE -ne 0) {
      if ($verbose -eq $true) { Write-Host "Energy Efficient Ethernet is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Energy Efficient Ethernet is not disabled on NIC: $($NIC.Name)."
      $errors++
    }
    
    # Should be set to 0 for Advanced EEE to be disabled on the NIC.
    if ($AdvEEE -eq 0) {
      if ($verbose -eq $true) { Write-Host "Advanced EEE is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Advanced EEE is correctly configured on NIC: $($NIC.Name)."
    } elseif ($AdvEEE -eq $null -or $AdvEEE -eq "Unsupported") {
      if ($verbose -eq $true) { Write-Host "Advanced EEE is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Advanced EEE is not an option on NIC: $($NIC.Name)."
    } elseif ($AdvEEE -ne 0) {
      if ($verbose -eq $true) { Write-Host "Advanced EEE is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Advanced EEE is not disabled on NIC: $($NIC.Name)."
      $errors++
    }
    
    # Should be set to 0 for Green Ethernet to be disabled on the NIC.
    if ($GE -eq 0) {
      if ($verbose -eq $true) { Write-Host "Green Ethernet is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Green Ethernet is correctly configured on NIC: $($NIC.Name)."
    } elseif ($GE -eq $null -or $GE -eq "Unsupported") {
      if ($verbose -eq $true) { Write-Host "Green Ethernet is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Green Ethernet is not an option on NIC: $($NIC.Name)."
    } elseif ($GE -ne 0) {
      if ($verbose -eq $true) { Write-Host "Green Ethernet is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Green Ethernet is not disabled on NIC: $($NIC.Name)."
      $errors++
    }
    
    # Should be set to 0 for Ultra Low Power Mode to be disabled on the NIC.
    if ($ULPM -eq 0) {
      if ($verbose -eq $true) { Write-Host "Ultra Low Power Mode is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ultra Low Power Mode is correctly configured on NIC: $($NIC.Name)."
    } elseif ($ULPM -eq $null -or $ULPM -eq "Unsupported") {
      if ($verbose -eq $true) { Write-Host "Ultra Low Power Mode is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ultra Low Power Mode is not an option on NIC: $($NIC.Name)."
    } elseif ($ULPM -ne 0) {
      if ($verbose -eq $true) { Write-Host "Ultra Low Power Mode is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ultra Low Power Mode is not disabled on NIC: $($NIC.Name)."
      $errors++
    }
    
    # Should be set to 0 for Speed & Duplex to be set to Auto Negotiation.
    if ($speed -eq 0) {
      if ($verbose -eq $true) { Write-Host "Speed & Duplex is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Speed & Duplex is correctly configured on NIC: $($NIC.Name)."
    } elseif ($speed -eq $null -or $speed -eq "Unsupported") {
      if ($verbose -eq $true) { Write-Host "Speed & Duplex is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Speed & Duplex is not an option on NIC: $($NIC.Name)."
    } elseif ($speed -ne 0) {
      if ($verbose -eq $true) { Write-Host "Speed & Duplex is not correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Speed & Duplex is not correctly configured on NIC: $($NIC.Name)."
    	
      $errors++
    }

    # Power Management settings
    if ($powerWoMP -eq "Disabled") {
      if ($verbose -eq $true) { Write-Host "Power Management Wake on Magic Packet is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Management Wake on Magic Packet is correctly configured on NIC: $($NIC.Name)."
    } elseif ($powerWoMP -eq $null) {
      if ($verbose -eq $true) { Write-Host "Power Management Wake on Magic Packet is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Management Wake on Magic Packet is not an option on NIC: $($NIC.Name)."
    } elseif ($powerWoMP -ne "Disabled") {
      if ($verbose -eq $true) { Write-Host "Power Management Wake on Magic Packet is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Management Wake on Magic Packet is not disabled on NIC: $($NIC.Name)."
      $errors++
    }

    if ($powerWoP -eq "Disabled") {
      if ($verbose -eq $true) { Write-Host "Power Management Wake on Pattern Match is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Management Wake on Pattern Match is correctly configured on NIC: $($NIC.Name)."
    } elseif ($powerWoP -eq $null) {
      if ($verbose -eq $true) { Write-Host "Power Management Wake on Pattern Match is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Management Wake on Pattern Match is not an option on NIC: $($NIC.Name)."
    } elseif ($powerWoP -ne "Disabled") {
      if ($verbose -eq $true) { Write-Host "Power Management Wake on Pattern Match is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Management Wake on Pattern Match is not disabled on NIC: $($NIC.Name)."
      $errors++
    }

    if ($powerSaving -eq "Disabled") {
      if ($verbose -eq $true) { Write-Host "Power Management Allow Computer to Turn Off Device is correctly configured on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Management Allow Computer to Turn Off Device is correctly configured on NIC: $($NIC.Name)."
    } elseif ($powerSaving -eq $null) {
      if ($verbose -eq $true) { Write-Host "Power Management Allow Computer to Turn Off Device is not an option on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Management Allow Computer to Turn Off Device is not an option on NIC: $($NIC.Name)."
    } elseif ($powerSaving -ne "Disabled") {
      if ($verbose -eq $true) { Write-Host "Power Management Allow Computer to Turn Off Device is not disabled on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Power Management Allow Computer to Turn Off Device is not disabled on NIC: $($NIC.Name)."
      $errors++
    }
    
    if ($linkSpeed -eq "1 Gbps") {
      if ($verbose -eq $true) { Write-Host "The NIC $($NIC.Name) is running at 1 Gbps." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The NIC $($NIC.Name) is running at 1 Gbps."
    } elseif ($linkSpeed -eq $null) {
      if ($verbose -eq $true) { Write-Host "Link Speed not found on NIC: $($NIC.Name)." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Link Speed not found on NIC: $($NIC.Name)."
    } elseif ($linkSpeed -ne "1 Gbps") {
      if ($verbose -eq $true) { Write-Host "The NIC $($NIC.Name) is running at 1 Gbps. It's currently running at $linkSpeed." }
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The NIC $($NIC.Name) is running at 1 Gbps. It's currently running at $linkSpeed."
      $errors++
    }
  }

  if ($errors -gt 0) {
    Write-Host "$errors errors found in the configuration of the NIC(s)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $errors errors found in the configuration of the NIC(s)."
    
    return $false
  } else {
    Write-Host "All NIC configurations are correctly audited."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All NIC configurations are correctly audited."
    
    return $true
  }
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

function Audit-Adobe {
  # Path where the Adobe .exe file exists
  $32BitExePath = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
  $64BitExePath = "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
  
  # Registry path where the RUNASADMIN data is set
  $regPath = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
  
  # Pulls the registry keys to see if it was created previously
  $32BitAdminRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name $32BitExePath -ErrorAction SilentlyContinue
  $64BitAdminRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name $64BitExePath -ErrorAction SilentlyContinue
  
  Write-Host "Auditing Adobe..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Adobe..."
  
  # Test for the 32 vs 64 bit version of Adobe.
  if (Test-Path $32BitExePath) {
    if ($verbose -eq $true) { Write-Host "32-bit Adobe was found."}
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") 32-bit Adobe was found."

    # Check the registry key to make sure it exists and is set correctly. 
    if ($32BitAdminRegKey -ne $null -and $32BitAdminRegKey.'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -eq "RUNASADMIN") {
      Write-Host "Adobe 32-bit is correctly configured to run as admin for all users."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe 32-bit is correctly configured to run as admin for all users."

      return $true
    }
    else {
      Write-Host "Adobe is not correctly configured to run as admin for all users."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe is not correctly configured to run as admin for all users."

      return $false
    }
  } 
  elseif (Test-Path $64BitExePath) {
    if ($verbose -eq $true) { Write-Host "64-bit Adobe was found." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") 64-bit Adobe was found."

    if ($64BitAdminRegKey -ne $null -and $64BitAdminRegKey.'C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe' -eq "RUNASADMIN") {
    Write-Host "Adobe 64-bit is correctly configured to run as admin for all users."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe 64-bit is correctly configured to run as admin for all users."

    return $true
    }
    else {
      Write-Host "Adobe is not correctly configured to run as admin for all users."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe is not correctly configured to run as admin for all users."

      return $false
    }
  }
  else {
    # Do a more thorough test to find an exe?
    Write-Host "Adobe could not be found in its usual install pathway. Adobe is not installed or an old version of Adobe is installed."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") 6Adobe could not be found in its usual install pathway. Adobe is not installed or an old version of Adobe is installed."

    return $false
  }
}

function Audit-UCPD {
  Write-Host "Auditing the UCPD driver..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the UCPD driver..."

  $configured = $false

  # Get the current state of the registry key
  $UCPDRegistry = Get-ItemProperty -Path “HKLM:\SYSTEM\CurrentControlSet\Services\UCPD” -Name “Start” -ErrorAction SilentlyContinue

  # Set the registry key if it exists. If the key doesn't exist, we shouldn't have to worry about it.
  if ($UCPDRegistry -and $UCPDRegistry.Start -eq 4) {
   if ($verbose -eq $true) {  Write-Host "The UCPD driver is configured correctly." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver is configured correctly."

    $configured = $true
  } elseif ($UCPDRegistry -eq $null) {
    if ($verbose -eq $true) { Write-Host "The UCPD driver doesn't exist." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver doesn't exist."

    $configured = $true
  } else {
    if ($verbose -eq $true) { Write-Host "The UCPD driver is not configured correctly." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver is not configured correctly."

    $configured = $false
  }

  # Get the current state of the scheduled task.
  $UCPDTask = Get-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "UCPD velocity" -ErrorAction SilentlyContinue

  # Disable the scheduled task if it exists.
  if ($UCPDTask -and $UCPDTask.State -eq "Disabled" ) {
    if ($verbose -eq $true) { Write-Host "The UCPD driver scheduled task is configured correctly." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver scheduled task is configured correctly."

    $configured = $true
  } elseif ($UCPDTask -eq $null) {
    if ($verbose -eq $true) { Write-Host "The UCPD driver scheduled task doesn't exist." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver scheduled task doesn't exist."

    $configured = $false
  } else {
    if ($verbose -eq $true) { Write-Host "The UCPD driver scheduled task is not configured correctly." }
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver scheduled task is not configured correctly."

    $configured = $false
  }

  if ($configured -eq $true) {
    Write-Host "The UCPD driver is configured correctly."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver is configured correctly."

    return $true
  } else {
    Write-Host "The UCPD driver is configured correctly."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The UCPD driver is configured correctly."

    return $false
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

Write-Host "Auditing local users..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing local users..."

# Gets the list of local users that are enabled and returns them as a joined string
function Get-EnabledLocalUserNames {
    $enabledUserNames = Get-LocalUser | Where-Object { $_.Enabled -eq $true } | Select-Object -ExpandProperty Name
    $userNamesString = $enabledUserNames -join ', '
    return $userNamesString
}

# Get the local users
$enabledUsersString = Get-EnabledLocalUserNames

if ($verbose -eq $true) { Write-Host "Enabled local user names: $enabledUsersString" }
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Enabled local user names: $enabledUsersString"

# Set the custom field in Ninja
Ninja-Property-Set localUsers $enabledUsersString

# Create custom objects for each function
$logFilesCreated = [PSCustomObject]@{
    Name = "Log Files"
    Value = Audit-LogFiles
}
$modernStandbyDisabled = [PSCustomObject]@{
    Name = "Modern Standby"
    Value = Audit-ModernStandby
}
$uacDisabled = [PSCustomObject]@{
    Name = "UAC"
    Value = Audit-UAC
}
$powerOptionsSet = [PSCustomObject]@{
    Name = "Power Options"
    Value = Audit-PowerOptions
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
$fastBootDisabled = [PSCustomObject]@{
    Name = "Fast Boot"
    Value = Audit-FastBoot
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
$adobeEnabledAsAdmin = [PSCustomObject]@{
    Name = "Adobe"
    Value = Audit-Adobe
}
$ucpdConfigured = [PSCustomObject]@{
    Name = "UCPD"
    Value = Audit-UCPD
}
$autoRunConfigured = [PSCustomObject]@{
    Name = "Auto Run"
    Value = Audit-AutoRun
}

# An array of all the above custom objects.
$auditingArray = @(
  $logFilesCreated, $modernStandbyDisabled, $uacDisabled, $powerOptionsSet, $windowsFirewallDisabled, $timeZoneSet, $servicesConfigured, $fastBootDisabled,
  $isoMountingDisabled, $networkAdapterConfigured, $usbControllerConfigured, $adobeEnabledAsAdmin, $ucpdConfigured, $autoRunConfigured
)

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
    
    $results = $initial | Where-Object { $_ -notin $overrideResults }
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

# Set the custom field.
Ninja-Property-Set auditResults $results