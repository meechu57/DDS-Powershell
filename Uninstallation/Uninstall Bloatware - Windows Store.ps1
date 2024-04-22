# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# For error tracking
$errors = 0

# The list of software to uninstall
$appsToUninstall = @(
  'Clipchamp.Clipchamp'
  'MicrosoftTeams'
  'Microsoft.MicrosoftSolitaireCollection'
  'Microsoft.MicrosoftOfficeHub'
  'Microsoft.GamingApp'
  'Microsoft.Getstarted'
  'Microsoft.OutlookForWindows'
  'Microsoft.Windows.Ai.Copilot.Provider'
  'Microsoft.XboxApp'
  'Microsoft.Xbox.TCUI'
  'Microsoft.XboxSpeechToTextOverlay'
  'Microsoft.XboxIdentityProvider'
  'Microsoft.XboxGamingOverlay'
  'Microsoft.XboxGameOverlay'
  'Microsoft.SkypeApp'
  'DellInc.DellDigitalDelivery'
  'DB6EA5DB.Power2GoforDell'
  'DB6EA5DB.MediaSuiteEssentialsforDell'
  'DB6EA5DB.PowerDirectorforDell'
  'DB6EA5DB.PowerMediaPlayerforDell'
  'HONHAIPRECISIONINDUSTRYCO.DellWatchdogTimer'
  'PortraitDisplays.DellPremierColor'
  'Microsoft.WindowsFeedbackHub'
  'Microsoft.OneDrive'
  'MicrosoftCorporationII.QuickAssist'
)

$appsToUninstall2 = @(
  'Microsoft.XboxGameOverlay'
  'SpotifyAB.SpotifyMusic'  
)

# Goes through the list of software to uninstall and compares it to the list of installed Windows software.
foreach ($app in $appsToUninstall) {
  $fullName = ((Get-AppProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $app}).PackageName)
    
  if ($fullName) {
    # Remove the software if it exists and matches the software uninstall list. 
    try {
      Write-Host "Uninstalling $app..."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling $app..."
        
      Remove-AppProvisionedPackage -online -PackageName $fullName -AllUsers
    } catch {Write-Host "Error: $_"}
  }
}

foreach ($app in $appsToUninstall2) {
  $fullName = ((Get-AppxPackage -AllUsers | Where-Object {$_.Name -eq $app}).PackageFullName)
  
  if ($fullName) {
    try {
      Write-Host "Uninstalling $app..."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling $app..."
    
      Remove-AppxPackage -Package $fullName -AllUsers
    } catch {Write-Host "Error: $_"}
  }
}

# Check to make sure all software was uninstalled properly.
foreach ($app in $appsToUninstall) {
  $fullName = ((Get-AppProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $app}).PackageName)
  
  if ($fullName) {
    Write-Host "An error occurred when uninstalling $app. The application was not uninstalled properly."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when uninstalling $app. The application was not uninstalled properly."
    
    $errors++
  }
}

# Check to make sure all software was uninstalled properly.
foreach ($app in $appsToUninstall2) {
  $fullName = ((Get-AppxPackage -AllUsers | Where-Object {$_.Name -eq $app}).PackageFullName)
  
  if ($fullName) {
    Write-Host "An error occurred when uninstalling $app. The application was not uninstalled properly."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when uninstalling $app. The application was not uninstalled properly."
    
    $errors++
  }
}

# Finish the script and show any errors.
if ($errors -eq 0) {
  Write-Host "All software was uninstalled successfully."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All software was uninstalled successfully."
} else {
  Write-Host "$errors error(s) occurred when uninstalling the software."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $errors error(s) occurred when uninstalling the software."
}
