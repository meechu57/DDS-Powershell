# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

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

# Check if the script was run as the default System User
function Test-IsSystem {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
}

# If it was we'll error out and enform the technician they should run it as the "Current Logged on User"
if (Test-IsSystem) {
  Write-Host "This script does not work when ran as system. Use Run As: 'Current Logged on User'."
  exit 1
}

Write-Host "Configuring TeamViewer settings..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring TeamViewer settings..."

# For password length/visibility
if ($wow6432PWStrength -eq $null -or $wow6432PWStrength -ne 4) {
  try {
    reg add "HKLM\Software\WOW6432Node\TeamViewer" /v Security_PasswordStrength /t REG_DWORD /d 4 /f
  } catch {
    Write-Host "Failed to add/set the WOW6432 Security_PasswordStrength registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add/set the WOW6432 Security_PasswordStrength registry key: $_"
    
    $errors++
  }
}

if ($pwStrength -eq $null -or $pwStrength -ne 4) {
  try {
    reg add "HKLM\Software\TeamViewer" /v Security_PasswordStrength /t REG_DWORD /d 4 /f
  } catch {
    Write-Host "Failed to add/set the Security_PasswordStrength registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add/set the Security_PasswordStrength registry key: $_"
    
    $errors++
  }
} 

# For message on session end
if ($suppressOnClose -eq $null -or $suppressOnClose -ne 1) {
  try {
    reg add "HKCU\Software\TeamViewer" /v SuppressMessageOnRemoteClosing /t REG_DWORD /d 1 /f
  } catch {
    Write-Host "Failed to add/set the SuppressMessageOnRemoteClosing registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add/set the SuppressMessageOnRemoteClosing registry key: $_"
    
    $errors++
  }
}

if ($msgDontShow -eq $null -or $msgDontShow -ne 1) {
  try {
    reg add "HKCU\Software\TeamViewer\MsgBoxDontShow" /v MsgBoxDontShow /t REG_DWORD /d 1 /f
  } catch {
    Write-Host "Failed to add/set the MsgBoxDontShow registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add/set the MsgBoxDontShow registry key: $_"
      
    $errors++
  }
}

if($pwOnEnd -eq $null -or $pwOnEnd -ne 1) {
  try {
    reg add "HKCU\Software\TeamViewer\MsgBoxDontShow" /v PasswordOnSessionEnd /t REG_DWORD /d 1 /f
  } catch {
    Write-Host "Failed to add/set the PasswordOnSessionEnd registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add/set the PasswordOnSessionEnd registry key: $_"
      
    $errors++
  }
}

if ($dynamicPW -eq $null -or $dynamicPW -ne 1) {
  try {
    reg add "HKCU\Software\TeamViewer" /v ChangeDynamicPassword /t REG_DWORD /d 1 /f
  } catch {
    Write-Host "Failed to add/set the ChangeDynamicPassword registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add/set the ChangeDynamicPassword registry: $_"
    
    $errors++
  }
}

# For generating a password on session end
if ($dynamicPWDeactive -eq $null -or $dynamicPWDeactive -ne 0) {
  try {
    reg add "HKCU\Software\TeamViewer" /v DeactivatedDynamicPassword /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to add/set the DeactivatedDynamicPassword registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add/set the DeactivatedDynamicPassword registry: $_"
    
    $errors++
  }
}

# Show any errors
Write-Host "Finished configuring TeamViewer settings with $errors errors."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Finished configuring TeamViewer settings with $errors errors."

# Restart TeamViewer to get updated settings
Write-Host "Restarting TeamViewer..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Restarting TeamViewer..."

# Restart the service
Restart-Service -Name TeamViewer

Start-Sleep -Seconds 5

# Manually start TeamViewer if it doesn't start with the service (Full version)
if ((Get-Process -Name TeamViewer) -eq $null) {
  start "C:\Program Files\TeamViewer\TeamViewer.exe"
}

Start-Sleep -Seconds 5

# Check to see if the TeamViewer process is running
if ((Get-Process -Name TeamViewer) -eq $null) {
  Write-Host "An error occurred when starting TeamViewer. TeamViewer did not start properly."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when starting TeamViewer. TeamViewer did not start properly."
  
  exit 1
} else {
  Write-Host "TeamViewer was successfully restarted."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") TeamViewer was successfully restarted."
}