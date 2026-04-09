# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# If true, sets the Static IP device tag if a static IP is found on the device.
$setTag = $env:setDeviceTag

# For tracking static IPs
$staticIPCount = 0

# Current Ninja tags
$tags = Get-NinjaTag

Write-Host "Auditing the NICs for static IPs."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the NICs for static IPs."

# Get the physical NIC(s). Ignore wireless NIC(s).
$NICs = Get-NetAdapter -Physical | Where-Object {$_.Name -notmatch "Wi-Fi|Wireless"} | Where-Object {$_.status -eq "Up"}

# Configure all NIC(s)
foreach ($NIC in $NICs) {
  # If the IP of the NIC is staic and not manual.
  if ((Get-NetIPAddress -InterfaceAlias $NIC.Name).PrefixOrigin -eq "Manual") {
    Write-Host "The NIC $($NIC.name) has a static IP."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The NIC $($NIC.name) has a static IP."
    
    $staticIPCount++
  } 
}

if ($staticIPCount -gt 0) {
  # Set the device tag.
  if ($setTag -eq $true) {
    if ($tags -match "Static IP") {
      Write-Host "The device already has the Static IP device tag."
    } else {
      Write-Host "Setting the Static IP device tag..."
      Set-NinjaTag -Name "Static IP"
    } 
  }
} else {
  Write-Host "No static IP was found."
  
  if ($tags -contains "Static IP") {
    Write-Host "Removing the Static IP device tag..."
    Remove-NinjaTag -Name "Static IP"
  }
}