# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Get all physical NICs.
$NICs = Get-NetAdapter -Physical

# Sets DNS to automatic.
if ($env:dnsOrIp -eq "DNS") {
  foreach ($adapter in $NICs) {
    Write-Host "Setting DNS to automatic on the $($adapter.name) NIC..."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Setting DNS to automatic on the $($adapter.name) NIC..."
    
    # Check to see if there is a static IP. Exit if the NIC isn't in DHCP mode.
    if ((Get-NetIPAddress -InterfaceIndex $adapter.ifIndex).PrefixOrigin -ne "Dhcp") {
      Write-Host "Cannot set DNS to automatic while a static IP is set. Please run the script as 'Both'."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Cannot set DNS to automatic while a static IP is set. Please run the script as 'Both'."
      
      exit 1
    }
    
    # Reset DNS to automatic.
    try {
      Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
    } catch {
      Write-Host "An error occurred while setting DNS to automatic on the $($adapter.name) NIC: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting DNS to automatic on the $($adapter.name) NIC: $_"
    }
  }
}

# Sets the IP to automatic then restarts the NIC to get the default gateway to re-establish.
if ($env:dnsOrIp -eq "IP") {
  foreach ($adapter in $NICs) {
    Write-Host "Setting the IP to automatic on the $($adapter.name) NIC..."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Setting the IP to automatic on the $($adapter.name) NIC..."
    
    try {
      # Remove the static IP & Default Gateway
      Remove-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false
      Remove-NetRoute -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false
      
      # Enable DHCP and restart the NIC
      Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -Dhcp Enabled 
      Restart-NetAdapter -InterfaceAlias $adapter.name
    } catch {
      Write-Host "An error occurred while setting the IP to automatic on the $($adapter.name) NIC: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting the IP to automatic on the $($adapter).name NIC: $_"
      
      exit 1
    }
  }
  
  # Remove the Static IP device tag if it is assigned to the device
  $tags = Get-NinjaTag
  if ($tags -match "Static IP") {
    Write-Host "Removing the Static IP device tag..."
    Remove-NinjaTag -Name "Static IP"
  }
}

# Resets both DNS and IP.
if ($env:dnsOrIp -eq "Both") {
  foreach ($adapter in $NICs) {
    Write-Host "Setting the IP and DNS to automatic on the $($adapter.name) NIC..."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Setting the IP and DNS to automatic on the $($adapter.name) NIC..."
    
    try {
      # Reset DNS to automatic.
      Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
      
      # Remove the static IP & Default Gateway
      Remove-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false
      Remove-NetRoute -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false
      
      # Enable DHCP and restart the NIC
      Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -Dhcp Enabled 
      Restart-NetAdapter -InterfaceAlias $adapter.name
    } catch {
      Write-Host "An error occurred while setting the IP and DNS to automatic on the $($adapter.name) NIC: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred while setting the IP and DNS to automatic on the $($adapter.name) NIC: $_"
      
      exit 1
    }
  }
  
  # Remove the Static IP device tag if it is assigned to the device
  $tags = Get-NinjaTag
  if ($tags -match "Static IP") {
    Write-Host "Removing the Static IP device tag..."
    Remove-NinjaTag -Name "Static IP"
  }
}