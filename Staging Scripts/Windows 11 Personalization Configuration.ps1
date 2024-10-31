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

# If it was we'll error out and inform the technician they should run it as the "Current Logged on User"
if (Test-IsSystem) {
  Write-Host "This script does not work when run as system. Use Run As: 'Current Logged on User'."
  exit 1
}

# Get the operating system version
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version

# Convert the script variable to a local variable. 
$enableDarkMode = $env:enableDarkMode

# Check if the OS version contains "10.0.2" (Windows 11)
if ($osVersion -like "10.0.2*") {
  #                                                    Taskbar configs
  Write-Host "Configuring the taskbar..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the taskbar..."

  # Remove Task View button
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "ShowTaskViewButton" -Value 0 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the ShowTaskViewButton registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the ShowTaskViewButton registry key: $_"
  }

  # Remove Widgets
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "TaskbarDa" -Value 0 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the TaskbarDa registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TaskbarDa registry key: $_"
  }

  # Remove Chat
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "TaskbarMn" -Value 0 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the TaskbarMn registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TaskbarMn registry key: $_"
  }
  
  <# Remove CoPilot
  try {
    $keyPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "TurnOffWindowsCopilot" -Value 1 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the TurnOffWindowsCopilot registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TurnOffWindowsCopilot registry key: $_"
  }#>

  # Moves Windows icon to the left
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "TaskbarAl" -Value 0 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the TaskbarAl registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TaskbarAl registry key: $_"
  }

  # Removes Search
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "SearchboxTaskbarMode" -Value 0 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the SearchboxTaskbarMode registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the SearchboxTaskbarMode registry key: $_"
  }

  #                                                  Start Menu
  Write-Host "Configuring the start menu..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Configuring the start menu..."

  # Shows more pins on the start menu
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "Start_Layout" -Value 1 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the Start_Layout registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the Start_Layout registry key: $_"
  }

  # Disables the info tips
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "ShowInfoTip" -Value 0 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the ShowInfoTip registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the ShowInfoTip registry key: $_"
  }

  # Disables the Iris info tips
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "Start_IrisRecommendations" -Value 0 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the Start_IrisRecommendations registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the Start_IrisRecommendations registry key: $_"
  }

  # Adds Settings and File Explorer to the Start menu
      
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v VisiblePlaces /t REG_BINARY /d 86087352AA5143429F7B2776584659D4BC248A140CD68942A0806ED9BBA24882 /f
  } catch {
    Write-Host "Failed to set the VisiblePlaces registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the VisiblePlaces registry key: $_"
  }

  # Show all file name extensions
  try {
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $keyPath)) {
      Write-Host "Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."
      Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Warning! The registry pathway $keyPath doesn't exist. Please manually investigate."

      exit 1
    }
    New-ItemProperty -Path $keyPath -Name "HideFileExt" -Value 0 -PropertyType DWord -Force
  } catch {
    Write-Host "Failed to set the HideFileExt registry key: $_"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the HideFileExt registry key: $_"
  }

  # Restarts Windows Explorer
  Stop-Process -Name explorer -Force
  Start-Sleep -Seconds 2
  Start-Process explorer
} 
else {
  Write-Host "A Windows 11 OS was not found. Aborting the script."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A Windows 11 OS was not found. Aborting the script."

  exit 1
}