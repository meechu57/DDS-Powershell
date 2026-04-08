# These will pull from script variables.
$officeOUName = "TestingOU"
$password = ConvertTo-SecureString -String "password123" -AsPlainText -Force

# Initial check for our OUs and ddsadmin user.
$domain = ((Get-CimInstance Win32_ComputerSystem).Domain) -split '\.'
$OUs = try { Get-ADOrganizationalUnit -Filter * -Properties Name, DistinguishedName } catch {}
$ddsOU = try { Get-ADOrganizationalUnit -Filter * -Properties Name, DistinguishedName | Where-Object {$_.name -like "*DDS*"} } catch {}
$officeOU = try {Get-ADOrganizationalUnit -Identity "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])"} catch {}
$ddsadminUser = Get-ADUser -Filter * -Properties * | Where-Object {$_.SamAccountName -eq "DDSADMIN"}

# If a DDS Users OU doesn't exist, create one.
if (-not $ddsOU) {
    Write-Host "Creating the DDS Users OU..."
    try { New-ADOrganizationalUnit -Name "DDS Users" -Path "DC=$($domain[0]),DC=$($domain[1])" } catch {}
} else { Write-Host "A DDS OU already exists." }

# If there's no ddsadmin domain user, create one.
if (-not $ddsadminUser) {
    Write-Host "Creating the ddsadmin domain user..."
    
    # All the user details.
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

    # Create the user.
    try { New-ADUser @splat } catch {}
    
    # Add the user to the domain admins and administrators users.
    try {
        Add-ADGroupMember -Identity "domain admins" -Members "ddsadmin"
        Add-ADGroupMember -Identity "administrators" -Members "ddsadmin"
    } catch {}
} else { # If the user already exists, check to make sure it's in the proper OU and that it has the proper roles.
    Write-Host "A ddsadmin user already exists." 

    try {
        if (-not ($ddsadminUser.MemberOf -like "*domain admins*")) {
            Write-Host "Adding the ddsadmin user to the domain admins group..." 
            Add-ADGroupMember -Identity "domain admins" -Members "ddsadmin"
        }
        if (-not ($ddsadminUser.MemberOf -like "*administrators*")) {
            Write-Host "Adding the ddsadmin user to the administrators group..." 
            Add-ADGroupMember -Identity "administrators" -Members "ddsadmin"
        }
        if (-not ($ddsadminUser.DistinguishedName -like "*OU=$($ddsOU.Name)*")) 
            Write-Host "Moving the ddsadmin user to the DDS Users OU..." 
            Move-ADObject -Identity $ddsadminUser.DistinguishedName -TargetPath $ddsOU.DistinguishedName
        }
    } catch {}
}

# If there is no offie specific OU, create one.
if (-not $officeOU) {
    Write-Host "Creating the $officeOUName OU..."
    # Create the OU and the Users/Computers sub OUs.
    try {
        New-ADOrganizationalUnit -Name $officeOUName -Path "DC=$($domain[0]),DC=$($domain[1])"
        New-ADOrganizationalUnit -Name "Computers" -Path "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])"
        New-ADOrganizationalUnit -Name "Users" -Path "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])"
    } catch {}
} else { # If the OU already exists, check the ensure that the Users/Computers sub OUs exist.
    $subOUs = try { Get-ADOrganizationalUnit -Filter * -SearchBase "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])" -SearchScope OneLevel } catch {}
    try {
        if ($subOUs.name -notcontains "Users") { New-ADOrganizationalUnit -Name "Users" -Path "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])" }
        if ($subOUs.name -notcontains "Computers") { New-ADOrganizationalUnit -Name "Computers" -Path "OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])" }
    } catch {}
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

# Move each active user to the office's OU.
foreach ($user in $users) {
    Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=Users,OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])"
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

# Move each computers user to the office's OU.
foreach ($computer in $computers) {
    Move-ADObject -Identity $computer.DistinguishedName -TargetPath "OU=Computers,OU=$officeOUName,DC=$($domain[0]),DC=$($domain[1])"
}