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
$computerNames = $env:adComputers
$computerNames = $computerNames.Trim()
$computerNames = $computerNames.TrimEnd(',')

# For error tracking
$errors = 0

Write-Host "Attempting to remove the following Active Directory computer(s): $computerNames"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Attempting to remove the following Active Directory computer(s): $computerNames"

# Convert to an array
$computerNames = $computerNames -split ',\s*'

# Get the current domain
$Domain = "DC=$(
    $(Get-CimInstance Win32_ComputerSystem).Domain -split "\." -join ",DC="
  )"

# Go through each computer that was input and try to remove it.
foreach ($name in $computerNames) {
  # For Splatting parameters into Get-ADComputer
  $GetComputerSplat = @{
    Property   = "Name"
    Filter     = { (Enabled -eq "true") -and (Name -eq $name) }
    SearchBase = $Domain
  }
  
  # Check to make sure the computer exists
  $computer = Get-ADComputer @GetComputerSplat -ErrorAction SilentlyContinue
  
  if ($computer) {
    # Try to remove the computer. Exit if there was an error removing it.
    try {
      Remove-ADComputer -Identity $name -Confirm:$false
      
      Write-Host "Successfully removed the $name computer."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully removed the $name computer."
    } catch {
      Write-Host "An error occurred when trying to remove the $name computer: $_"
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to remove the $name computer: $_"
      
      exit 1
    }
  } else {
    Write-Host "The computer $name could not be found. The computer was not removed from Active Directory."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The computer $name could not be found. The computer was not removed from Active Directory."
    
    $errors++
  }
}

# Show any errors. 
if ($errors -eq 0) {
  Write-Host "All requested Active Directory computers were successfully removed."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All requested Active Directory computers were successfully removed."
} else {
  Write-Host "$errors computers(s) was not removed from Active Directory. Manual investigation required."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $errors computers(s) was not removed from Active Directory. Manual investigation required."
  
  exit 1
}