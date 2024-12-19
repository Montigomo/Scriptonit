Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Network.Hosts") | Out-Null

function PrepareHostsRaw {
    param (
        [Parameter(Mandatory = $true)] [string[]]$Hosts
    )
    foreach ($item in $Hosts) {
        $values = ($item -split "\|")
        $result = Add-Host -HostIp $values[0] -HostName $values[1]
        if ($result) {
            Write-Host "[PrepareHosts] Added host $($values[0]) - $($values[1])" -ForegroundColor DarkGreen
        }
        else {
            Write-Host "[PrepareHosts] Host $($values[0]) - $($values[1]) already exist in hosts file." -ForegroundColor DarkYellow
        }
    }

}

function PrepareHosts {
    param (
        [Parameter(Mandatory = $true)][hashtable]$Hosts
    )
    Write-Host "[PrepareHosts] started ..." -ForegroundColor Green

    foreach ($key in $Hosts.Keys) {
        Write-Host "[PrepareHosts] Adding group: $key" -ForegroundColor DarkGreen
        PrepareHostsRaw -Hosts $Hosts[$key]
    }

}