# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Installs AD DS, DHCP, DNS, DFS Namespaces, DFS Replication, BitLocker, and MSMQ including their management tools.

Write-Host "Installing Roles and Features..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Installing Roles and Features..."

$result = Install-WindowsFeature -Name AD-Domain-Services, DHCP, DNS, FS-DFS-Namespace, FS-DFS-Replication, BitLocker, MSMQ-Server -IncludeManagementTools

Write-Host "Success: $($result.Success)"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Success: $($result.Success)"
Write-Host "Restart Needed: $($result.RestartNeeded)"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Restart Needed: $($result.RestartNeeded)"
Write-Host "Exit Code: $($result.ExitCode)"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Exit Code: $($result.ExitCode)"

if ($result.RestartNeeded -eq "Yes") {
  Write-Host "Installation complete. A restart is required."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Installation complete. A restart is required."
}