[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)] [string]$UserName,
    [Parameter(Mandatory = $false)] [array]$StartupItems
)

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common") | Out-Null

function ListStartupItems {
    param (
        [Parameter(Mandatory = $true)] [string]$UserName
    )

    $objects = LmGetObjects -ConfigName "Users.$UserName.StartupItems"

    $objects.Keys | Format-Table -AutoSize
}

function SetStartupItems {
    param (
        [Parameter(Mandatory = $true)] [string]$UserName,
        [Parameter(Mandatory = $false)] [array]$StartupItems
    )

    $objects = LmGetObjects -ConfigName "Users.$UserName.StartupItems"

    if(-not $objects){
        return
    }

    if (-not (Get-IsAdmin)) {
        #Start-Process pwsh  -Verb "RunAs" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$PSCommandPath"""
        return
    }
    
    foreach ($key in $objects.Keys) {
        if($StartupItems -and ($StartupItems -notcontains $key)){
            continue
        }        
        if ($StartupItems -or $objects[$key].prepare) {
            $itemPath = $objects[$key].Path
            $itemArgument = $null
            if ($objects[$key].ContainsKey("Argument")) {
                $itemArgument = $objects[$key].Argument
            }
            Set-StartUpItem -Name $key -Path $itemPath -Argument $itemArgument
        }
    }
    Start-Sleep -Seconds 3  

}

if ($PSBoundParameters.Count -gt 0) {
    $params = LmGetParams -InvParams $MyInvocation.MyCommand.Parameters -PSBoundParams $PSBoundParameters            
    SetStartupItems @params
}