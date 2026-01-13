#Requires -RunAsAdministrator

Set-StrictMode -Version 3.0

function Enable-Features {
    [CmdletBinding()]
    param (
        [Parameter()]
        [array]$Features
    )    

    foreach ($feature in $Features) {
        $featureItem = Get-WindowsOptionalFeature -Online -FeatureName $feature
        if (-not $featureItem) {
            Write-Host "Feature $feature not found" -ForegroundColor Red
            continue
        }
        if($featureItem.State -eq 'Disabled'){
            Write-Host "Enabling feature $feature" -ForegroundColor DarkYellow
            Enable-WindowsOptionalFeature -Online -FeatureName $feature
        }
    }
}