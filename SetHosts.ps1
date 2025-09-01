Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network", "Network.Hosts") -Force | Out-Null

$Hosts = @{
    "Common" = @(
        "127.0.0.1|compute-1.amazonaws.com"
        "0.0.0.0|license.sublimehq.com"
        "83.243.40.67|wiki.bash-hackers.org"
    )
    "Corel"  = @(
        "127.0.0.1|iws.corel.com",
        "127.0.0.1|apps.corel.com",
        "127.0.0.1|mc.corel.com",
        "127.0.0.1|origin-mc.corel.com",
        "127.0.0.1|iws.corel.com",
        "127.0.0.1|deploy.akamaitechnologies.com"
    )
    "Adobe"  = @(
        "127.0.0.1|na1r.services.adobe.com"
        "127.0.0.1|hlrcv.stage.adobe.com"
        "127.0.0.1|lmlicenses.wip4.adobe.com"
        "127.0.0.1|lm.licenses.adobe.com"
        "127.0.0.1|activate.adobe.com"
        "127.0.0.1|practivate.adobe.com"
        "127.0.0.1|ereg.adobe.com"
        "127.0.0.1|activate.wip3.adobe.com"
        "127.0.0.1|wip3.adobe.com"
        "127.0.0.1|3dns-3.adobe.com"
        "127.0.0.1|3dns-2.adobe.com"
        "127.0.0.1|adobe-dns.adobe.com"
        "127.0.0.1|adobe-dns-2.adobe.com"
        "127.0.0.1|adobe-dns-3.adobe.com"
        "127.0.0.1|ereg.wip3.adobe.com"
        "127.0.0.1|activate-sea.adobe.com"
        "127.0.0.1|wwis-dubc1-vip60.adobe.com"
        "127.0.0.1|activate-sjc0.adobe.com"
        "127.0.0.1|adobeereg.com"
        "127.0.0.1|adobe.activate.com"
    )
}


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
    Write-Host "[PrepareHosts] started ..." -ForegroundColor DarkYellow

    foreach ($key in $Hosts.Keys) {
        Write-Host "[PrepareHosts] Adding group: $key" -ForegroundColor DarkGreen
        PrepareHostsRaw -Hosts $Hosts[$key]
    }

}


PrepareHosts -Hosts $Hosts