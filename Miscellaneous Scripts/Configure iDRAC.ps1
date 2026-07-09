
# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

$iDRACIP = $env:idracIp
$iDRACNetmask = $env:idracNetmask
$iDRACGateway = $env:idracDefaultGateway
$iDRACPassword = $env:idracPassword

if ($env:setIdracPassword -eq $true) {
  Write-Host "Configuring the iDRAC password..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the iDRAC password..."
  try {
    racadm set iDRAC.Users.2.Password $iDRACPassword
  } catch {
    Write-Host "An error occurred when setting the password of the iDRAC port: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when setting the password of the iDRAC port: $_"
  }
}

if ($env:setIdracIp -eq $true) {
  Write-Host "Configuring the iDRAC IP address..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the iDRAC IP address..."
  try {
    racadm setniccfg -s $iDRACIP $iDRACNetmask $iDRACGateway
  } catch {
    Write-Host "An error occurred when setting the IP address of the iDRAC port: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when setting the IP address of the iDRAC port: $_"
  }
}