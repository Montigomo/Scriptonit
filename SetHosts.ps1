#R-equires -Version 6.0
#R-equires -PSEdition Core
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Work')]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false, ParameterSetName = 'List')]
    [Parameter(Mandatory = $false)]
    [object]$ConfigPath,
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    [Parameter(Mandatory = $false, ParameterSetName = 'List')]
    [switch]$ListRules
)


Set-StrictMode -Version 3.0


. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network", "Network.Hosts") -Force | Out-Null


#region PrepareHostsRaw

function PrepareHostsRaw {
    param (
        [Parameter(Mandatory = $true)] [string[]]$Hosts
    )
    foreach ($item in $Hosts) {
        $values = ($item -split "\|")
        if ( $values.Count -lt 2) {
            Write-Host "[PrepareHosts] Invalid host entry: $item" -ForegroundColor DarkRed
            continue
        }

        if ($values[0] -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
            Write-Host "[PrepareHosts] Invalid IP address: $($values[0])" -ForegroundColor DarkRed
            continue
        }
        if ($values[1] -notmatch '^[a-zA-Z0-9\-\.]+$') {
            Write-Host "[PrepareHosts] Invalid host name: $($values[1])" -ForegroundColor DarkRed
            continue
        }

        $result = Add-Host -HostIp $values[0] -HostName $values[1]
        if ($result) {
            Write-Host "[PrepareHosts] Added host $($values[0]) - $($values[1])" -ForegroundColor DarkGreen
        }
        else {
            Write-Host "[PrepareHosts] Host $($values[0]) - $($values[1]) already exist in hosts file." -ForegroundColor DarkYellow
        }
    }

}

#endregion


function PrepareHostsPost {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Object
    )

    if ($objects -is [array] ) {
        $_fullName = LmJoinObjects -Objects $ConfigPath
        Write-Host "[PrepareHosts] Adding group: $_fullName" -ForegroundColor DarkGreen
        PrepareHostsRaw -Hosts $objects
    }
    elseif ($objects -is [hashtable]) {
        $_fullName = LmJoinObjects -Objects $ConfigPath
        foreach ($key in $objects.Keys) {
            $_item = $objects[$key]
            PrepareHostsPost $_item
        }

    }


}


function PrepareHosts {
    param (
        [Parameter(Mandatory = $false)]
        [object]$ConfigPath
    )

    $objects = LmGetObjects -ConfigPath $ConfigPath

    if (-not $objects) {
        Write-Host "Not any hosts to apply." -ForegroundColor DarkYellow
        return
    }

    PrepareHostsPost -Object $objects
}


if ($PSBoundParameters.Count -gt 0) {
    $params = $PSCmdlet.MyInvocation.BoundParameters
    switch ($PSCmdlet.ParameterSetName) {
        'Work' {
            ImportFirewallRule @params
            break
        }
        'List' {
            $params.Remove("ListRules")
            ListFirewallRule @params
            break
        }
    }
}