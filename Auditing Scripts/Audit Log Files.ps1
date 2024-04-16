# For error tracking
$errors = 0

# Looking for the script. If it doesn't exist, track the error.
if(Test-Path 'C:\DDS\Logs\Scripts.log') {
  Write-Host "The Scripts.log file exists."
} else {
  Write-Host "Couldn't find the Scripts.log file. Manual investigation is required."
  
  $errors++
}

# Looking for the script. If it doesn't exist, track the error.
if(Test-Path 'C:\DDS\Logs\Maintenance.log') {
   Write-Host "The Maintenance.log file exists."
} else {
   Write-Host "Couldn't find the Maintenance.log file. Manual investigation is required."
  
  $errors++
}
 
# Looking for the script. If it doesn't exist, track the error.
if(Test-Path 'C:\DDS\Logs\Staging.log') {
   Write-Host "The Staging.log file exists."
} else {
   Write-Host "Couldn't find the Staging.log file. Manual investigation is required."
  
  $errors++
}
 
# Looking for the script. If it doesn't exist, track the error.
if(Test-Path 'C:\DDS\Logs\Audit.log') {
   Write-Host "The Audit.log file exists."
} else {
   Write-Host "Couldn't find the Audit.log file. Manual investigation is required."
  
  $errors++
}

# Looking for the script. If it doesn't exist, track the error.
if(Test-Path "C:\DDS\Logs\Scheduled Automation.log") {
   Write-Host "The Scheduled Automation.log file exists."
} else {
   Write-Host "Couldn't find the Scheduled Automation.log file. Manual investigation is required."
  
  $errors++
}
 
# Looking for the old script log file. Delete it if it exists.
if(Test-Path "C:\Program Files\NinjaRemote\Script Log.log") {
  try {
    Remove-Item "C:\Program Files\NinjaRemote\Script Log.log"
  } catch {
    Write-Host "Failed to remove the old Script Log.log file"
  }
}

# If errors are 0, all files exist. If more than 0, more than one log doesn't exist.
if ($errors -eq 0) {
  Write-Host "All log files exist."
  
  Ninja-Property-Set logFilesCreated $true
} else {
  Write-Host "$($errors) log file(s) don't exist. Manual investigation is required."
  
  Ninja-Property-Set logFilesCreated $false
}
