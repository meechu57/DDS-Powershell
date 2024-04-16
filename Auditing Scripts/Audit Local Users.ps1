# The log path for this script
$logPath = "C:\DDS\Logs\Audit.log"

Write-Host "Auditing local users..."
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Auditing local users..."

# Gets the list of local users that are enabled and returns them as a joined string
function Get-EnabledLocalUserNames {
    $enabledUserNames = Get-LocalUser | Where-Object { $_.Enabled -eq $true } | Select-Object -ExpandProperty Name
    $userNamesString = $enabledUserNames -join ', '
    return $userNamesString
}

# Get the local users
$enabledUsersString = Get-EnabledLocalUserNames

Write-Host "Enabled local user names: $enabledUsersString"
Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Enabled local user names: $enabledUsersString"

# Set the custom field in Ninja
Ninja-Property-Set localUsers $enabledUsersString
