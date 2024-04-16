<# 
This will create 5 log files for ad hoc scripts, staging scripts, and for maintenance scripts. 

Scripts.log should be used for ad hoc scripts.
Maintenance.log should be used only for the maintenance policy.
Staging.log should be used only for the staging policy.
Audit.log should be used for the scripts in the auditing category.
Scheduled Automation.log should be used for scripts that run on a scheduled, regular basis through their policy.
#>

# Checks to see if the Scripts.log file exists and creates it if it doesn't
if(!(Test-Path 'C:\DDS\Logs\Scripts.log')) {
  try {
    New-Item -ItemType File -Path "C:\DDS\Logs\Scripts.log" -Force
    
    Write-Host "Added Scripts.log to the directory C:\DDS\Logs"
  } catch {
    Write-Host "Unable to add Scripts.log to the directory C:\DDS\Logs"
  }
}

# Checks to see if the Maintenance.log file exists and creates it if it doesn't
if(!(Test-Path 'C:\DDS\Logs\Maintenance.log')) {
  try {
    New-Item -ItemType File -Path "C:\DDS\Logs\Maintenance.log" -Force
    
    Write-Host "Added Maintenance.log to the directory C:\DDS\Logss"
  } catch {
    Write-Host "Unable to add Maintenance.log to the directory C:\DDS\Logs"
  }
}

# Checks to see if the Staging.log file exists and creates it if it doesn't
if(!(Test-Path 'C:\DDS\Logs\Staging.log')) {
  try {
    New-Item -ItemType File -Path "C:\DDS\Logs\Staging.log" -Force
    
    Write-Host "Added Staging.log to the directory C:\DDS\Logs"
  } catch {
    Write-Host "Unable to add Staging.log to the directory C:\DDS\Logs"
  }
}

# Checks to see if the Audit.log file exists and creates it if it doesn't
if(!(Test-Path 'C:\DDS\Logs\Audit.log')) {
  try {
    New-Item -ItemType File -Path "C:\DDS\Logs\Audit.log" -Force
    
    Write-Host "Added Audit.log to the directory C:\DDS\Logs"
  } catch {
    Write-Host "Unable to add Audit.log to the directory C:\DDS\Logs"
  }
}

# Checks to see if the Scheduled Automation.log file exists and creates it if it doesn't
if(!(Test-Path "C:\DDS\Logs\Scheduled Automation.log")) {
  try {
    New-Item -ItemType File -Path "C:\DDS\Logs\Scheduled Automation.log" -Force
    
    Write-Host "Added Scheduled Automation.log to the directory C:\DDS\Logs"
  } catch {
    Write-Host "Unable to add Scheduled Automation.log to the directory C:\DDS\Logs"
  }
}

# Checks to see if the Defender.log file exists and creates it if it doesn't
if(!(Test-Path 'C:\DDS\Logs\Defender.log')) {
  try {
    New-Item -ItemType File -Path "C:\DDS\Logs\Defender.log" -Force
    
    Write-Host "Added Defender.log to the directory C:\DDS\Logss"
  } catch {
    Write-Host "Unable to add Defender.log to the directory C:\DDS\Logs"
  }
}
