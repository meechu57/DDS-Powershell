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

# Todays date
$today = Get-Date

# Number of days that we determine to be the max age of a user account before it's inactive.
$numberOfDays = 30

# Max age that the user can be before being considered inactive in date format.
$maxAge = (Get-Date).AddDays(-$numberOfDays)

# List of users to exclude from the search
$excludedUsers = "ddsadmin, administrator, Sikkauser, sidexis4service"

# Pull the list of excluded users and trim them to an array.
if ($excludedUsers) {
  Write-Host "Ignoring the following users: $excludedUsers"
  
  $excludedUsers = $excludedUsers.Trim()
  $excludedUsers = $excludedUsers.TrimEnd(',')
  $excludedUsers = $excludedUsers -split ","
  $excludedUsers = $excludedUsers.Trim()
}

# Filter through all users, excluding the excluded users, and find all users that are not active or have logged in in the last x days.
if ($excludedUsers) {
  $users = Get-ADUser -Filter {SamAccountName -ne "administrator"} -Properties SamAccountName, UserPrincipalName, LastLogonDate | Where {$excludedUsers -notcontains $_.SamAccountName}
    
  $inactiveUsers = @()
  
  foreach ($user in $users) {
    if ($user.LastLogonDate -eq $null) {
        Write-Host "$($user.SamAccountName) has not logged in yet"
        $inactiveUsers += $user
    } elseif ($user.LastLogonDate -le $maxAge) {
        $inactiveUsers += $user
    }
  }
  
  $inactiveUsers | Select-Object SamAccountName, UserPrincipalName, LastLogonDate
} 

# Creating a generic list to start assembling the report
$Report = New-Object System.Collections.Generic.List[string]

# Actual report assembly each section will be print on its own line
$Report.Add("Inactive users: $(($inactiveUsers | Measure-Object).Count)")
$Report.Add("Total users: $(($users | Measure-Object).Count)")
$Report.Add("Percent Inactive: $(if((($users | Measure-Object).Count) -gt 0){[Math]::Round(($inactiveUsers | Measure-Object).Count / (($users | Measure-Object).Count) * 100, 2)}else{0})%")

# Set's up table to use in the report
$Report.Add($($inactiveUsers | Format-Table | Out-String))

if ($InactiveUsers) {
  # Exports report to activity log
  $Report | Write-Host
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $Report"
}
else {
  Write-Error "No inactive users found!"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No inactive users found!"
  
  exit 1
}