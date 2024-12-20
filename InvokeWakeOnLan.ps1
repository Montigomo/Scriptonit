#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Include')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string]$NetworkName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [string[]]$IncludeNames,
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string[]]$ExcludeNames
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network", "Network.WakeOnLan") | Out-Null

function InvokeWakeOnLan {
    [CmdletBinding(DefaultParameterSetName = 'Include')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Include')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Exclude')]
        [string]$NetworkName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
        [string[]]$IncludeNames,
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
        [string[]]$ExcludeNames
    )

    $objects = LmGetObjects -ConfigName "Networks.$NetworkName.Hosts"

    if(-not $objects){
        return
    }

    $objects = $objects.GetEnumerator()

    switch ($PSCmdlet.ParameterSetName) {
        'Include' {
            if ($IncludeNames) {
                $objects = $objects | Where-Object { $IncludeNames -icontains $_.Key}
            }
            break
        }
        'Exclude' {
            if ($ExcludeNames) {
                $objects = $objects | Where-Object { $ExcludeNames -inotcontains $_.Key }
            }
            break
        }
    }

    $objects = $objects | Where-Object { $_.Value["wolFlag"] -eq $true }  

    foreach ($object in $objects) {
        $objectMAC = $object.Value.MAC
        $objectName = $object.Key
        Write-Host "Sending wol packet to $objectName" -ForegroundColor DarkGreen
        Send-MagicPacket -MacAddresses $objectMAC #-BroadcastProxy 192.168.1.255
    }
}


if ($PSBoundParameters.Count -gt 0) {
    $params = LmGetParams -InvParams $MyInvocation.MyCommand.Parameters -PSBoundParams $PSBoundParameters            
    InvokeWakeOnLan @params
}