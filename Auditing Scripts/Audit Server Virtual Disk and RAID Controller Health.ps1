# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Check to ensure the script is running on a Dell server.
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
if (-not($computerSystem.Manufacturer -match "Dell") -and -not($computerSystem.Model -match "PowerEdge")) {
  Write-Host "This device is not a Dell server. Please run the script on a Dell server."
  exit 1
}

try {
  # Check to see if the racadm command is recognized. If it isn't, install the iDRAC tools.
  racadm | Out-Null
} catch {
  Write-Host "The iDRAC tools are not currently installed. Attempting to install now..."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") The iDRAC tools are not currently installed. Attempting to install now..."
  
  # Download and extract the iDRACTools MSI file.
  $uri = "https://dl.dell.com/FOLDER13988263M/1/Dell-iDRACTools-Web-WINX64-11.4.0.0-1435_A00.exe"
  $file = "$env:temp/Dell-iDRACTools-Web-WINX64-11.4.0.0-1435_A00.exe"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $uri -Method get -OutFile $file -UserAgent Chrome
  Unblock-File $file
  Start-Process -FilePath $file -ArgumentList "/auto" -Wait

  # Install the MSI file.
  if (Test-Path "C:\OpenManage\iDRACTools_x64.msi") {
    Start-Process -FilePath "C:\OpenManage\iDRACTools_x64.msi" -ArgumentList "/q" -Wait
  } else {
    Write-Host "An error occurred when trying to install the iDRAC tools. Please investigate and install manually if issues persist."
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to install the iDRAC tools. Please investigate and install manually if issues persist."
    
    exit 1
  }
}

# Check the status of the virtual disk and controller.
try {
  $raidController = racadm storage get controllers | Where-Object {$_ -like "RAID.*"}
  $vdiskStatus = racadm storage get vdisks -o | Where-Object { $_ -match '^\s*Status\s*=' } | ForEach-Object { ($_ -split '=')[1].Trim() }
  $controllerStatus = racadm storage get controllers:$raidController | Where-Object { $_ -match '^\s*Status\s*=' } | ForEach-Object { ($_ -split '=')[1].Trim() }

if ($vdiskStatus -ne "OK" -or $controllerStatus -ne "OK") {
  Write-Host "The Virtual Disk or RAID Controller's status is not 'OK'. Current status - Virtual Disk: $vdiskStatus - RAID Controller: $controllerStatus"
  
  exit 0
}
  
} catch {
  Write-Host "An error occurred when trying to run the Consistency Check. Please investigate and run manually if issues persist."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") An error occurred when trying to run the Consistency Check. Please investigate and run manually if issues persist."
  
  exit 1
}
