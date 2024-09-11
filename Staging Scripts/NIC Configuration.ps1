# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

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
  $powerWoMP = (Get-NetAdapterPowerManagement -Name $NIC.Name).WakeOnMagicPacket # Should be "Disabled"
  $powerWoP = (Get-NetAdapterPowerManagement -Name $NIC.Name).WakeOnPattern # Should be "Disabled"
  $powerSaving = (Get-NetAdapterPowerManagement -Name $NIC.Name).AllowComputerToTurnOffDevice # Should be "Disabled"
  
  # Configure IPv6
  if ($IPv6 -eq $null) { 
    Write-Host "IPv6 is not an option on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") IPv6 is not an option on NIC $($NIC.name)."
  } elseif ($IPv6 -eq $false) {
    Write-Host "IPv6 is already disabled on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") IPv6 is already disabled on NIC $($NIC.name)."
  } else { # Set IPv6 to disabled
    try {
      Write-Host "Disabling IPv6 on NIC $($NIC.name)..."
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
    Write-Host "Wake on Magic Packet is not an option on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is not an option on NIC $($NIC.name)."
  } elseif ($WoMP -eq 0) {
    Write-Host "Wake on Magic Packet is already disabled on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is already disabled on NIC $($NIC.name)."
  } else { # Set Wake on Magic Packet to disabled
    try {
      Write-Host "Disabling Wake on Magic Packet on NIC $($NIC.name)..."
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
    Write-Host "Wake on Pattern is not an option on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern is not an option on NIC $($NIC.name)."
  } elseif ($WoP -eq 0) {
    Write-Host "Wake on Pattern is already disabled on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern is already disabled on NIC $($NIC.name)."
  } else { # Set Wake on Pattern to disabled
    try {
      Write-Host "Disabling Wake on Pattern on NIC $($NIC.name)..."
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
    Write-Host "EEE is not an option on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") EEE is not an option on NIC $($NIC.name)."
  } elseif ($EEE -eq 0) {
    Write-Host "EEE is already disabled on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") EEE is already disabled on NIC $($NIC.name)."
  } else { # Set Energy Efficient Ethernet to disabled
    try {
      Write-Host "Disabling Energy Efficient Ethernet on NIC $($NIC.name)..."
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
    Write-Host "Advanced EEE is not an option on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Advanced EEE is not an option on NIC $($NIC.name)."
  } elseif ($AdvEEE -eq 0) {
    Write-Host "Advanced EEE is already disabled on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Advanced EEE is already disabled on NIC $($NIC.name)."
  } else { # Set Advanced EEE to disabled
    try {
      Write-Host "Disabling Advanced EEE on NIC $($NIC.name)..."
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
    Write-Host "Green Ethernet is not an option on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Green Ethernet is not an option on NIC $($NIC.name)."
  } elseif ($GE -eq 0) {
    Write-Host "Green Ethernet is already disabled on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Green Ethernet is already disabled on NIC $($NIC.name)."
  } else { # Set Green Ethernet to disabled
    try {
      Write-Host "Disabling Green Ethernet on NIC $($NIC.name)..."
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
    Write-Host "Ultra Low Power Mode is not an option on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ultra Low Power Mode is not an option on NIC $($NIC.name)."
  } elseif ($ULPM -eq 0) {
    Write-Host "Ultra Low Power Mode is already disabled on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ultra Low Power Mode is already disabled on NIC $($NIC.name)."
  } else { # Set Ultra Low Power Mode to disabled
    try {
      Write-Host "Disabling Ultra Low Power Mode on NIC $($NIC.name)..."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Ultra Low Power Mode on NIC $($NIC.name)..."
      
      Set-NetAdapterAdvancedProperty -Name $NIC.name -DisplayName "Ultra Low Power Mode" -RegistryValue 0
    } catch {
      Write-Host "An error occurred while configuring Ultra Low Power Mode on NIC $($NIC.name): $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring Ultra Low Power Mode on NIC $($NIC.name): $_"
      
      $errors++
    }
  }
  
  # Configure Wake on Magic Packet in the NIC power settings
  if ($powerWoMP -eq $null) { 
    Write-Host "Wake on Magic Packet is not an option in power settings on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is not an option in power settings on NIC $($NIC.name)."
  } elseif ($powerWoMP -eq "Disabled") {
    Write-Host "Wake on Magic Packet is already disabled in power settings on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is already disabled in power settings on NIC $($NIC.name)."
  } else { # Set Wake Wake on Magic Packet in the NIC power settings to Disabled
    try {
      Write-Host "Disabling Wake on Magic Packet in the power settings on NIC $($NIC.name)..."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Wake on Magic Packet in the power settings on NIC $($NIC.name)..."
      
      Set-NetAdapterPowerManagement -Name $NIC.name -WakeOnMagicPacket "Disabled"
      $NIC | Disable-NetAdapterPowerManagement -WakeOnMagicPacket
    } catch {
      Write-Host "An error occurred while configuring power setting Wake on Magic Packet on NIC $($NIC.name): $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring power setting Wake on Magic Packet on NIC $($NIC.name): $_"
      
      $errors++
    }
  }
  
  # Configure Wake on Pattern in the NIC power settings
  if ($powerWoP -eq $null) { 
    Write-Host "Wake on Pattern is not an option in power settings on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern is not an option in power settings on NIC $($NIC.name)."
  } elseif ($powerWoP -eq "Disabled") {
    Write-Host "Wake on Pattern is already disabled in power settings on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern is already disabled in power settings on NIC $($NIC.name)."
  } else { # Set Wake Wake on Pattern in the NIC power settings to Disabled
    try {
      Write-Host "Disabling Wake on Pattern in the power settings on NIC $($NIC.name)..."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling Wake on Pattern in the power settings on NIC $($NIC.name)..."
      
      Set-NetAdapterPowerManagement -Name $NIC.name -WakeOnPattern "Disabled"
      $NIC | Disable-NetAdapterPowerManagement -WakeOnPattern
    } catch {
      Write-Host "An error occurred while configuring power setting Wake on Pattern on NIC $($NIC.name): $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring power setting Wake on Pattern on NIC $($NIC.name): $_"
      
      $errors++
    }
  }
  
  # Configure the Allow computer to turn off device option in the NIC power settings
  if ($powerSaving -eq $null) {
    Write-Host "Allow computer to turn off device is not an option on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Allow computer to turn off device is not an option on NIC $($NIC.name)."
  } elseif ($powerSaving -eq "Disabled") {
    Write-Host "Allow computer to turn off device is already disabled on NIC $($NIC.name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Allow computer to turn off device is already disabled on NIC $($NIC.name)."
  } else {
    try {
      Write-Host "Disabling the Allow computer to turn off device option in the power settings on NIC $($NIC.name)..."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling the Allow computer to turn off device option in the power settings on NIC $($NIC.name)..."
      
      # Temp variable used to change the setting
      $setting = $NIC | Get-NetAdapterPowerManagement
      $setting.AllowComputerToTurnOffDevice = 'Disabled'
      $setting | Set-NetAdapterPowerManagement
    } catch {
      Write-Host "An error occurred while configuring the Allow computer to turn off device option setting on NIC $($NIC.name): $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while configuring the Allow computer to turn off device option setting on NIC $($NIC.name): $_"
      
      $errors++
    }
  }
}

if ($errors -eq 0) {
  Write-Host "Finished configuring all NICs with 0 errors."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Finished configuring all NICs with 0 errors."
} else {
  Write-Host "$errors errors occurred while configuring the NIC(s)."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $errors errors occurred while configuring the NIC(s)."
  
  exit 1
}