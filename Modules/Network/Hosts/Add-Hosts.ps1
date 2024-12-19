Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\..\LoadModule.ps1" -ModuleNames @( "Network.Hosts") | Out-Null

function Add-Host {
    param
    (
        [Parameter(Mandatory = $true)]        
        [string]$HostIp,
        [Parameter(Mandatory = $true)]        
        [string]$HostName,
        [string]$HeaderLine,
        [string]$Comment,
        [string]$HostFileDestination = "$env:windir\System32\drivers\etc\hosts"
    )

    $hosts = New-Object System.Collections.Specialized.OrderedDictionary
    $hosts = Get-Hosts;
    [ipaddress]$IpAddress = New-Object System.Net.IPAddress(0x7FFFFFFF)
    if ([ipaddress]::TryParse($HostIp, [ref]$IpAddress)) {
        $_hosts = @($hosts.GetEnumerator() | Where-Object { $_.Value["ip"] -eq $HostIp -and $_.Value["host"] -eq $HostName })
        if ($_hosts.Count -eq 0) {
            if ($HeaderLine) {
                $hosts.Add($count, @{"line" = $line; "host" = $null; "ip" = $null });
            }
            if ($Comment.StartsWith("#")) {
                $line = "$HostIp $HostName  $Comment"
            }
            else {
                $line = "$HostIp $HostName"                
            }
            $count = $hosts.Count + 1
            
            $hosts.Add($count, @{"line" = $line; "host" = $HostName; "ip" = $HostIp });
            Write-Hosts -Hosts $hosts -FileName $HostFileDestination
            return $true
        }
        else {
            return $false
        }
    }
}