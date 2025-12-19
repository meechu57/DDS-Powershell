try {
    $InstanceNames = $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" -ErrorAction Stop).InstalledInstances
    $SqlInstances = $InstanceNames | ForEach-Object {
        $SqlPath = $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$_\Setup" -ErrorAction Stop).SQLPath
        $SqlServices = Get-Service -Name "MSSQL`$$_" -ErrorAction Stop
        $SqlService = $SqlServices | Where-Object { $_.Name -notlike $SqlServices.DependentServices.Name -and $_.Name -notlike "SQLTelemetry*" }
        $SqlDatabaseSize = Get-ChildItem -Path "$SqlPath\Data" -Recurse -File | Measure-Object -Property Length -Sum | ForEach-Object { [Math]::Round($_.Sum / 1MB, 2) }
        [PSCustomObject]@{
            Status   = $SqlService.Status
            Service  = $SqlService.DisplayName
            Instance = $_
            Path     = $SqlPath
            Size     = $SqlDatabaseSize
        }
    }
}
catch {
    Write-Host "[Error] $($_.Message)"
    Write-Host "[Info] Likely no MSSQL instance found."
    exit 1
}

$SqlInstances | Out-String | Write-Host

foreach ($SqlInstance in $SqlInstances) {
    if ($SqlInstance.Size -gt 900) {
        Write-Host "Warning! The database $($SqlInstance.Instance) is getting close to the 1 GB limit."
    }
}