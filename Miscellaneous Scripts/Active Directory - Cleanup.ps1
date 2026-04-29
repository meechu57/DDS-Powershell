# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Tests if the device the script is running on is a dmona controller.
function Test-IsDomainController {
  return $(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2
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

# Convert the script variables to local variables.
$officeOUName = $env:officeOuName
$ddsadminPassword = $env:ddsadminPassword

# Convert the plain text password to a secure string.
$password = ConvertTo-SecureString -String $ddsadminPassword -AsPlainText -Force

# Pull all the initial information.
$domain = ((Get-CimInstance Win32_ComputerSystem).Domain) -split '\.'
$OUs = try { Get-ADOrganizationalUnit -Filter * -Properties Name, DistinguishedName } catch {}
$ddsOU = try { Get-ADOrganizationalUnit -Filter * -Properties Name, DistinguishedName | Where-Object {$_.name -like "*DDS*"} } catch {}
$officeOU = try {Get-ADOrganizationalUnit -Identity "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])"} catch {}
$ddsadminUser = Get-ADUser -Filter * -Properties * | Where-Object {$_.SamAccountName -eq "DDSADMIN"}

# Create the DDS Users OU if it doesn't exist.
if (-not $ddsOU) {
  Write-Host "Creating the 'DDS Users' OU..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Creating the 'DDS Users' OU..."

  try {
    New-ADOrganizationalUnit -Name "DDS Users" -Path "DC=$($domain[0]),DC=$($domain[1])"
  } catch {
    Write-Host "An error occurred when trying to create the 'DDS Users' OU: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to create the 'DDS Users' OU: $_"
  }
} else { 
  Write-Host "A 'DDS' OU already exists." 
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A 'DDS' OU already exists."
}

# Create the ddsadmin domain user if it doesn't exist. Also checks to make sure the correct roles are in place and that the user is in the DDS OU.
if (-not $ddsadminUser) {
  Write-Host "Creating the 'ddsadmin' domain user..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Creating the 'ddsadmin' domain user..."
  
  # Get the DDS OU pathway again in the event one didn't previously exist.
  $ddsOU = try { Get-ADOrganizationalUnit -Filter * -Properties Name, DistinguishedName | Where-Object {$_.name -like "*DDS*"} } catch {}
  
  # All the information needed to create the user.
  $splat = @{
    Name = "ddsadmin"
    SamAccountName = "ddsadmin"
    DisplayName = "ddsadmin"
    Description = "DDS Integration Domain Administrator"
    AccountPassword = $password
    PasswordNeverExpires = $true
    Enabled = $true
    Path = $ddsOU.DistinguishedName
  }
  
  try {
    New-ADUser @splat
    Add-ADGroupMember -Identity "domain admins" -Members "ddsadmin"
    Add-ADGroupMember -Identity "administrators" -Members "ddsadmin" 
  } catch {
    Write-Host "An error occurred when trying to create the 'ddsadmin' domain user: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to create the 'ddsadmin' domain user: $_"
  }
} else { 
  # If the user already exists, check the roles, where its located, and fix anything that's not correct.
  Write-Host "A 'ddsadmin' user already exists." 
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A 'ddsadmin' user already exists."

  # Update the password if requested.
  if ($env:updateDdsadminPassword -eq $true) {
    try {
      Set-ADAccountPassword -Identity $ddsadminUser.DistinguishedName -Reset -NewPassword $password
    } catch {
      Write-Host "An error occurred when trying to change the password of the ddsadmin user: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to change the password of the ddsadmin user: $_"
    }
  } 
  
  # Make sure the ddsadmin user is a domain administrator and regular administrator.
  try {
    if (-not ($ddsadminUser.MemberOf -like "*domain admins*")) { Add-ADGroupMember -Identity "domain admins" -Members "ddsadmin" }
    if (-not ($ddsadminUser.MemberOf -like "*administrators*")) { Add-ADGroupMember -Identity "administrators" -Members "ddsadmin" }
  } catch {
    Write-Host "An error occurred when trying to add the 'ddsadmin' domain user as a member of the 'Domain Admins' or 'Administrators' security groups: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to add the 'ddsadmin' domain user as a member of the 'Domain Admins' or 'Administrators' security groups: $_"
  }
  
  # Moves the ddsadmin user to the DDS OU.
  try {
    if (-not ($ddsadminUser.DistinguishedName -like "*OU=$($ddsOU.Name)*")) { Move-ADObject -Identity $ddsadminUser.DistinguishedName -TargetPath $ddsOU.DistinguishedName } 
  } catch {
    Write-Host "An error occurred when trying to move the 'ddsadmin' domain user to the $($ddsOU.Name) OU: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to move the 'ddsadmin' domain user to the $($ddsOU.Name) OU: $_"
  }
}

# Creates the office's OU and sub OUs if they don't exist.
if (-not $officeOU) {
  Write-Host "Creating the '$officeOUName' OU and sub OUs..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Creating the '$officeOUName' OU and sub OUs..."
  try {
    New-ADOrganizationalUnit -Name $officeOUName -Path "DC=$($domain[0]),DC=$($domain[1])"
    New-ADOrganizationalUnit -Name "Computers" -Path "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])"
    New-ADOrganizationalUnit -Name "Users" -Path "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])" 
  } catch {
    Write-Host "An error occurred when creating the '$officeOUName' OU and sub OUs: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when creating the '$officeOUName 'OU and sub OUs: $_"
  }
} else { 
  $subOUs = Get-ADOrganizationalUnit -Filter * -SearchBase "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])" -SearchScope OneLevel

  try {
    if ($subOUs.name -notcontains "Users") { New-ADOrganizationalUnit -Name "Users" -Path "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])" }
    if ($subOUs.name -notcontains "Computers") { New-ADOrganizationalUnit -Name "Computers" -Path "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])" } 
  } catch {
    Write-Host "An error occurred when creating the '$officeOUName' sub OUs: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when creating the '$officeOUName' sub OUs: $_"
  }
}

# Todays date.
$today = Get-Date

# Maximum age of the user's last login before the user is flagged as inactive.
$maxAge = (Get-Date).AddDays(-90)

# List of users to exclude from the search.
$excludedUsers = "ddsadmin, Sikkauser, sidexis4service, DefaultAccount, krbtgt"
# Convert the string to an array.
$excludedUsers = $excludedUsers -split ', '

# Get all current users, excluding users in $excludedUsers.
$users = Get-ADUser -Filter * -Properties * | Where-Object {$_.Description -notlike "Built-in*"} | Where {$excludedUsers -notcontains $_.SamAccountName} | Where-Object {$_.SamAccountName -notlike "QBDataService*"}
# Initialize the array for active & inactive users.
$activeUsers = @()
$inactiveUsers = @()

# Sort the users between active and inactive.
foreach ($user in $users) {
  if ($user.LastLogonDate -ne $null -and $user.LastLogonDate -gt $maxAge) {
    $activeUsers += $user
  } else {
    $inactiveUsers += $user
  }
}

# Move each active user to the office's OU. To-Do: Change $users to $activeUsers
Write-Host "Moving the following users to the '$officeOUName' 'Users' OU: $($users.Name)"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Moving the following users to the '$officeOUName' 'Users' OU: $users"
foreach ($user in $users) { 
  try {
    Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=Users,OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])"  
  } catch {
    Write-Host "An error occurred when moving the '$user' user to the '$officeOUName' 'Users' OU: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when moving the '$user' user to the '$officeOUName' 'Users' OU: $_"
  }
}

# Get all current computers.
$computers = Get-ADComputer -Filter * -Properties * | Where-Object {$_.DistinguishedName -notlike "*OU=Domain Controllers*"}
# Initialize the array for active & inactive computers.
$activeComputers = @()
$inactiveComputers = @()

# Sort the computers between active and inactive.
foreach ($computer in $computers) {
  if ($computer.LastLogonDate -ne $null -and $computer.LastLogonDate -gt $maxAge) {
    $activeComputers += $computer
  } else {
    $inactiveComputers += $computer
  }
}

# Move each computers user to the office's OU. To-Do: Change $computers to $activeComputers
Write-Host "Moving the following computers to the '$officeOUName' 'Computers' OU: $($computers.Name)"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Moving the following computers to the '$officeOUName' 'Computers' OU: $activeComputers"
foreach ($computer in $computers) { 
  try {
    Move-ADObject -Identity $computer.DistinguishedName -TargetPath "OU=Computers,OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])"   
  } catch {
    Write-Host "An error occurred when moving the '$computer' user to the '$officeOUName' 'Computers' OU: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when moving the '$computer' user to the '$officeOUName' 'Computers' OU: $_"
  }
}