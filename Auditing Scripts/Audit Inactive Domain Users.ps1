# The log path for this script.
$logPath = "C:\DDS\Logs\Audit.log"

# Tests for administrative rights which is required to get the last logon date.
function Test-IsElevated {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object System.Security.Principal.WindowsPrincipal($id)
  $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Tests if the device the script is running on is a dmona controller.
function Test-IsDomainController {
  return $(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2
}

# Erroring out when ran without administrator rights
if (-not (Test-IsElevated)) {
  Write-Error -Message "Access Denied. Please run with Administrator privileges."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Access Denied. Please run with Administrator privileges."
  
  exit 1
}

# Erroring out when ran on a non-domain controller
if (-not (Test-IsDomainController)) {
  Write-Error -Message "The script needs to be run on a domain controller!"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The script needs to be run on a domain controller!"
  
  exit 1
}

# Check that Active Directory module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
  Write-Host "Active Directory module is not available. Please install it and try again."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Active Directory module is not available. Please install it and try again."
  
  exit 1
}

Write-Host "Auditing inactive domain users..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing inactive domain users..."

# Todays date
$today = Get-Date

# Number of days that we determine to be the max age of a user account before it's inactive.
$numberOfDays = 30

# Max age that the user can be before being considered inactive in date format.
$maxAge = (Get-Date).AddDays(-$numberOfDays)

# Get any currently excluded user from the inactiveUserOverride custom field
$currentExcludedUsers = Ninja-Property-Get inactiveUserOverride

# If there's users that were excluded, sort them into custom variables and decrement the number of days by 30.
if ($currentExcludedUsers -ne $null) {
  # Arrays for sorting
  $initialArray = $currentExcludedUsers -split ', '
  $userArray = @()
  
  # Sort the  input into an array made from Custom Objects
  foreach ($input in $initialArray) {
    $userParts = $input -split '-'
  
    $user = [PSCustomObject]@{
      Name   = $userParts[0]
      Days = [int]$userParts[1]
    }
  
    $userArray += $user
  }
  
  # Decrement the Days count by 30. If the count reaches 0, remove them from the inactiveUserOverride custom field and make sure the script audits the user.
  foreach ($user in $userArray) {
    $user.Days = $user.Days - 30
    # Alert that the user was removed from the inactiveUserOverride custom field
    if ($user.Days -le 0) {
      Write-Host "The $($user.Name) user's Inactive User Override has expired. If this user gets flagged as inactive below, please note that it was previously added to the Inactive User Override custom field."
    }
  }
  
  # Get all users that have a day count over 0.
  $userArray = $userArray | Where-Object { $_.Days -gt 0 }
  
  # Join the $userArray into a single string and set the value back into the inactiveUserOverride custom field
  $overrideOutput = ($userArray | ForEach-Object { "$($_.Name)-$($_.Days)" }) -join ', '
  Ninja-Property-Set inactiveUserOverride $overrideOutput
  
  # Join just the names from the $userArray for the $excludedUsers variable
  $nameOnlyOutput = ($userArray | ForEach-Object { $_.Name }) -join ', '
  
  # List of users to exclude from the search
  $excludedUsers = "ddsadmin, administrator, Sikkauser, sidexis4service, Guest, krbtgt, $nameOnlyOutput" 
} else {
  # List of users to exclude from the search
  $excludedUsers = "ddsadmin, administrator, Sikkauser, sidexis4service, Guest, krbtgt"
}

# Pull the list of excluded users and trim them to an array.
if ($excludedUsers) {
  Write-Host "Ignoring the following users: $excludedUsers"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ignoring the following users: $excludedUsers"
}

# Filter through all users, excluding the excluded users, and add the users that haven't logged in for 30 days to the inactive users list.
if ($excludedUsers) {
  $users = Get-ADUser -Filter {SamAccountName -ne "administrator"} -Properties SamAccountName, UserPrincipalName, LastLogonDate | Where {$excludedUsers -notcontains $_.SamAccountName}

  $inactiveUsers = @()
  
  foreach ($user in $users) {
    if ($user.LastLogonDate -eq $null) {
      $inactiveUsers += $user
    } elseif ($user.LastLogonDate -le $maxAge) {
      $inactiveUsers += $user
    }
  }
  
  # $inactiveUsers | Select-Object SamAccountName, UserPrincipalName, LastLogonDate
} 

# Convert the script variable to a local variable.
$disableUsers = $env:disableInactiveUsers
# Initialize the arrays for reporting. 
$users30Day = @()
$users60Day = @()
$usersAlreadyDisabled = @()

# Check to make sure there's inactive users for reporting.
if ($inactiveUsers.Count -gt 0) {
  foreach ($user in $inactiveUsers) {
    # Add the user to this group if it was already disabled before this script ran.
    if ($user.Enabled -eq $false) {
      $usersAlreadyDisabled += $user.SamAccountName
    }
    
    # Disable the user if the option was selected.
    if ($disableUsers -eq $true -and $user.Enabled -eq $true) {
      Write-Host "Disabling the $($user.SamAccountName) user account..."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Disabling the $($user.SamAccountName) user account..."
      $user | Disable-ADAccount
    }
    
    # Sort each inactive user into the two categories.
    if ($user.LastLogonDate) {
      $daysInactive = ($today - $user.LastLogonDate).Days
  
      if ($daysInactive -ge 30 -and $daysInactive -lt 60) {
        $users30Day += $user.SamAccountName
      }
      elseif ($daysInactive -ge 60) {
        $users60Day += $user.SamAccountName
      }
    } else {
      # LastLogonDate is null
      $users60Day += $user.SamAccountName
    }
  }
  # Join the arrays into strings.
  $users30Day = $users30Day -join ", "
  $users60Day = $users60Day -join ", "
  $usersAlreadyDisabled = $usersAlreadyDisabled -join ", "
  
  if ($usersAlreadyDisabled -ne "") {
    Write-Host "The following users were already disabled before this script ran: $usersAlreadyDisabled"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The following users were already disabled before this script ran: $usersAlreadyDisabled"
  }
  
  if ($users30Day -ne "") {
    Write-Host "The following users have been inactive for over 30 days: $users30Day"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The following users have been inactive for over 30 days: $users30Day"
  }
  
  if ($users60Day -ne "") {
    Write-Host "The following users have been inactive for over 60 days: $users60Day"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The following users have been inactive for over 60 days: $users60Day"
  }
} else {
  Write-Host "No inactive user accounts were found!"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No inactive user accounts were found!"
  
  exit 2
}
