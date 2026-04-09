# The log path for this script.
$logPath = "C:\Program Files\Dentrix\Reg Backup\Reg Backup.log"

# Adds a Reg backup folder and log file
if(!(Test-Path('C:\Program Files\Dentrix\Reg Backup'))) {
  New-Item -ItemType Directory -Path "C:\Program Files\Dentrix\Reg Backup" -Force
}
if(!(Test-Path($logPath))) {
  New-Item -ItemType File -Path $logPath -Force
}

# Backs up all four Dentrix reg locations to C:\Program Files\Dentrix\Reg Backup and writes the success or failure to the log file.
try {
  reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Dentrix Dental Systems, Inc." "C:\Program Files\Dentrix\Reg Backup\HKLM_Software.reg" /y
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully backed up the HKLM\SOFTWARE\Dentrix Dental Systems, Inc. registry keys."
} catch {
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to back up the HKLM\SOFTWARE\Dentrix Dental Systems, Inc. registry keys."
}

try {
  reg export "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Dentrix Dental Systems, Inc." "C:\Program Files\Dentrix\Reg Backup\HKLM_Wow64.reg" /y
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully backed up the HKLM\SOFTWARE\WOW6432Node\Dentrix Dental Systems, Inc. registry keys."
} catch {
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to back up the HKLM\SOFTWARE\WOW6432Node\Dentrix Dental Systems, Inc. registry keys."
}

try {
  reg export "HKEY_CURRENT_USER\SOFTWARE\Software\Dentrix Dental Systems, Inc." "C:\Program Files\Dentrix\Reg Backup\HKCU_Software_Software.reg" /y
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully backed up the HKCU\SOFTWARE\Software\Dentrix Dental Systems, Inc. registry keys."
} catch {
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to back up the HKCU\SOFTWARE\Software\Dentrix Dental Systems, Inc. registry keys."
}

try {
  reg export "HKEY_CURRENT_USER\SOFTWARE\Dentrix Dental Systems, Inc." "C:\Program Files\Dentrix\Reg Backup\HKCU_Software.reg"/y
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Successfully backed up the HKCU\SOFTWARE\Dentrix Dental Systems, Inc. registry keys."
} catch {
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to back up the HKCU\SOFTWARE\Dentrix Dental Systems, Inc. registry keys."
}