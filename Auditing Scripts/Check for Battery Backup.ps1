# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

if ((Get-Computerinfo).CsPCSystemType -ne "Mobile") {
  $battery = Get-CimInstance -ClassName Win32_Battery
  
  if ($battery -ne $null) {
    Write-Host "A battery backup has been detected. Name: $($battery.Name)"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A battery backup has been detected. Name: $($battery.Name)"
    
    Ninja-Property-Set batteryBackup "Yes: $($battery.Name)"
  } else {
    Write-Host "No battery backup was detected."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No battery backup was detected."
    
    Ninja-Property-Set batteryBackup "Not Detected"
  }
} else {
  Write-Host "This device is a laptop."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") This device is a laptop."
  
  Ninja-Property-Set batteryBackup "Laptop"
}