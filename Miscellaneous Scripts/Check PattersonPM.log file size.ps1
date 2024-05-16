# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

function Get-FileSize {
  $filePath = "D:\EagleSoft\Data\PattersonPM.log"
    
  if (Test-Path $filePath) {
    $fileInfo = Get-Item $filePath
    return $fileInfo.Length
  } else {
    Write-Host "PattersonPM.log file was not found at: $($filePath)"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") PattersonPM.log file was not found at: $($filePath)"
    return $null
  }
}

Write-Host "Checking the PattersonPM.log file size..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Checking the PattersonPM.log file size..."

# Get the file size and display it.
$fileSize = Get-FileSize

if ($fileSize -ne $null) {
  if ($fileSize -lt 1KB) {
    Write-Host "PattersonPM.log file size: $fileSize bytes"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") PattersonPM.log file size: $fileSize bytes"
  } elseif ($fileSize -lt 1MB) {
    $fileSizeKB = $fileSize / 1KB
    
    Write-Host "PattersonPM.log file size: $fileSizeKB KB"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") PattersonPM.log file size: $fileSizeKB KB"
  } else {
    $fileSizeMB = $fileSize / 1MB
    
    Write-Host "PattersonPM.log file size: $fileSizeMB MB"
    Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") PattersonPM.log file size: $fileSizeMB MB"
  }
}
