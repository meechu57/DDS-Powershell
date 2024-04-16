# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Get the values of the 'Enabled' property for all three firewalls listed in the Get-NetFirewallProfile cmdlet.
$firewallProfiles = Get-NetFirewallProfile | Select-Object -ExpandProperty Enabled

# Check to see what the current state of the firewall is
if ($firewallProfiles -ne $null) {
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
