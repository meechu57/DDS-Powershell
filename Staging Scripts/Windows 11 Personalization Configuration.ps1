# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Check if the script was run as the default System User
function Test-IsSystem {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
}

# If it was we'll error out and enform the technician they should run it as the "Current Logged on User"
if (Test-IsSystem) {
  Write-Host "This script does not work when ran as system. Use Run As: 'Current Logged on User'."
  exit 1
}

# Get the operating system version
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version

# Check if the OS version contains "10.0.2" (Windows 11)
if ($osVersion -like "10.0.2*") {
  #                                                    Taskbar configs
  Write-Host "Configuring the taskbar..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the taskbar..."

  # Remove Task View button
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the ShowTaskViewButton registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the ShowTaskViewButton registry key: $_"
  }

  # Remove Widgets
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the TaskbarDa registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TaskbarDa registry key: $_"
  }

  # Remove Chat
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the TaskbarMn registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TaskbarMn registry key: $_"
  }
  
  # Remove CoPilot
  try {
    reg add HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot /v "TurnOffWindowsCopilot" /t REG_DWORD /f /d 1
  } catch {
    Write-Host "Failed to set the TurnOffWindowsCopilot registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TurnOffWindowsCopilot registry key: $_"
  }

  # Moves Windows icon to the left
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the TaskbarAl registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TaskbarAl registry key: $_"
  }

  # Removes Search
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the SearchboxTaskbarMode registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the SearchboxTaskbarMode registry key: $_"
  }

  #                                                  Start Menu
  Write-Host "Configuring the start menu..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the start menu..."

  # Shows more pins on the start menu
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_Layout /t REG_DWORD /d 1 /f
  } catch {
    Write-Host "Failed to set the Start_Layout registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the Start_Layout registry key: $_"
  }

  # Disables the info tips
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowInfoTip /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the ShowInfoTip registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the ShowInfoTip registry key: $_"
  }

  # Disables the Iris info tips
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_IrisRecommendations /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the Start_IrisRecommendations registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the Start_IrisRecommendations registry key: $_"
  }

  # Adds Settings and File Explorer to the Start menu
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v VisiblePlaces /t REG_BINARY /d 86087352AA5143429F7B2776584659D4BC248A140CD68942A0806ED9BBA24882 /f
  } catch {
    Write-Host "Failed to set the VisiblePlaces registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the VisiblePlaces registry key: $_"
  }

  # Show all file name extentsions
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the HideFileExt registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the HideFileExt registry key: $_"
  }

  #                                                  DARK MODE BAYBEEE
  Write-Host "Configuring dark mode..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring dark mode..."

  # Forces Dark mode on apps
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the AppsUseLightTheme registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the AppsUseLightTheme registry key: $_"
  }

  # Forces Dark mode on Windows
  try {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f
  } catch {
    Write-Host "Failed to set the SystemUsesLightTheme registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the SystemUsesLightTheme registry key: $_"
  }

  # Restarts Windows Exporer
  Stop-Process -Name explorer -Force
  Start-Sleep -Seconds 2
  Start-Process explorer
} 
else {
  Write-Host "A Windows 11 OS was not found. Aborting the script."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A Windows 11 OS was not found. Aborting the script."
}
