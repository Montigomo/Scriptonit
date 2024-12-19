Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\..\LoadModule.ps1" -ModuleNames @( "Network.Hosts") | Out-Null

function Write-Hosts
{
    param
    (
        [Parameter(Mandatory=$true)]
        [System.Collections.Specialized.OrderedDictionary]$Hosts,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName
    )   

    $directory = [System.IO.Path]::GetDirectoryName($FileName)
    
    if(!(Test-Path $directory))
    {
        return
    }
    
    $arrayList = New-Object System.Collections.ArrayList;
    foreach($item in $Hosts.GetEnumerator())
    {
        $arrayList.Add($item.Value["line"]) | Out-Null
    }
    
    $arrayList | Out-File $FileName
}