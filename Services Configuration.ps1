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

# Pulls the services to variables for use later
$fdrpService = Get-Service -name FDResPub
$ssdpService = Get-Service -name SSDPSRV
$upnpService = Get-Service -name upnphost

Write-Host "Configuring the FDResPub, SSDPSRV, and upnphost services..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the FDResPub, SSDPSRV, and upnphost services..."

# Checks to make sure the service gets pulled correctly
if ($fdrpService -eq $null) {
  Write-Host "The FDResPub service could not be found."
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
    Write-Host "The startup type for FDResPub is already set to Automatic: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The startup type for FDResPub is already set to Automatic: $_"
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
    Write-Host "The FDResPub service is already running."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The FDResPub service is already running."
  }
}

# Checks to make sure the service gets pulled correctly
if ($ssdpService -eq $null) {
  Write-Host "The SSDPSRV service could not be found."
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
    Write-Host "The startup type for SSDPSRV is already set to Automatic."
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
    Write-Host "The SSDPSRV service is already running."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The SSDPSRV service is already running."
  }
}

# Checks to make sure the service gets pulled correctly
if ($upnpService -eq $null) {
  Write-Host "The upnphost service could not be found."
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
    Write-Host "The startup type for upnphost is already set to Automatic."
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
    Write-Host "The upnphost service is already running."
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
