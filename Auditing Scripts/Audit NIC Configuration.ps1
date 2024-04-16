# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

Write-Host "Auditing the configuration of the NIC(s)..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the configuration of the NIC(s)..."

# Get the physical NIC(s)
$NICs = Get-NetAdapter -Physical

# For error tracking. Should only be incremented if any of the below variables are Null.
$errors = 0


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
  
  # Should be false for IPv6 to be disabled on the NIC
  if ($IPv6 -ne $false -and $IPv6 -ne $null) {
    Write-Host "IPv6 is not disabled on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") IPv6 is not disabled on NIC: $($NIC.Name)."
    
    $errors++
  } elseif ($IPv6 -eq $null) {
    Write-Host "IPv6 is not an option on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") IPv6 is not an option on NIC: $($NIC.Name)."
  }
  
  # Should be set to 0 for Wake on Magic Packet to be disabled on the NIC.
  if ($WoMP -ne 0 -and $WoMP -ne $null) {
    Write-Host "Wake on Magic Packet is not disabled on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is not disabled on NIC: $($NIC.Name)."
    
    $errors++
  } elseif ($WoMP -eq $null) {
    Write-Host "Wake on Magic Packet is not an option on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is not an option on NIC: $($NIC.Name)."
  }
  
  # Should be set to 0 for Wake on Pattern Match to be disabled on the NIC.
  if ($WoP -ne 0 -and $WoP -ne $null) {
    Write-Host "Wake on Pattern Match is not disabled on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on pattern match is not disabled on NIC: $($NIC.Name)."
    
    $errors++
  } elseif ($WoP -eq $null) {
    Write-Host "Wake on Pattern Match is not an option on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern Match is not an option on NIC: $($NIC.Name)."
  }
  
  # Should be set to 0 for Energy Efficient Ethernet to be disabled on the NIC.
  if ($EEE -ne 0 -and $EEE -ne $null) {
    Write-Host "Energy Efficient Ethernet is not disabled on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Energy Efficient Ethernet is not disabled on NIC: $($NIC.Name)."
    
    $errors++
  } elseif ($EEE -eq $null) {
    Write-Host "Energy Efficient Ethernet is not an option on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Energy Efficient Ethernet is not an option on NIC: $($NIC.Name)."
  }
  
  # Should be set to 0 for Advanced EEE to be disabled on the NIC.
  if ($AdvEEE -ne 0 -and $AdvEEE -ne $null) {
    Write-Host "Advanced EEE is not disabled on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Advanced EEE is not disabled on NIC: $($NIC.Name)."
    
    $errors++
  } elseif ($AdvEEE -eq $null) {
    Write-Host "Advanced EEE is not an option on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Advanced EEE is not an option on NIC: $($NIC.Name)."
  }
  
  # Should be set to 0 for Green Ethernet to be disabled on the NIC.
  if ($GE -ne 0 -and $GE -ne $null) {
    Write-Host "Green Ethernet is not disabled on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Green Ethernet is not disabled on NIC: $($NIC.Name)."
    
    $errors++
  }
  elseif ($GE -eq $null) {
    Write-Host "Green Ethernet is not an option on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Green Ethernet is not an option on NIC: $($NIC.Name)."
  }
  
  # Should be set to 0 for Ultra Low Power Mode to be disabled on the NIC.
  if ($ULPM -ne 0 -and $ULPM -ne $null) {
    Write-Host "Ultra Low Power Mode is not disabled on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ultra Low Power Mode is not disabled on NIC: $($NIC.Name)."
    
    $errors++
  }
  elseif ($ULPM -eq $null) {
    Write-Host "Ultra Low Power Mode is not an option on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ultra Low Power Mode is not an option on NIC: $($NIC.Name)."
  }
  
  # Should be set to Disabled for Wake on Magic Pattern to be disabled in power settings on the NIC.
  if ($powerWoMP -ne "Disabled" -and $powerWoMP -ne $null) {
    Write-Host "Wake on Magic Packet is not disabled in power settings on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is not disabled in power settings on NIC: $($NIC.Name)."
    
    $errors++
  }
  elseif ($powerWoMP -eq $null) {
    Write-Host "Wake on Magic Packet is not an option in power settings on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Magic Packet is not an option in power settings on NIC: $($NIC.Name)."
  }
  
  # Should be set to Disabled for Wake on Pattern to be disabled in power settings on the NIC.
  if ($powerWoP -ne "Disabled" -and $powerWoP -ne $null) {
    Write-Host "Wake on Pattern is not disabled in power settings on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern is not disabled in power settings on NIC: $($NIC.Name)."
    
    $errors++
  }
  elseif ($powerWoP -eq $null) {
    Write-Host "Wake on Pattern is not an option in power settings on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Wake on Pattern is not an option in power settings on NIC: $($NIC.Name)."
  }
  
  # Should be set to Disabled for Allow Computer To Turn Off Device to be disabled in power settings on the NIC.
  if ($powerSaving -ne "Disabled" -and $powerSaving -ne $null) {
    Write-Host "Allow Computer To Turn Off Device is not disabled in power settings on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Allow Computer To Turn Off Device is not disabled in power settings on NIC: $($NIC.Name)."
    
    $errors++
  }
  elseif ($powerSaving -eq $null) {
    Write-Host "Allow Computer To Turn Off Device is not an option in power settings on NIC: $($NIC.Name)."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Allow Computer To Turn Off Device is not an option in power settings on NIC: $($NIC.Name)."
  }
}

# If no errors, all NICs are configured properly.
if ($errors -eq 0) {
  Write-Host "All NICs are configured properly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All NICs are configured properly."
  
  Ninja-Property-Set networkAdapterConfigured $true
}
else {
  Write-Host "Errors were found in the configuration of the NIC(s). Number of errors found: $errors."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Errors were found in the configuration of the NIC(s). Number of errors found: $errors."
  
  Ninja-Property-Set networkAdapterConfigured $false
}
