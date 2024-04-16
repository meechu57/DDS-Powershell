# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# For error tracking
$errors = 0

# Get the values of the 'Enabled' property for all three firewalls listed in the Get-NetFirewallProfile cmdlet.
$firewallProfiles = Get-NetFirewallProfile | Select-Object -ExpandProperty Enabled

# Ensure that we grabbed the values above correctly
if ($firewallProfiles -ne $null) {

  Write-Host "Auditing Windows Firewall..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Windows Firewall..."

  # Check to see if any of the values in $firewallProfiles are 'True'
  foreach ($i in $firewallProfiles) {
    if ($i -ne "False") {
      $errors++
    }
  }

  # If all three firewalls are disabled
  if ($errors -eq 0) {
    Write-Host "All firewalls are disabled."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All firewalls are disabled."
  
    Ninja-Property-Set windowsFirewallDisabled $true
  }
  # If any of the firewalls are enabled
  else {
    Write-Host "$($errors) firewall(s) are enabled. Manual investigation required."
    Add-Content -Path $logPath -Value "$($errors) firewall(s) are enabled. Manual investigation required."
  
    Ninja-Property-Set windowsFirewallDisabled $false
  }
}
else {
  Write-Host "Unable to find the state of Windows Firewall."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Unable to find the state of Windows Firewall."
  Ninja-Property-Set windowsFirewallDisabled $null
}
