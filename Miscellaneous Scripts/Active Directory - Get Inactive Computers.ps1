# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# The default values in the event that nothing is set in the script variables.
$InactiveDays = 30
$CustomFieldName = "InactiveComputers"
  
function Test-IsElevated {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object System.Security.Principal.WindowsPrincipal($id)
  $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

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

# Tests if the device the script is running on is a dmona controller.
function Test-IsDomainController {
  return $(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2
}

# Check that the script is going to run with correct permissions
if (-not (Test-IsElevated)) {
  Write-Host "Access Denied. Please run with Administrator privileges."
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

# Get Script Variables and override parameters with them
if ($env:inactiveDays -and $env:inactiveDays -notlike "null") { $InactiveDays = $env:inactiveDays }
if ($env:excludeComputers -and $env:excludeComputers -notlike "null") { $excludedComputers = $env:excludeComputers }

# Pull the list of excluded computers and trim them to an array.
if ($excludedComputers) {
  Write-Host "Ignoring the following computers: $excludedComputers"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Ignoring the following computers: $excludedComputers"
  
  $excludedComputers = $excludedComputers.Trim()
  $excludedComputers = $excludedComputers.TrimEnd(',')
  $excludedComputers = $excludedComputers -split ","
  $excludedComputers = $excludedComputers.Trim()
}

# Get the date in the past $InactiveDays days
$InactiveDate = (Get-Date).AddDays(-$InactiveDays)
# Get the SearchBase for the domain
$Domain = "DC=$(
  $(Get-CimInstance Win32_ComputerSystem).Domain -split "\." -join ",DC="
)"

Write-Host "Searching for computers that are inactive for $InactiveDays days or more."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Searching for computers that are inactive for $InactiveDays days or more."

# For Splatting parameters into Get-ADComputer
$GetComputerSplat = @{
  Property   = "Name", "LastLogonTimeStamp", "OperatingSystem"
  # LastLogonTimeStamp is converted to a DateTime object from the Get-ADComputer cmdlet
  Filter     = { (Enabled -eq "true") -and (LastLogonTimeStamp -le $InactiveDate) }
  SearchBase = $Domain
}

if ($excludedComputers) {
  # Get inactive computers that are not active in the past $InactiveDays days
  $InactiveComputers = Get-ADComputer @GetComputerSplat | Select-Object "Name", @{
    # Format the LastLogonTimeStamp property to a human-readable date
    Name       = "LastLogon"
    Expression = {
      if ($_.LastLogonTimeStamp -gt 0) {
        # Convert LastLogonTimeStamp to a datetime
        $lastLogon = [DateTime]::FromFileTime($_.LastLogonTimeStamp)
        # Format the datetime
        $lastLogonFormatted = $lastLogon.ToString("MM/dd/yyyy hh:mm:ss tt")
        return $lastLogonFormatted
      }
      else {
        return "01/01/1601 00:00:00 AM"
      }
    }
  }, "OperatingSystem" | Where {$excludedComputers -notcontains $_.Name}
} else {
  # Get inactive computers that are not active in the past $InactiveDays days
  $InactiveComputers = Get-ADComputer @GetComputerSplat | Select-Object "Name", @{
    # Format the LastLogonTimeStamp property to a human-readable date
    Name       = "LastLogon"
    Expression = {
      if ($_.LastLogonTimeStamp -gt 0) {
        # Convert LastLogonTimeStamp to a datetime
        $lastLogon = [DateTime]::FromFileTime($_.LastLogonTimeStamp)
        # Format the datetime
        $lastLogonFormatted = $lastLogon.ToString("MM/dd/yyyy hh:mm:ss tt")
        return $lastLogonFormatted
      }
      else {
        return "01/01/1601 00:00:00 AM"
      }
    }
  }, "OperatingSystem"
}

# Get all of the computers on the domain.
$computers = Get-ADComputer -filter *

# Creating a generic list to start assembling the report
$Report = New-Object System.Collections.Generic.List[string]

# Actual report assembly each section will be print on its own line
$Report.Add("Inactive computers: $(($InactiveComputers | Measure-Object).Count)")
$Report.Add("Total computers: $(($computers | Measure-Object).Count)")
$Report.Add("Percent Inactive: $(if((($computers | Measure-Object).Count) -gt 0){[Math]::Round(($InactiveComputers | Measure-Object).Count / (($computers | Measure-Object).Count) * 100, 2)}else{0})%")

# Set's up table to use in the report
$Report.Add($($InactiveComputers | Format-Table | Out-String))

if ($InactiveComputers) {
  # Exports report to activity log
  $Report | Write-Host
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $Report"

  if ($CustomFieldName) {
    # Saves report to custom field.
    try {
      Set-NinjaProperty -Name $CustomFieldName -Value $($InactiveComputers | ConvertTo-Html -Fragment | Out-String)
    }
    catch {
      # If we ran into some sort of error we'll output it here.
      Write-Error -Message $_.ToString() -Category InvalidOperation -Exception (New-Object System.Exception)
      exit 1
    }
  }
}
else {
  Write-Error "No inactive computers found!"
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") No inactive computers found!"
  
  exit 1
}