#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Include')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string]$NetworkName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')][string[]]$IncludeNames,
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')][string[]]$ExcludeNames
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network", "Network.WakeOnLan") -Verbose | Out-Null

function InvokeWakeOnLan {
    [CmdletBinding(DefaultParameterSetName = 'Include')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
        [string]$NetworkName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Include')][string[]]$IncludeNames,
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')][string[]]$ExcludeNames
    )

    $objects = LmGetObjects -ConfigName "Networks.$NetworkName.Hosts"

    $objects = $objects.GetEnumerator() | Where-Object { $_.Value["wolFlag"] -eq $true }

    foreach ($object in $objects) {
        $objectMAC = $object.Value.MAC
        $objectName = $object.Key
        Write-Host "Sending wol packet to $objectName" -ForegroundColor DarkGreen
        Send-MagicPacket -MacAddresses $objectMAC #-BroadcastProxy 192.168.1.255
    }
}


$params = LmGetParams -InvParams $MyInvocation.MyCommand.Parameters -PSBoundParams $PSBoundParameters
if ($params) {
    InvokeWakeOnLan @params
}