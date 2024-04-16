# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Path where the Adobe .exe file exists
$exePath = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"

# Registry path where the RUNASADMIN data is set
$regPath = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

# Pulls the registry key to see if it was created previously
$adminRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name $exePath -ErrorAction SilentlyContinue

Write-Host "Configuring Adobe to run as admin..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring Adobe to run as admin..."

# Verify that Adobe is actually installed before proceeding
if (Test-Path $exePath) { 
  # If the registry key doesn't exist, create it.
  if ($adminRegKey -eq $null) {
    try {
     reg add $regPath /v $exePath /t REG_SZ /d "RUNASADMIN" /f 
    } catch {
      Write-Host "Failed to add the RUNASADMIN registry key: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the RUNASADMIN registry key: $_"
    }
    
    # Pull the registry key again
    $adminRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name $exePath -ErrorAction SilentlyContinue
    
    # Verify that the registry key was added properly
    if ($adminRegKey.$exePath -eq "RUNASADMIN") {
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
