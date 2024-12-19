Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\..\LoadModule.ps1" -ModuleNames @( "Network.Hosts") | Out-Null

function Remove-Host
{
    param
    (
        [Parameter(Mandatory=$true)]        
        [string]$HostIp,
        [Parameter(Mandatory=$true)]        
        [string]$HostName,
        [string]$HostFileDestination  = "$env:windir\System32\drivers\etc\hosts"
    )

    $hosts = New-Object System.Collections.Specialized.OrderedDictionary
    $hosts = Get-Hosts;
    [ipaddress]$IpAddress = New-Object System.Net.IPAddress(0x7FFFFFFF)
    if([ipaddress]::TryParse($HostIp, [ref]$IpAddress))
    {
        $ExHosts = ($hosts.GetEnumerator() | Where-Object {$_.Value["ip"] -eq $HostIp -and $_.Value["host"] -eq $HostName})
        if($ExHosts.Count -gt 0)
        {
            foreach($item in $ExHosts)
            {
                $hosts.Remove($item.Key);
            }
            Write-Hosts -Hosts $hosts -FileName $HostFileDestination
        }
    }
}