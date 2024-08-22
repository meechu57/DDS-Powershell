# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

function Test-IsElevated {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object System.Security.Principal.WindowsPrincipal($id)
  $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check that the script is going to run with correct permissions
if (-not (Test-IsElevated)) {
  Write-Host "Access Denied. Please run with Administrator privileges."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Access Denied. Please run with Administrator privileges."
  
  exit 1
}

# Check that Active Directory module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
  Write-Host "Active Directory module is not available. Please install it and try again."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Active Directory module is not available. Please install it and try again."
  
  exit 1
}

# Convert the script variable to a local variable and trim the end
$userNames = $env:adUsers
$userNames = $userNames.Trim()
$userNames = $userNames.TrimEnd(',')

# For error tracking
$errors = 0

Write-Host "Attempting to remove the following Active Directory user(s): $userNames"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to remove the following Active Directory user(s): $userNames"

# Convert to an array
$userNames = $userNames -split ',\s*'

# Go through each user and attempt to remove them.
foreach ($name in $userNames) {
  # Check to make sure that user exists.
  $user = Get-ADUser -Filter { SamAccountName -eq $name} -ErrorAction SilentlyContinue
  
  if ($user) {
    Write-Host "Attempting to remove the following Active Directory user: $name"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to remove the following Active Directory user: $name"
    
    # Try to remove the user. Exit if an error occurred.
    try {
      Remove-ADUser -Identity $name -confirm:$false
      
      Write-Host "Successfully removed the $name user."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully removed the $name user."
    } catch {
      Write-Host "An error occurred when trying to remove the $name user: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to remove the $name user: $_"
      
      exit 1
    }
  } else {
    Write-Host "The user $name could not be found. The user was not removed from Active Directory."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The user $name could not be found. The user was not removed from Active Directory."
    
    $errors++
  }
}

# Show any errors. 
if ($errors -eq 0) {
  Write-Host "All requested Active Directory users were successfully removed."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All requested Active Directory users were successfully removed."
} else {
  Write-Host "$errors user(s) was not removed from Active Directory. Manual investigation required."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $errors user(s) was not removed from Active Directory. Manual investigation required."
  
  exit 1
}