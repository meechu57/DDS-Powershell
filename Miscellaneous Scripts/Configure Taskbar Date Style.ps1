# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Convert the script variable to a local variable then to the correct formatting for the registry value.
$dateStyle = $env:dateLayout
if ($dateStyle -eq "MM  DD  YYYY") {
  $dateStyle = "MM/dd/yyyy"
} elseif ($dateStyle -eq "M D YYYY") {
  $dateStyle = "M/d/yyyy"
} else {
  Write-Host "Could not decipher the date style that was input. Fix it and try again. Currently it's set to $dateStyle."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Could not decipher the date style that was input. Fix it and try again. Currently it's set to $dateStyle."
  
  exit 1
}

Write-Host "Configuring the date layout on the taskbar to $dateStyle..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the date layout on the taskbar to $dateStyle..."

Write-Host "Loading Default registry hive."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Loading Default registry hive."
REG LOAD HKLM\Default C:\Users\Default\NTUSER.DAT

# Set the date on the taskbar to the style selected by the script variable.
$reg = New-ItemProperty "HKLM:\Default\Control Panel\International" -Name "sShortDate" -Value $dateStyle -PropertyType String -Force
try { $reg.Handle.Close() } catch {}

[GC]::Collect()
REG UNLOAD HKLM\Default

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

  # Set the date on the taskbar to the style selected by the script variable.
  $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Control Panel\International" -Name "sShortDate" -Value $dateStyle -PropertyType String -Force
  try { $reg.Handle.Close() } catch {}

  # Unload NTUser.dat
  if ($ProfileWasLoaded -eq $false) {
    [GC]::Collect()
    Start-Sleep 1
    REG UNLOAD HKU\$($UserProfile.SID)
  }
}