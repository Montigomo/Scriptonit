#Requires -Version 6.0
#Requires -PSEdition Core
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Work')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListItems')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListUsers')]
    [string]$UserName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [array]$Items,
    [Parameter(Mandatory = $false, ParameterSetName = 'ListItems')]
    [switch]$ListItems,
    [Parameter(Mandatory = $false, ParameterSetName = 'ListUsers')]
    [switch]$ListUsers
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null


function ListUsers {
    LmListObjects -ConfigName "Users"
}

function ListItems {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    LmListObjects -ConfigName "Users", "$UserName", "tasks"
}

function SetStartupItems {
    param (
        [Parameter(Mandatory = $true)] [string]$UserName,
        [Parameter(Mandatory = $false)] [array]$Items
    )

    $objects = LmGetObjects -ConfigName "users", "$UserName", "tasks"

    if (-not $objects -or $objects -isnot [array]) {
        Write-Host "Empty objects or wrong type." -ForegroundColor DarkYellow
        return
    }

    if (-not (Get-IsAdmin)) {
        #Start-Process pwsh  -Verb "RunAs" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$PSCommandPath"""
        return
    }

    foreach ($object in $objects) {

        if ($Items -and ($Items -notcontains $object.Name)) {
            continue
        }

        Write-HostColorable @("Create", "startup task", "for", $($object.Name))  @("DarkYellow", "DarkGreen", "DarkYellow", "DarkBlue")

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
        'ListUsers' {
            $params.Remove("ListItems") | Out-Null
            $params.Remove("ListUsers") | Out-Null
            ListUsers @params
            break
        }
    }
}