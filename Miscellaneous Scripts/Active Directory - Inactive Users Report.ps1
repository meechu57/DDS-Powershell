# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# The default values in the event that nothing is set in the script variables.
$NumberOfDays = 30
$CustomFieldName = "InactiveUsers"

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

# This function is to make it easier to set Ninja Custom Fields.
function Set-NinjaProperty {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True)]
    [String]$Name,
    [Parameter()]
    [String]$Type,
    [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    $Value,
    [Parameter()]
    [String]$DocumentName
  )

  $Characters = $Value | Measure-Object -Character | Select-Object -ExpandProperty Characters
  if ($Characters -ge 10000) {
    throw [System.ArgumentOutOfRangeException]::New("Character limit exceeded, value is greater than 10,000 characters.")
  }
  
  # If we're requested to set the field value for a Ninja document we'll specify it here.
  $DocumentationParams = @{}
  if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }
  
  # This is a list of valid fields that can be set. If no type is given, it will be assumed that the input doesn't need to be changed.
  $ValidFields = "Attachment", "Checkbox", "Date", "Date or Date Time", "Decimal", "Dropdown", "Email", "Integer", "IP Address", "MultiLine", "MultiSelect", "Phone", "Secure", "Text", "Time", "URL", "WYSIWYG"
  if ($Type -and $ValidFields -notcontains $Type) { Write-Warning "$Type is an invalid type! Please check here for valid types. https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" }
  
  # The field below requires additional information to be set
  $NeedsOptions = "Dropdown"
  if ($DocumentName) {
    if ($NeedsOptions -contains $Type) {
      # We'll redirect the error output to the success stream to make it easier to error out if nothing was found or something else went wrong.
      $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
    }
  }
  else {
    if ($NeedsOptions -contains $Type) {
      $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
    }
  }
  
  # If an error is received it will have an exception property, the function will exit with that error information.
  if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }
  
  # The below types require values not typically given in order to be set. The below code will convert whatever we're given into a format ninjarmm-cli supports.
  switch ($Type) {
    "Checkbox" {
      # While it's highly likely we were given a value like "True" or a boolean datatype it's better to be safe than sorry.
      $NinjaValue = [System.Convert]::ToBoolean($Value)
    }
    "Date or Date Time" {
      # Ninjarmm-cli expects the GUID of the option to be selected. Therefore, the given value will be matched with a GUID.
      $Date = (Get-Date $Value).ToUniversalTime()
      $TimeSpan = New-TimeSpan (Get-Date "1970-01-01 00:00:00") $Date
      $NinjaValue = $TimeSpan.TotalSeconds
    }
    "Dropdown" {
      # Ninjarmm-cli is expecting the guid of the option we're trying to select. So we'll match up the value we were given with a guid.
      $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
      $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID

      if (-not $Selection) {
        throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown")
      }

      $NinjaValue = $Selection
    }
    default {
      # All the other types shouldn't require additional work on the input.
      $NinjaValue = $Value
    }
  }
  
  # We'll need to set the field differently depending on if its a field in a Ninja Document or not.
  if ($DocumentName) {
    $CustomField = Ninja-Property-Docs-Set -AttributeName $Name -AttributeValue $NinjaValue @DocumentationParams 2>&1
  }
  else {
    $CustomField = Ninja-Property-Set -Name $Name -Value $NinjaValue 2>&1
  }
  
  if ($CustomField.Exception) {
    throw $CustomField
  }
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
$Today = Get-Date

# Get the script variable if it was set.
if ($env:numberOfDaysToReportOn -and $env:numberOfDaysToReportOn -notlike "null") { $NumberOfDays = $env:numberOfDaysToReportOn }
if ($env:excludeUsers -and $env:excludeUsers -notlike "null") { $excludedUsers = $env:excludeUsers }

Write-Host "Searching for users that have been inactive for $NumberOfDays days or more."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Searching for users that have been inactive for $NumberOfDays days or more."

# Pull the list of excluded users and trim them to an array.
if ($excludedUsers) {
  Write-Host "Ignoring the following users: $excludedUsers"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ignoring the following users: $excludedUsers"
  
  $excludedUsers = $excludedUsers.Trim()
  $excludedUsers = $excludedUsers.TrimEnd(',')
  $excludedUsers = $excludedUsers -split ","
  $excludedUsers = $excludedUsers.Trim()
}

# Filter through all users, excluding the excluded users, and find all users that are not active or have logged in in the last x days.
if ($excludedUsers) {
  $Users = Get-ADUser -Filter {SamAccountName -ne "ddsadmin"} -Properties SamAccountName, UserPrincipalName, LastLogonDate | Where {$excludedUsers -notcontains $_.SamAccountName}
  $ActiveUsers = Get-ADUser -Filter { LastLogonDate -ge 0  -and SamAccountName -ne "ddsadmin" } -Properties SamAccountName, UserPrincipalName, LastLogonDate |
    Where-Object { (New-TimeSpan $_.LastLogonDate $Today).Days -le $NumberOfDays } | Where {$excludedUsers -notcontains $_.SamAccountName} |
    Select-Object SamAccountName, UserPrincipalName, LastLogonDate
    
  $InactiveUsers = @()
  
  # If the user in $Users is in ActiveUsers, ignore it. Otherwise, add it to InactiveUsers.
  foreach ($user in $Users) {
    $active = $false
    
    foreach($activeUser in $ActiveUsers) {
      if ($activeUser.SamAccountName -eq $user.SamAccountName ){
        $active = $true
        break
      }
    }
    
    if (-not $active) {
      $InactiveUsers += $user
    }
  }
  
  $InactiveUsers = $InactiveUsers | Select-Object SamAccountName, UserPrincipalName, LastLogonDate
} else {
  # This is the same process as above, minus the filtering for excluded users.
  $Users = Get-ADUser -Filter {SamAccountName -ne "ddsadmin"} -Properties SamAccountName, UserPrincipalName, LastLogonDate
  $ActiveUsers = Get-ADUser -Filter { LastLogonDate -ge 0  -and SamAccountName -ne "ddsadmin" } -Properties SamAccountName, UserPrincipalName, LastLogonDate |
    Where-Object { (New-TimeSpan $_.LastLogonDate $Today).Days -le $NumberOfDays } |
    Select-Object SamAccountName, UserPrincipalName, LastLogonDate
    
  $InactiveUsers = @()
  
  # If the user in $Users is in ActiveUsers, ignore it. Otherwise, add it to InactiveUsers.  
  foreach ($user in $Users) {
    $active = $false
    
    foreach($activeUser in $ActiveUsers) {
      if ($activeUser.SamAccountName -eq $user.SamAccountName ){
        $active = $true
        break
      }
    }
    
    if (-not $active) {
      $InactiveUsers += $user
    }
  }

  $InactiveUsers = $InactiveUsers | Select-Object SamAccountName, UserPrincipalName, LastLogonDate
}

# Creating a generic list to start assembling the report
$Report = New-Object System.Collections.Generic.List[string]

# Actual report assembly each section will be print on its own line
$Report.Add("Inactive users: $(($InactiveUsers | Measure-Object).Count)")
$Report.Add("Total users: $(($Users | Measure-Object).Count)")
$Report.Add("Percent Inactive: $(if((($Users | Measure-Object).Count) -gt 0){[Math]::Round(($InactiveUsers | Measure-Object).Count / (($Users | Measure-Object).Count) * 100, 2)}else{0})%")

# Set's up table to use in the report
$Report.Add($($InactiveUsers | Format-Table | Out-String))

if ($InactiveUsers) {
  # Exports report to activity log
  $Report | Write-Host
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $Report"

  if ($CustomFieldName) {
    # Saves report to custom field.
    try {
      Set-NinjaProperty -Name $CustomFieldName -Value $($InactiveUsers | ConvertTo-Html -Fragment | Out-String)
    }
    catch {
      # If we ran into some sort of error we'll output it here.
      Write-Error -Message $_.ToString() -Category InvalidOperation -Exception (New-Object System.Exception)
      exit 1
    }
  }
}
else {
  Write-Error "No inactive users found!"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No inactive users found!"
  
  exit 1
}