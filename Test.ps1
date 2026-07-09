# The log path for this script.
$logPath = "C:\DDS\Logs\Audit.log"

# Convert script variables to local variables.
$showPaths = $true
$showMappedDrives = $true

Write-Host "Auditing Folder Redirection$(if ($showMappedDrives) { ' and Mapped Drives' })..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Folder Redirection$(if ($showMappedDrives) { ' and Mapped Drives' })..."

# Grabs the last logged in user via the registry.
$lastLoggedInUser = [PSCustomObject]@{
  User = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name LastLoggedOnUser -ErrorAction SilentlyContinue).LastLoggedOnUser
  DisplayName = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name LastLoggedOnDisplayName -ErrorAction SilentlyContinue).LastLoggedOnDisplayName
  SID = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name LastLoggedOnUserSID -ErrorAction SilentlyContinue).LastLoggedOnUserSID
}

# Path to Folder Redirection registry location for this user
$regPath = "Registry::HKEY_USERS\$($lastLoggedInUser.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

# Name of the computer's domain.
$domainName = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

# Only proceed if the registry path exists
if (Test-Path $regPath) {
  # Get folder path values from registry
  $folders = Get-ItemProperty $regPath

  # Expand environment variables (e.g. %USERPROFILE%)
  $desktopPath   = [Environment]::ExpandEnvironmentVariables($folders.Desktop)
  $documentsPath = [Environment]::ExpandEnvironmentVariables($folders.Personal)
  $picturesPath = [Environment]::ExpandEnvironmentVariables($folders.'My Pictures')
  $videosPath = [Environment]::ExpandEnvironmentVariables($folders.'My Video')
  $musicPath = [Environment]::ExpandEnvironmentVariables($folders.'My Music')

  # Build HasFolderRedirection summary
  $redirectedFolders = @()
  if ($desktopPath -like "\\*")   { $redirectedFolders += "Desktop" }
  if ($documentsPath -like "\\*") { $redirectedFolders += "Documents" }
  if ($picturesPath -like "\\*")  { $redirectedFolders += "Pictures" }
  if ($videosPath -like "\\*")    { $redirectedFolders += "Videos" }
  if ($musicPath -like "\\*")     { $redirectedFolders += "Music" }

  # Check for any missing redirected folders to show in the $results.
  $allFolders = @("Desktop", "Documents", "Pictures", "Videos", "Music")
  $missing = $allFolders | Where-Object { $_ -notin $redirectedFolders }
  if ($missing.Count -eq 0) {
    $status = "Compliant"
  } elseif ($missing.Count -eq 5) {
    $status = "Not Configured"
  } else {
    $status = "Configured. Missing Redirected Folders: " + ($missing -join ", ")
  }

  # Get all mapped drives the user may be using.
  $mappedDrives = Get-ChildItem "Registry::HKEY_USERS\$($lastLoggedInUser.SID)\Network" | 
    Select-Object @(
      @{ N = 'Drive'; E = { $_.PSChildName.ToUpper() } }
      @{ N = 'Pathway'; E = { $_.GetValue('RemotePath') }})
  
  # Final results. Results may be added to based on script variables.
  $results = @(
    "Folder Redirection Status:",
    "User   | $($lastLoggedInUser.User)",
    "Status | $status"
    )
  
  # Optionally show the pathways of the potential redirected folders.
  if ($showPaths -eq $true) {
    $results += @(
      "",
      "Folder Pathways:",
      "Desktop   | $desktopPath",
      "Documents | $documentsPath",
      "Pictures  | $picturesPath",
      "Videos    | $videosPath",
      "Music     | $musicPath"
    )
  }
  
  # Optionally show the pathways of the mapped drives.
  if ($showMappedDrives -eq $true) {
    $results += ""
    $results += "Mapped Drives:"
    if ($mappedDrives -ne $null) {
      $results += ($mappedDrives | ForEach-Object { "Drive: $($_.Drive)  | Pathway: $($_.Pathway)" })
    } else {
      $results += "None" 
    }
  }

  # Show the results and set the custom field.
  $results -join "`n"
  #Ninja-Property-Set folderRedirectionAudit $results
} 
else {
  Write-Host "Couldn't find the $regPath registry pathway."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Couldn't find the $regPath registry pathway."
  
  exit 1
}
