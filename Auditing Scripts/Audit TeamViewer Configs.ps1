# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# For password length/visibility
$wow6432PWStrength = (Get-ItemProperty -Path "Registry::HKLM\Software\WOW6432Node\TeamViewer" -name Security_PasswordStrength -ErrorAction SilentlyContinue).Security_PasswordStrength
$pwStrength = (Get-ItemProperty -Path "Registry::HKLM\Software\TeamViewer" -name Security_PasswordStrength -ErrorAction SilentlyContinue).Security_PasswordStrength

# For message on session end
$suppressOnClose = (Get-ItemProperty -Path "Registry::HKCU\Software\TeamViewer" -name SuppressMessageOnRemoteClosing -ErrorAction SilentlyContinue).SuppressMessageOnRemoteClosing
$msgDontShow = (Get-ItemProperty -Path "Registry::HKCU\Software\TeamViewer\MsgBoxDontShow" -name MsgBoxDontShow -ErrorAction SilentlyContinue).MsgBoxDontShow
$pwOnEnd = (Get-ItemProperty -Path "Registry::HKCU\Software\TeamViewer\MsgBoxDontShow" -name PasswordOnSessionEnd -ErrorAction SilentlyContinue).PasswordOnSessionEnd

# For generating a password on session end
$dynamicPW = (Get-ItemProperty -Path "Registry::HKCU\Software\TeamViewer" -name ChangeDynamicPassword -ErrorAction SilentlyContinue).ChangeDynamicPassword
$dynamicPWDeactive = (Get-ItemProperty -Path "Registry::HKCU\Software\TeamViewer" -name DeactivatedDynamicPassword -ErrorAction SilentlyContinue).DeactivatedDynamicPassword

# For error tracking
$errors = 0

Write-Host "Auditing TeamViewer settings..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing TeamViewer settings..."

# For password length/visibility
if ($wow6432PWStrength -eq $null -or $wow6432PWStrength -ne 4) {
  Write-Host "The WOW6432 Security_PasswordStrength registry key isn't set properly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The WOW6432S Security_PasswordStrength registry key isn't set properly."
  
  $errors++
}

# For password length/visibility
if ($pwStrength -eq $null -or $pwStrength -ne 4) {
  Write-Host "The Security_PasswordStrength registry key isn't set properly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The Security_PasswordStrength registry key isn't set properly."
  
  $errors++
}

# For message on session end
if ($suppressOnClose -eq $null -or $suppressOnClose -ne 1) {
  Write-Host "The SuppressMessageOnRemoteClosing registry key isn't set properly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The SuppressMessageOnRemoteClosing registry key isn't set properly."
  
  $errors++
}

# Generate password on session end
if ($msgDontShow -eq $null -or $msgDontShow -ne 1) {
  Write-Host "The MsgBoxDontShow registry key isn't set properly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The MsgBoxDontShow registry key isn't set properly."
  
  $errors++
}

# Message on session end
if($pwOnEnd -eq $null -or $pwOnEnd -ne 1) {
  Write-Host "The PasswordOnSessionEnd registry key isn't set properly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The PasswordOnSessionEnd registry key isn't set properly."
  
  $errors++
}

# For generating a password on session end
if ($dynamicPW -eq $null -or $dynamicPW -ne 1) {
  Write-Host "The ChangeDynamicPassword registry key isn't set properly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The ChangeDynamicPassword registry key isn't set properly."
  
  $errors++
}

# For generating a password on session end
if ($dynamicPWDeactive -eq $null -or $dynamicPWDeactive -ne 0) {
  Write-Host "The DeactivatedDynamicPassword registry key isn't set properly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The DeactivatedDynamicPassword registry key isn't set properly."
  
  $errors++
}

# If no errors were encountered, TeamViewer is configured properly.
if ($errors -eq 0) {
  Write-Host "TeamViewer settings are configured correctly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") TeamViewer settings are configured correctly."
  
  Ninja-Property-Set teamviewerConfigured $true
} 
else {
  Write-Host "TeamViewer is not configured properly. Number of settings misconfigured: $errors."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") TeamViewer is not configured properly. Number of settings misconfigured: $errors."
  
  Ninja-Property-Set teamviewerConfigured $false
}
