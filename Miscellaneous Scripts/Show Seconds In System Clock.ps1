# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

Write-Host "Configuring Adobe to be the default PDF viewer."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring Adobe to be the default PDF viewer."

Write-Host "Loading Default registry hive."
REG LOAD HKLM\Default C:\Users\Default\NTUSER.DAT

# Create the registry key if it doesn't exist yet.
if (-not(Test-Path "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice")) {
  New-Item -Path "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" -Force
}

# Sets Adobe as the default application for .PDF extensions.
$reg = New-ItemProperty -Path "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" -Name "ProgId" -Value "AcroExch.Document.DC" -PropertyType String -Force
try { $reg.Handle.Close() } catch {}

Write-Host "Unloading Default registry hive."
[GC]::Collect()
REG UNLOAD HKLM\Default

$UserProfiles = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
  Where-Object { $_.PSChildName -match "S-1-5-21-(\d+-?){4}$" } |
  Select-Object @{Name = "SID"; Expression = { $_.PSChildName } }, @{Name = "UserHive"; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } }

# Loop through each profile on the machine
foreach ($UserProfile in $UserProfiles) {
  Write-Host "Running for profile: $($UserProfile.UserHive)"

  # Load User NTUser.dat if it's not already loaded
  if (($ProfileWasLoaded = Test-Path Registry::HKEY_USERS\$($UserProfile.SID)) -eq $false) {
    REG LOAD HKU\$($UserProfile.SID) $($UserProfile.UserHive)
  }
  
  # Create the registry key if it doesn't exist yet.
  if (-not(Test-Path "registry::HKEY_USERS\$($UserProfile.SID)\oftware\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice")) {
    New-Item -Path "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" -Force
  }

  # Sets Adobe as the default application for .PDF extensions.
  $reg = New-ItemProperty -Path "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" -Name "ProgId" -Value "AcroExch.Document.DC" -PropertyType String -Force
  try { $reg.Handle.Close() } catch {}

  # Unload NTUser.dat
  if ($ProfileWasLoaded -eq $false) {
    [GC]::Collect()
    Start-Sleep 1
    REG UNLOAD HKU\$($UserProfile.SID)
  }
}