# Grabs the last logged in user via the registry.
$lastLoggedInUser = [PSCustomObject]@{
	User = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name LastLoggedOnUser -ErrorAction SilentlyContinue).LastLoggedOnUser
	DisplayName = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name LastLoggedOnDisplayName -ErrorAction SilentlyContinue).LastLoggedOnDisplayName
	SID = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name LastLoggedOnUserSID -ErrorAction SilentlyContinue).LastLoggedOnUserSID
}

# All user profiles, excluding the baked in profiles in the HKEY_USERS hive.
# The System, Local Service, and Network Services SIDs.
$excludedSIDs = @( "S-1-5-18", "S-1-5-19", "S-1-5-20" )
$profiles = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildName -match "^S-1-5-21-" -and $_.PSChildName -notin $excludedSIDs -and $_.PSChildName -notlike "*_Classes" }
$domainName = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

# Initialize the results array
$results = @()

# Loop through each user profile and collect folder data
foreach ($userprofile in $profiles) {
  # Extract SID from registry key
  $sid = $userprofile.PSChildName

  # Path to Folder Redirection registry location for this user
  $regPath = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

  # Attempt to translate SID to DOMAIN\Username format
  try {
    $user = (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
  } catch {
    # If translation fails, fall back to SID
    $user = $sid
  }

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

    # Determine if paths are redirected (UNC path = redirected)
    $desktopRedirected   = ($desktopPath -like "\\*")
    $documentsRedirected = ($documentsPath -like "\\*")

    if ($picturesPath -like "\\*") {
      if ($picturesPath -like "$documentsPath\*") {
        $picturesRedirected = "True: Following Documents folder"
      } else { $picturesRedirected = "True: Not following Documents" }
    } else { $picturesRedirected = $false }

    if ($videosPath -like "\\*") {
      if ($videosPath -like "$documentsPath\*") {
        $videosRedirected = "True: Following Documents folder"
      } else { $videosRedirected = "True: Not following Documents" }
    } else { $videosRedirected = $false }

    if ($musicPath -like "\\*") {
      if ($musicPath -like "$documentsPath\*") {
        $musicRedirected = "True: Following Documents folder"
      } else { $musicRedirected = "True: Not following Documents" }
    } else { $musicRedirected = $false }

    # Show if the user was the last logged in user.
    if ($user -eq $lastLoggedInUser.User -or $user -eq $lastLoggedInUser.SID) {
      $lastLoggedOnUser = $true
    } else {
      $lastLoggedOnUser = $false
    }

    # Build HasFolderRedirection summary
    $redirectedFolders = @()
    if ($desktopRedirected)   { $redirectedFolders += "Desktop" }
    if ($documentsRedirected) { $redirectedFolders += "Documents" }
    if ($picturesRedirected)  { $redirectedFolders += "Pictures" }
    if ($videosRedirected)    { $redirectedFolders += "Videos" }
    if ($musicRedirected)     { $redirectedFolders += "Music" }

    $hasFolderRedirection = if ($redirectedFolders.Count -eq 0) {
      "No"
    } else {
      "Yes: " + ($redirectedFolders -join ", ")
    }

    $results += [PSCustomObject]@{
      User                 = $user
      LastLoggedOnUser     = $lastLoggedOnUser
      Domain               = $domainName
      HasFolderRedirection = $hasFolderRedirection
      PicturesPath         = $picturesPath
      VideosPath           = $videosPath
      MusicPath            = $musicPath
      DesktopPath          = $desktopPath
      DocumentsPath        = $documentsPath
    }
  }
}

# Show the results in the output.
$results

# Final output.
$allFolders = @("Desktop", "Documents", "Pictures", "Videos", "Music")
$complianceOutput = @()

foreach ($entry in $results) {
  $redirected = @()
  if ($entry.DesktopPath   -like "\\*") { $redirected += "Desktop"   }
  if ($entry.DocumentsPath -like "\\*") { $redirected += "Documents" }
  if ($entry.PicturesPath  -like "\\*") { $redirected += "Pictures"  }
  if ($entry.VideosPath    -like "\\*") { $redirected += "Videos"    }
  if ($entry.MusicPath     -like "\\*") { $redirected += "Music"     }

  $missing = $allFolders | Where-Object { $_ -notin $redirected }

  if ($entry.LastLoggedOnUser) {
    if ($missing.Count -eq 0) {
      $status = "Compliant"
    } else {
      $status = "Missing Redirection: " + ($missing -join ", ")
    }
  } else {
    if ($redirected.Count -gt 0) {
      $status = "Non-primary user has redirected folders: " + ($redirected -join ", ")
    } else {
      continue
    }
  }

  $complianceOutput += "User: $($entry.User) | $status"
}

# Set the custom field.
Ninja-Property-Set folderRedirectionAudit $complianceOutput
