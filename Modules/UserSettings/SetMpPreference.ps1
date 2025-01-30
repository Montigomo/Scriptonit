Set-StrictMode -Version 3.0

function SetMpPreference {
    param (
        [Parameter(Mandatory = $true)][array]$Items
    )

    Write-Host "[SetMpPreference] started ..." -ForegroundColor DarkYellow

    $mp = (Get-MpPreference)
    $o = $mp.ExclusionPath

    foreach ($item in $Items) {
        if (-not (Test-Path $item)) {
            Write-Host "[SetMpPreference] path $item doesn't exist." -ForegroundColor DarkRed
            continue
        }
        if ($o -inotcontains $item ) {
            Write-Host "[SetMpPreference] Added item $item" -ForegroundColor DarkGreen
            Add-MpPreference -ExclusionPath $item
        }
        else {
            Write-Host "[SetMpPreference] Item $item already added." -ForegroundColor DarkYellow
        }
    }
}