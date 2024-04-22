# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# Path where the Adobe .exe file exists
$exePath = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"

# Registry path where the RUNASADMIN data is set
$regPath = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

# Pulls the registry key to see if it was created previously
$adminRegKey = Get-ItemProperty -Path "Registry::$regPath" -Name $exePath -ErrorAction SilentlyContinue

Write-Host "Auditing Adobe..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing Adobe..."

if ($adminRegKey -ne $null -and $adminRegKey.'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -eq "RUNASADMIN") {
  Write-Host "Adobe is correctly configured to run as admin for all users."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe is correctly configured to run as admin for all users."
  
  Ninja-Property-Set adobeEnabledAsAdmin $true
}
else {
  Write-Host "Adobe is not correctly configured to run as admin for all users."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Adobe is not correctly configured to run as admin for all users."
  
  Ninja-Property-Set adobeEnabledAsAdmin $false
}
