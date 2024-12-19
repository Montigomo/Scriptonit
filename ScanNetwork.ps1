#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'NetworkName')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'NetworkName', Position = 0)]
    [string]$NetworkName,
    [Parameter(Mandatory = $false, ParameterSetName = 'NetworkRange', Position = 0)]
    [ipaddress]$FromIp,
    [Parameter(Mandatory = $false, ParameterSetName = 'NetworkRange', Position = 1)]
    [ipaddress]$ToIp
)

Set-StrictMode -Version 3.0
#region Imports
. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network") | Out-Null
#endregion

#region ResolveHost ScanIpRangePrinters ScanIpRangePort ScanIpRangePing

function ResolveHost {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline)] [object] $Item
    )
    $label = ""
    try {
        $label = [System.Net.DNS]::GetHostEntry($Item.IPAddress).HostName
    }
    catch {}
    if (-not ([bool]($Item.PSobject.Properties.name -match "ComputerName"))) {
        $Item | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value "no set"
    }
    $Item.ComputerName = $label
    $Item
}

function ScanIpRangePrinters {
    param(
        [Parameter(Mandatory = $true)] [array]$IpRange
    )
    $IpRange | Invoke-Parallel { Test-RemotePort -ComputerName $_ -Port 9100 -TimeoutMilliSec 3000 } -ThrottleLimit 128 | Where-Object Response | Invoke-Parallel { Get-PrinterInfo -ComputerName $_.ComputerName }
}

function ScanIpRangePort {
    param(
        [Parameter(Mandatory = $true)] [array]$IpRange,
        [Parameter(Mandatory = $false)] [int] $Port
    )
    $result = $IpRange | Invoke-Parallel { Test-RemotePort -Port $Port -IPAddress $_ -TimeoutMilliSec 1000 } -ThrottleLimit 64 | Where-Object { $_.Response }
    $result = $result | Invoke-Parallel { ResolveHost -Item $_ } -ThrottleLimit 128 
    $result = $result | Select-Object -Property IPAddress, Port, Response, ComputerName | Sort-Object { $_.IPAddress -replace '\d+', { $_.Value.PadLeft(3, '0') } }
    $result | Format-Table -Wrap -AutoSize
}

function ScanIpRangePing {
    param(
        [Parameter(Mandatory = $true)] [array]$IpRange
    )
    $result = $IpRange | Invoke-Parallel { Test-Ping -IPAddress $_ -TimeoutMilliSec 100 } -ThrottleLimit 128 | Where-Object { $_.Response }
    $result = $result |  Invoke-Parallel { ResolveHost -Item $_ } -ThrottleLimit 128
    $result = $result | Select-Object -Property IPAddress, Port, Response, ComputerName | Sort-Object { $_.IPAddress -replace '\d+', { $_.Value.PadLeft(3, '0') } }
    $result | Format-Table -Wrap -AutoSize 
}

#endregion

#region ScanNetwork

function ScanNetwork {
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'NetworkName', Position = 0)] [string]$NetworkName,
        [Parameter(Mandatory = $false, ParameterSetName = 'NetworkRange', Position = 0)] [ipaddress]$FromIp,
        [Parameter(Mandatory = $false, ParameterSetName = 'NetworkRange', Position = 1)] [ipaddress]$ToIp
    )

    $objects = LmGetObjects -ConfigName "Networks.$NetworkName.Scan"
    $objects = $objects.GetEnumerator() | Sort-Object { $_.order }

    foreach ($item in $objects) {
        $ipFrom = $item.ipfrom
        $ipTo = $item.ipto
        $IpRange = New-IpRange -From $ipFrom -To $ipTo

        switch ($item.method) {
            "ping" {
                Write-Host "Lan: Scan by ping" -ForegroundColor DarkYellow
                ScanIpRangePing -IpRange $IpRange
                break
            }
            "port" {
                $port = $item.port
                Write-Host "Lan: Scan port $port" -ForegroundColor DarkYellow
                ScanIpRangePort -IpRange $IpRange -Port $port
                break
            }
        }
    }
}

#endregion

Get-ModuleAdvanced -ModuleName "PSParallel"

$params = LmGetParams -InvParams $MyInvocation.MyCommand.Parameters -PSBoundParams $PSBoundParameters
if ($params) {
    ScanNetwork @params
}