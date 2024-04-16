# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Converts the script variable to local variables for easier readability.
$password = $env:password
$isAdmin = $env:setAsAnAdministrator
$username = $env:accountName

# Function to check if a user exists
function UserExists() {
  param ([string]$Name)
  
  # Get all enabled users
  $users = Get-LocalUser | Where-Object { $_.Enabled -eq $true}
  
  # Go through all enabled users and return true if the user's name is the same as the name passed through by the paramater
  foreach ($user in $users) {
    if ($user.Name -eq $Name) {
      Write-Host "The user $Name exists."
      
      return $true
    }
  }
  
  Write-Host "The user $Name doesn't exist."
  
  return $false
}

# Function to create a user, set password, and add the user to the 'Administrators' group
function CreateUser() {
  param ([string]$Name, [string]$Password, [boolean]$Admin)
  
  # Converts the plain text password to a secure string
  $newPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    
  Write-Host "User '$name' created."
  
 
  if ($Admin) {
    # Create a local user with the username and password from the paramaters
    New-LocalUser -Name $name -Password $newPassword -Description "DDS Integration local admin"
    
    # If the paramater was set, this will add the user to the 'Administrators' group
    Add-LocalGroupMember -Group "Administrators" -Member $name

    Write-Host "User '$name' added to the Administrators group."
  } else {
    # Create a local user with the username and password from the paramaters
    New-LocalUser -Name $name -Password $newPassword -Description "DDS Integration local user"
  }
}

# Function to change the password of an existing user
function ChangePassword() {
  param ([string]$Name, [string]$Password)
  
  # Converts the plain text password to a secure string
  $newPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
  
  # Changes the password of the local user
  Set-LocalUser -Name $Name -Password $newPassword

  Write-Host "Changed the password for user '$Name'."
}

# Sets the username to 'Admin' or the custom username depending on the "Account Name" env variable
if ($username -eq "Admin" -or $username -eq "admin"){
  Write-Host "Username set to $username"
}else{
  $username = $env:otherUsername
  Write-Host "Username set to $username"
}

Write-Host "Creating a local user with name $username..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Creating a local user with name $username..."

# If the user exists, change the password. If the user doesn't exist, create the user.
if (UserExists -Name $username) {
  ChangePassword -Name $username -Password $password
  
  Write-Host "The user $username already exists. Updating the user's password."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The user $username already exists. Updating the user's password."
} 
else {
  if ($isAdmin -eq $true) {
    CreateUser -Name $username -Password $password -Admin $true
    
    Write-Host "Created a new local user, $username, and added the user to the Administrators group."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Created a new local user, $username, and added the user to the Administrators group."
  } else {
    CreateUser -Name $username -Password $password -Admin $false
    
    Write-Host "Created a new local user, $username. The user was not added to the Administrators group."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Created a new local user, $username. The user was not added to the Administrators group."
  }
}
