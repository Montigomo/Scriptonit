Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\..\LoadModule.ps1" -ModuleNames @( "Network.Hosts") | Out-Null
function Get-Hosts{
    param(
        [string]$HostsFilePath = "$env:windir\System32\drivers\etc\hosts"
    )
    $regexip4 = "(?<ip>(((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))|(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])))";
    
    $RegexEntry = "(?<!#.*)$regexip4\s*(?<host>[^\s]+)(\s*\#.*)?";

    $hostsDictionary = New-Object System.Collections.Specialized.OrderedDictionary

	$lines = Get-Content $HostsFilePath;

    $count = 0;

    $pattern = $RegexEntry

	foreach ($line in  $lines)
    {
        $ip = $null;
        $hosts = $null;
        if($line -match $pattern)
        {
            $ip = $Matches["ip"];
            $hosts =  $($Matches["host"]);
        }
        $hostsDictionary.Add($count, @{"line" = $line; "host" = $hosts; "ip" = $ip});
        $count++;
	}
    return $hostsDictionary;
}