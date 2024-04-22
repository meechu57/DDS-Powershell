# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

# Used track good restore points
$recentRestorePoints = 0

# Calculate the date 7 days ago
$sevenDaysAgo = (Get-Date).AddDays(-7)

# Get the restore points and filter based on the creation date
$restorePoints = Get-ComputerRestorePoint | Where-Object {
    $creationTime = $_.ConvertToDateTime($_.CreationTime)
    $creationTime -ge $sevenDaysAgo
}

Write-Host "Auditing restore point(s)..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing restore point(s)..."

# Sorts the list of restore points and looks for only DDS created restore points. 
foreach ($i in $restorePoints) {
  $creationTime = $i.ConvertToDateTime($i.CreationTime).ToShortDateString()
  $recentRestorePoints++
}

# If we've got restore points, we're g2g.
if ($recentRestorePoints -gt 0) {
  Ninja-Property-Set recentRestorePointCreated $true
  
  Write-Host "A restore point from the last 7 days exists. It was created on $creationTime."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A restore point from the last 7 days exists. It was created on $creationTime."
} 
else {
  Ninja-Property-Set recentRestorePointCreated $false
  
  Write-Host "A restore point from the last 7 days way not found."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A restore point from the last 7 days way not found."
}
