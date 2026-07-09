# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

$rightclickSyle = $env:setRightClickStyle

Write-Host "Attempting to change to the $($env:setRightClickStyle) style right click menu..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to change to the $($env:setRightClickStyle) style right click menu..."


if ($rightclickSyle -eq "Windows 10") {
  Write-Host "Loading Default registry hive."
  REG LOAD HKLM\Default C:\Users\Default\NTUSER.DAT
  
  $reg = New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force
  try { $reg.Handle.Close() } catch {}
  
  Write-Host "Unloading Default registry hive."
  [GC]::Collect()
  REG UNLOAD HKLM\Default
  
  $UserProfiles = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
  Where-Object { $_.PSChildName -match "S-1-5-21-(\d+-?){4}$" } |
  Select-Object @{Name = "SID"; Expression = { $_.PSChildName } }, @{Name = "UserHive"; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } }

  # Loop through each profile on the machine
  foreach ($UserProfile in $UserProfiles) {
    $reg = New-Item -Path "registry::HKEY_USERS\$($UserProfile.SID)\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force
    try { $reg.Handle.Close() } catch {}
    
     # Unload NTUser.dat
    if ($ProfileWasLoaded -eq $false) {
      [GC]::Collect()
      Start-Sleep 1
      REG UNLOAD HKU\$($UserProfile.SID)
    }
  }
}
elseif ($rightclickSyle -eq "Windows 11") {
  # Check to make sure the registry key actually exists before deleting it.
  if (-not (test-path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32")) {
    Write-Host "The registry path for the Windows 10 style right click doesn't exist. Exiting the script."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The registry path for the Windows 10 style right click doesn't exist. Exiting the script."
    
    exit 1
  }
  try {
    reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
    
    Write-Host "Successfully changed the right click menu to a Windows 11 style menu."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully changed the right click menu to a Windows 11 style menu."
  }
  catch {
    Write-Host "Failed to change the right click menu style: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to change the right click menu style: $_"
    
    exit 1
  }
}