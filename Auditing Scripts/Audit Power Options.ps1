# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# Assigning these as variables for readability purposes
$usbSubGUID = '2a737441-1930-4402-8d77-b2bebba308a3'
$usbSelectiveSuspend = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'
$hubSelectiveSuspend = '0853a681-27c8-4100-a2fd-82013e970683'
$usbLinkPowerManagement = 'd4e98f31-5ffe-4ce1-be31-1b38b384c009'

# Power options to verify
$subSleep = @('STANDBYIDLE', 'HYBRIDSLEEP', 'HIBERNATEIDLE', 'RTCWAKE')
$usb = @($usbSelectiveSuspend, $hubSelectiveSuspend, $usbLinkPowerManagement)
$subSleepVerification = $null
$usbVerification = $null
$subVideoVerification = $null
$diskVerification = $null
$hibernateVerification = $null

# Start of verification in the log
Write-Host "Auditing the power options..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the power options..." 

# Verify the results of the SUB_SLEEP GUID
foreach ($i in $subSleep) {
  $index = powercfg /qh SCHEME_CURRENT SUB_SLEEP $i | Select-String -Pattern "Power Setting Index: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
  if ($index[0] -ne '0x00000000' -or $index[1] -ne '0x00000000') {
    Write-Host "WARNING! The $i power setting was not set correctly. Manual investigation required."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! The $i power setting was not set correctly. Manual investigation required."
    
    $subSleepVerification = $false
    break
  } else {
   $subSleepVerification = $true
 }
}

# Verify the results of the USB GUID
foreach ($i in $usb) {
 $index = powercfg /qh SCHEME_CURRENT $usbSubGUID $i | Select-String -Pattern "Power Setting Index: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
 if ($index[0] -ne '0x00000000' -or $index[1] -ne '0x00000000') {
   Write-Host "WARNING! One of the USB setting was not set correctly. Manual investigation required."
   Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! One of the USB setting was not set correctly. Manual investigation required."
   
   $usbVerification = $false
   bre
 } else {
    $usbVerification = $true
  }
}

# Verify the results of VIDEOIDLE
$index = powercfg /qh SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | Select-String -Pattern "Power Setting Index: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
if ($index[0] -ne '0x00001518' -or $index[1] -ne '0x00001518') {
  Write-Host "WARNING! The VIDEOIDLE power setting was not set correctly. Manual investigation required."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! The VIDEOIDLE power setting was not set correctly. Manual investigation required."
 
  $subVideoVerification = $false
} else {
  $subVideoVerification = $true
}

# Verify the results of DISKIDLE
$index = powercfg /qh SCHEME_CURRENT SUB_DISK DISKIDLE | Select-String -Pattern "Power Setting Index: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
if ($index[0] -ne '0x00000000' -or $index[1] -ne '0x00000000') {
  Write-Host "WARNING! The DISKIDLE power setting was not set correctly. Manual investigation required."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! The DISKIDLE power setting was not set correctly. Manual investigation required."
  
  $diskVerification = $false
} else {
  $diskVerification = $true
}

# Verify the results of Hibernation
$regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Power"
$hibernateRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name HibernateEnabled -ErrorAction SilentlyContinue
if ($hibernateRegKey.HibernateEnabled -ne 0) {
  Write-Host "WARNING! Hibernation is not disabled. Manual investigation required."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! Hibernation is not disabled. Manual investigation required."
  
  $hibernateVerification = $false
} else {
  $hibernateVerification = $true
}

# Verify the overall results
if ($subSleepVerification -eq $true -and $usbVerification -eq $true -and $subVideoVerification -eq $true -and $diskVerification -eq $true -and $hibernateVerification -eq $true) {
  Write-Host "All power options were successfully set."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All power options were successfully set." 
  
  Ninja-Property-Set powerOptionsSet $true
} else {
  Write-Host "WARNING! One or more power setting was not set properly. Manual investigation required."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") WARNING! One or more power setting was not set properly. Manual investigation required."
  
  Ninja-Property-Set powerOptionsSet $false
}
