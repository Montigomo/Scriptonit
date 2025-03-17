#Requires -RunAsAdministrator

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network", "Network.WakeOnLan") -Force | Out-Null

function ConfigureWakeOnLan {
    $interface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and ($_.ifAlias -ilike "Ethernet*") }

    if (-not ($interface)) {
        Write-Host "Can't find any valid network interface" -ForegroundColor DarkYellow
        return
    }

    Enable-WakeOnLan -NetAdapter $interface -Verbose

    Disable-FastStartUp
}