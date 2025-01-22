# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Get the operating system version
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version

# Convert the script variable to a local variable. 
$enableDarkMode = $env:enableDarkMode

# Check if the OS version contains "10.0.2" (Windows 11)
if ($osVersion -like "10.0.2*") {
  #                                                    Taskbar configs
  Write-Host "Configuring the taskbar..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the taskbar..."

  Write-Host "Loading Default registry hive."
  REG LOAD HKLM\Default C:\Users\Default\NTUSER.DAT

  # Removes Task View from the Taskbar
  $reg = New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # Removes Widgets from the Taskbar
  $reg = New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}
  $reg = New-ItemProperty "HKLM:\Default\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests" -Name "AllowNewsAndInterests" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}
  $reg = New-ItemProperty "HKLM:\Default\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # Removes Copilot from the Taskbar
  $reg = New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # Removes Chat from the Taskbar
  $reg = New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # Default StartMenu alignment 0=Left
  $reg = New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # Default StartMenu pins layout 0=Default, 1=More Pins, 2=More Recommendations
  $reg = New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value "1" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # Removes search from the Taskbar
  $RegKey = "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\RunOnce"
  if (-not(Test-Path $RegKey )) {
    $reg = New-Item $RegKey -Force | Out-Null
    try { $reg.Handle.Close() } catch {}
  }
  $reg = New-ItemProperty $RegKey -Name "RemoveSearch"  -Value "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Search /t REG_DWORD /v SearchboxTaskbarMode /d 0 /f" -PropertyType String -Force
  try { $reg.Handle.Close() } catch {}

  # Disables the info tips
  $reg = New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowInfoTip" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # Disables the Iris info tips
  $reg = New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # Show all file name extensions
  $reg = New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value "0" -PropertyType Dword -Force
  try { $reg.Handle.Close() } catch {}

  # Adds Settings and File Explorer to the Start menu 
  reg add "HKLM\Default\Software\Microsoft\Windows\CurrentVersion\Start" /v VisiblePlaces /t REG_BINARY /d 86087352AA5143429F7B2776584659D4BC248A140CD68942A0806ED9BBA24882 /f

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
  
    # Removes Task View from the Taskbar
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Removes Widgets from the Taskbar
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests" -Name "AllowNewsAndInterests" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Removes Copilot from the Taskbar
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Removes Chat from the Taskbar
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Default StartMenu alignment 0=Left
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Default StartMenu pins layout 0=Default, 1=More Pins, 2=More Recommendations
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value "1" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Disables the info tips
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowInfoTip" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Disables the Iris info tips
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Removes search from the Taskbar
    $RegKey = "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Search"
    if (-not(Test-Path $RegKey )) {
        $reg = New-Item $RegKey -Force | Out-Null
        try { $reg.Handle.Close() } catch {}
    }
    $reg = New-ItemProperty $RegKey -Name "SearchboxTaskbarMode" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Show all file name extensions
    $reg = New-ItemProperty "registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value "0" -PropertyType Dword -Force
    try { $reg.Handle.Close() } catch {}
  
    # Adds Settings and File Explorer to the Start menu 
    reg add "HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Start" /v VisiblePlaces /t REG_BINARY /d 86087352AA5143429F7B2776584659D4BC248A140CD68942A0806ED9BBA24882 /f
  
    # Unload NTUser.dat
    if ($ProfileWasLoaded -eq $false) {
      [GC]::Collect()
      Start-Sleep 1
      REG UNLOAD HKU\$($UserProfile.SID)
    }
  }
} 
else {
  Write-Host "A Windows 11 OS was not found. Aborting the script."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A Windows 11 OS was not found. Aborting the script."

  exit 1
}