#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Only')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Only')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string]$NetworkName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Only')]
    [string[]]$OnlyNames,
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string[]]$ExcludeNames
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network", "Network.WakeOnLan") -Force | Out-Null

function InvokeWakeOnLan {
    [CmdletBinding(DefaultParameterSetName = 'Only')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Only')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Exclude')]
        [string]$NetworkName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Only')]
        [string[]]$OnlyNames,
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
        [string[]]$ExcludeNames
    )

    $objects = LmGetObjects "networks", "$networkName", "Hosts"

    if (-not $objects) {
        return
    }


    switch ($PSCmdlet.ParameterSetName) {
        'Only' {
            if ($OnlyNames) {
                $objects = $objects | Where-Object { $OnlyNames -icontains $_.HostName }
            }
            break
        }
        'Exclude' {
            if ($ExcludeNames) {
                $objects = $objects | Where-Object { $ExcludeNames -inotcontains $_.HostName }
            }
            break
        }
    }

    $objects = $objects | Where-Object { $_.wolFlag -eq $true }

    foreach ($object in $objects) {
        $objectMAC = $object.MAC
        $objectName = $object.HostName
        Write-Host "Sending wol packet to " -ForegroundColor DarkGreen -NoNewline
        Write-Host "$objectName." -ForegroundColor Blue
        Send-MagicPacket -MacAddresses $objectMAC #-BroadcastProxy 192.168.1.255
    }
}


if ($PSBoundParameters.Count -gt 0) {
    $params = $PSBoundParameters
    InvokeWakeOnLan @params
}