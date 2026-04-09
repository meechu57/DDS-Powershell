# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

Write-Host "Auditing the Forest and Domain Functional  Levels..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing the Forest and Domain Functional  Levels..."

# Obtain Active Directory Schema version and translate it to the corresponding Windows Server version. Also add the expected Forest & Domain levels.
$ADVer = (Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion | Select-Object objectVersion) -replace "@{objectVersion=", "" -replace "}", ""
switch ($ADVer) {
  '91' { $os = 'Windows Server 2025'; $expected = "Windows Server 2025" }
  '88' { $os = 'Windows Server 2019/2022'; $expected = "Windows Server 2016" }
  '87' { $os = 'Windows Server 2016'; $expected = "Windows Server 2016" }
  '69' { $os = 'Windows Server 2012 R2'; $expected = "Windows Server 2012 R2" }
  '56' { $os = 'Windows Server 2012'; $expected = "Windows Server 2012" }
}

# Get the current Forest Functional Level and make the text more readable. 
$ADForestMode = (Get-ADForest).ForestMode
switch ($ADForestMode) {
  'Windows2025Forest' { $forest = "Windows Server 2025" }
  'Windows2016Forest' { $forest = "Windows Server 2016" }
  'Windows2012R2Forest' { $forest = "Windows Server 2012 R2" }
  'Windows2012Forest' { $forest = "Windows Server 2012" }
  'Windows2008R2Forest' { $forest = "Windows Server 2008 R2" }
  'Windows2008Forest' { $forest = "Windows Server 2008" }
  'Windows2003Forest' { $forest = "Windows Server 2003" }
}

# Get the current Domain Functional Level and make the text more readable.
$ADDomainMode = (Get-ADDomain).DomainMode
switch ($ADDomainMode) {
  'Windows2025Domain' { $domain = "Windows Server 2025" }
  'Windows2016Domain' { $domain = "Windows Server 2016" }
  'Windows2012R2Domain' { $domain = "Windows Server 2012 R2" }
  'Windows2012Domain' { $domain = "Windows Server 2012" }
  'Windows2008R2Domain' { $domain = "Windows Server 2008 R2" }
  'Windows2008Domain' { $domain = "Windows Server 2008" }
  'Windows2003Domain' { $domain = "Windows Server 2003" }
}

# Custom PowerShell object with all the details for the current server.
$server = [PSCustomObject]@{
  OS = $os
  ExpectedLevels = $expected
  ForestFunctionalLevel = $forest
  DomainFunctionalLevel = $domain
}

# If the levels aren't what we're expecting, throw a flag.
if ($server.ExpectedLevels -ne $server.ForestFunctionalLevel -or $server.ExpectedLevels -ne $server.DomainFunctionalLevel) {
  Write-Host "The Forest or Domain Functional Levels does not match the expected levels. The current levels are: OS: $($server.OS) | Expected Levels: $($server.ExpectedLevels) | Forest Functional Level: $($server.ForestFunctionalLevel) | Domain Functional Level: $($server.DomainFunctionalLevel)"
 
  exit 1
} else {
  Write-Host "The Forest and Domain Functional Levels are at their appropriate levels. The current levels are: OS: $($server.OS) | Expected Levels: $($server.ExpectedLevels) | Forest Functional Level: $($server.ForestFunctionalLevel) | Domain Functional Level: $($server.DomainFunctionalLevel)"
}