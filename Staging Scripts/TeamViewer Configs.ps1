# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

Write-Host "Configuring TeamViewer settings..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring TeamViewer settings..."

# Create the registry keys if they don't exist.
if (-not (Test-Path ("registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TeamViewer"))) {
  New-Item -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TeamViewer" -Force
}
if (-not (Test-Path ("registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TeamViewer\MsgBoxDontShow"))) {
  New-Item -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TeamViewer\MsgBoxDontShow" -Force
}

# For password length/visibility
$wow6432PWStrength = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TeamViewer" -name Security_PasswordStrength -ErrorAction SilentlyContinue).Security_PasswordStrength
if ($wow6432PWStrength -ne 4) {
  New-ItemProperty "registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TeamViewer" -Name "Security_PasswordStrength" -Value "4" -PropertyType Dword -Force
}
$pwStrength = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TeamViewer" -name Security_PasswordStrength -ErrorAction SilentlyContinue).Security_PasswordStrength
if ($pwStrength -ne 4) {
  New-ItemProperty "registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TeamViewer" -Name "Security_PasswordStrength" -Value "4" -PropertyType Dword -Force
}

# Load the default user.
Write-Host "Loading Default registry hive."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Loading Default registry hive."
REG LOAD HKLM\Default C:\Users\Default\NTUSER.DAT

# Create the registry keys if they don't exist.
if (-not (Test-Path ("registry::HKLM\Default\Software\TeamViewer"))) {
  New-Item -Path "registry::HKLM\Default\Software\TeamViewer" -Force
}
if (-not (Test-Path ("registry::HKLM\Default\Software\TeamViewer\MsgBoxDontShow"))) {
  New-Item -Path "registry::HKLM\Default\Software\TeamViewer\MsgBoxDontShow" -Force
}

# For message on session end
$reg = New-ItemProperty "registry::HKLM\Default\Software\TeamViewer" -Name "SuppressMessageOnRemoteClosing" -Value "1" -PropertyType Dword -Force
try { $reg.Handle.Close() } catch {}
$reg = New-ItemProperty "registry::HKLM\Default\Software\TeamViewer" -Name "ChangeDynamicPassword" -Value "1" -PropertyType Dword -Force
try { $reg.Handle.Close() } catch {}
$reg = New-ItemProperty "registry::HKLM\Default\Software\TeamViewer\MsgBoxDontShow" -Name "MsgBoxDontShow" -Value "1" -PropertyType Dword -Force
try { $reg.Handle.Close() } catch {}
$reg = New-ItemProperty "registry::HKLM\Default\Software\TeamViewer\MsgBoxDontShow" -Name "PasswordOnSessionEnd" -Value "1" -PropertyType Dword -Force
try { $reg.Handle.Close() } catch {}

# For generating a password on session end
$reg = New-ItemProperty "registry::HKLM\Default\Software\TeamViewer" -Name "DeactivatedDynamicPassword" -Value "0" -PropertyType Dword -Force
try { $reg.Handle.Close() } catch {}

# Unload the Default user.
[GC]::Collect()
REG UNLOAD HKLM\Default

# Get a list of all users on the machine.
$UserProfiles = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
Where-Object { $_.PSChildName -match "S-1-5-21-(\d+-?){4}$" } |
Select-Object @{Name = "SID"; Expression = { $_.PSChildName } }, @{Name = "UserHive"; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } }

# Loop through each profile on the machine
foreach ($UserProfile in $UserProfiles) {
  Write-Host "Running for profile: $($UserProfile.UserHive)"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Running for profile: $($UserProfile.UserHive)"

  # Load User NTUser.dat if it's not already loaded
  if (($ProfileWasLoaded = Test-Path Registry::HKEY_USERS\$($UserProfile.SID)) -eq $false) {
    REG LOAD HKU\$($UserProfile.SID) $($UserProfile.UserHive)
  }
  
  # Create the registry keys if they don't exist.
  if (-not (Test-Path ("registry::HKEY_USERS\$($UserProfile.SID)\Software\TeamViewer"))) {
    New-Item -Path "registry::HKEY_USERS\$($UserProfile.SID)\Software\TeamViewer" -Force
  }
  if (-not (Test-Path ("registry::HKEY_USERS\$($UserProfile.SID)\Software\TeamViewer\MsgBoxDontShow"))) {
    New-Item -Path "registry::HKEY_USERS\$($UserProfile.SID)\Software\TeamViewer\MsgBoxDontShow" -Force
  }

  # For message on session end
  $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\TeamViewer" -Name "SuppressMessageOnRemoteClosing" -Value "1" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}
  $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\TeamViewer" -Name "ChangeDynamicPassword" -Value "1" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}
  $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\TeamViewer\MsgBoxDontShow" -Name "MsgBoxDontShow" -Value "1" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}
  $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\TeamViewer\MsgBoxDontShow" -Name "PasswordOnSessionEnd" -Value "1" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # For generating a password on session end
  $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\TeamViewer" -Name "DeactivatedDynamicPassword" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}


  # Unload NTUser.dat
  if ($ProfileWasLoaded -eq $false) {
    [GC]::Collect()
    Start-Sleep 1
    REG UNLOAD HKU\$($UserProfile.SID)
  }
}