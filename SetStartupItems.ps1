#Requires -Version 6.0
#Requires -PSEdition Core
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Work')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListItems')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListSets')]
    [string]$SetName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [array]$Items,
    [Parameter(Mandatory = $false, ParameterSetName = 'ListItems')]
    [switch]$ListItems,
    [Parameter(Mandatory = $false, ParameterSetName = 'ListSets')]
    [switch]$ListSets
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null


function ListSets {
    $objects = LmGetObjects -ConfigName "Tasks"
    $objects | Format-Table @{
        Label      = "Sets";
        Expression = {
            $color = "93"
            #$color = "32"
            #$color = "35"
            #$color = "0"
            $e = [char]27
            "$e[${color}m$($_.Key)${e}[0m"
        }
    }
}
function ListItems {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SetName
    )
    $objects = LmGetObjects -ConfigName "Tasks.$SetName"

    $objects | Select-Object -Property Name | Format-Table @{
        Label      = "Operations";
        Expression = {
            #$color = "93"
            #$color = "32"
            $color = "35"
            #$color = "0"
            $e = [char]27
            "$e[${color}m$($_.Name)${e}[0m"
        }
    }
}

function SetStartupItems {
    param (
        [Parameter(Mandatory = $true)] [string]$SetName,
        [Parameter(Mandatory = $false)] [array]$Items
    )

    $objects = LmGetObjects -ConfigName "Tasks.$SetName"

    if (-not $objects -or $objects -isnot [array]) {
        Write-Host "Empty objects or wrong type." -ForegroundColor DarkYellow
        return
    }

    if (-not (Get-IsAdmin)) {
        #Start-Process pwsh  -Verb "RunAs" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$PSCommandPath"""
        return
    }

    foreach ($object in $objects) {

        if($Items -and ($Items -notcontains $object.Name)){
            continue
        }

        Write-Host "Create task for $($object.Name)" -ForegroundColor DarkYellow

        if ($Items -or $object.prepare) {
            $params = $object
            $params.Remove("order")
            $params.Remove("prepare")
            $params = LmParamsRemoveComments -Params $params
            Register-ScheduledTaskWrapper @params
        }
    }
    Start-Sleep -Seconds 3

}

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSBoundParameters
    switch ($PSCmdlet.ParameterSetName) {
        'Work' {
            SetStartupItems @params
            break
        }
        'ListItems' {
            $params.Remove("ListItems") | Out-Null
            $params.Remove("LisSets") | Out-Null
            ListItems @params
            break
        }
        'ListSets' {
            $params.Remove("ListItems") | Out-Null
            $params.Remove("LisSets") | Out-Null
            ListSets @params
            break
        }
    }
}