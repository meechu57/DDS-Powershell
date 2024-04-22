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

# The list of software that will be uninstalled. This has to match the dispaly name of the software in the registry.
$appsToUninstall = @(
    'Dell Core Services'
    'Dell Digital Delivery Services'
    'Dell Display Manager 2.1'
    'Dell Optimizer'
    'Dell Optimizer Core'
    'DellOptimizerUI'
    'Dell Pair'
    'Dell SupportAssist'
    'Dell SupportAssist OS Recovery Plugin for Dell Update'
    'Dell SupportAssist Remediation'
    'Dell Trusted Device Agent'
    'Dell Watchdog Timer'
    'Office 16 Click-to-Run Extensibility Component'
    'Office 16 Click-to-Run Licensing Component'
    'Office 16 Click-to-Run Localization Component'
    'Microsoft 365 - en-us'
    'Microsoft 365 - es-es'
    'Microsoft 365 - fr-fr'
    'Microsoft 365 - pt-br'
    'Microsoft OneNote - en-us'
    'Microsoft OneNote - es-es'
    'Microsoft OneNote - fr-fr'
    'Microsoft OneNote - pt-br'
    'Microsoft OneDrive'
)
 
# The two registry locations where the software would be.
$uninstallKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'

# Go through all registry locations.
foreach ($uKey in $uninstallKeys) {
  # Go through all of the registry keys in the hive.
  foreach ($key in (Get-ItemProperty $uKey)) {
    # Go through all of the app in the uninstall list and try to match them to the current registry key.
    foreach ($app in $appsToUninstall) {
      if ($app -eq $key.DisplayName) {
        # If the uninstall string is a MsiExec use the msiexec.exe with the /qn and product code switches. Don't reboot.
        if ($key.UninstallString -like "MsiExec*") {
          Write-Host "Uninstalling $($key.DisplayName)..."
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling $($key.DisplayName)..."
          
          $productCode = $key.PSChildName
          Start-Process -Wait -NoNewWindow -FilePath "msiexec.exe" -ArgumentList "/qn","/X$productCode","REBOOT=ReallySuppress"  -RedirectStandardOutput "NUL"
        } # If we have a quiet install string and not a MsiExec.
        elseif ($key.QuietUninstallString) {
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling $($key.DisplayName)..."
          Write-Host "Uninstalling the rest of $($key.DisplayName)..."
          & $env:ComSpec /c $key.QuietUninstallString
        } # For the Microsoft 365 and OneNote applications.
        elseif ($key.DisplayName -like "Microsoft*") {
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling $($key.DisplayName)..."
          Write-Host "Uninstalling $($key.DisplayName)..."
          & $env:ComSpec /c $key.UninstallString "DisplayLevel=False"
        } # For Dell Watchdog Timer. Manually hit enter as the software is dumb and has no silent uninstall switch.
        elseif ($key.DisplayName -eq 'Dell Watchdog Timer') {
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling $($key.DisplayName)..."
          Write-Host "Uninstalling $($key.DisplayName)..."
          & $env:ComSpec /c $key.UninstallString
          Timeout /T 10
          Add-Type -AssemblyName System.Windows.Forms
          [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        }
        elseif ($key.DisplayName -eq "Dell Display Manager 2.1" -or $key.DisplayName -eq "Dell Pair") {
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling $($key.DisplayName)..."
          Write-Host "Uninstalling $($key.DisplayName)..."
          & $env:ComSpec /c $key.UninstallString "/S"
        } # For everything else. Really is only catching the Dell Optimizer right now.
        elseif ($key.DisplayName -eq "Microsoft OneDrive") {
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling $($key.DisplayName)..."
          Write-Host "Uninstalling $($key.DisplayName)..."
          & $env:ComSpec /c $key.UninstallString "/silent"
        }
        else {
          Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Uninstalling $($key.DisplayName)..."
          Write-Host "Uninstalling $($key.DisplayName)..."
          & $env:ComSpec /c $key.UninstallString "-silent"
        }
      }
    }
  }
}

# Goes through everything again to verify that everything got uninstalled properly.
foreach ($uKey in $uninstallKeys) {
  foreach ($key in (Get-ItemProperty $uKey)) {
    foreach ($app in $appsToUninstall) {
      # If this catches anything, the software wasn't uninstalled properly.
      if ($app -eq $key.DisplayName) {
        Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when uninstalling $($key.DisplayName). The software was not uninstalled correctly."
        Write-Host "An error occurred when uninstalling $($key.DisplayName). The software was not uninstalled correctly."
        
        $errors++
      }
    }
  }
}

# Finish the script and show any errors.
if ($errors -eq 0) {
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") All software was uninstalled successfully."
  Write-Host "All software was uninstalled successfully."
} else {
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") $errors error(s) occurred when uninstalling the software."
  Write-Host "$errors error(s) occurred when uninstalling the software."
}
