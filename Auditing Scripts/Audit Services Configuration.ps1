# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# Pulls the services to variables for use later
$fdrpService = Get-Service -name FDResPub
$ssdpService = Get-Service -name SSDPSRV
$upnpService = Get-Service -name upnphost

# For error tracking
$errors = 0

# Test to make sure the service gets pulled correctly
if ($fdrpService -eq $null) {
  Write-Host "The FDResPub service could not be found."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The FDResPub service could not be found."
  
  $errors++
} 
else {
  # If the service isn't set to Automatic or isn't running, it isn't configured properly
  if ($fdrpService.StartType -ne 'Automatic' -or $fdrpService.Status -ne 'Running') {
    Write-Host "The FDResPub service is not configured properly. Manual investigation is required."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The FDResPub service is not configured properly. Manual investigation is required."
    
    $errors++
  }
}

# Test to make sure the service gets pulled correctly
if ($ssdpService -eq $null) {
  Write-Host "The SSDPSRV service could not be found."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The SSDPSRV service could not be found."
  
  $errors++
} 
else {
  # If the service isn't set to Automatic or isn't running, it isn't configured properly
  if ($ssdpService.StartType -ne 'Automatic' -or $ssdpService.Status -ne 'Running') {
    Write-Host "The SSDPSRV service is not configured properly. Manual investigation is required."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The SSDPSRV service is not configured properly. Manual investigation is required."
    
    $errors++
  }
}

# Test to make sure the service gets pulled correctly
if ($upnpService -eq $null) {
  Write-Host "The upnphost service could not be found."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The upnphost service could not be found."
  
  $errors++
} 
else {
  # If the service isn't set to Automatic or isn't running, it isn't configured properly
  if ($upnpService.StartType -ne 'Automatic' -or $upnpService.Status -ne 'Running') {
    Write-Host "The upnphost service is not configured properly. Manual investigation is required."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The upnphost service is not configured properly. Manual investigation is required."
    
    $errors++
  }
}

# If the error counter is 0, we're in the clear. If the above auditing caught any errors, the value will be greater than 0.
if ($errors -eq 0) {
  Write-Host "All services are properly configured."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All services are properly configured."
  
  Ninja-Property-Set servicesConfigured $true
} else {
  Write-Host "Errors were found in the configuration of the services. Number of services improperly configured: $errors."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Errors were found in the configuration of the services. Number of services improperly configured: $errors."
  
  Ninja-Property-Set servicesConfigured $false
}
