#Requires -RunAsAdministrator
#--Requires -Version 6.0
#--Requires -PSEdition Core

[CmdletBinding(DefaultParameterSetName = 'Include')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListOperations')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListUsers')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]    
    [string]$UserName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [array]$OnlyNames,
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [array]$ExcludeNames,    
    [Parameter(Mandatory = $false, ParameterSetName = 'ListOperations')]
    [switch]$ListOperations,
    [Parameter(Mandatory = $false, ParameterSetName = 'ListUsers')]
    [switch]$ListUsers
    
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "UserFolders", "Network", "Network.Hosts", "UserSettings") -Force | Out-Null

#region ListUsers ListUserOperations
function ListUsers {
    LmListObjects "Users"
}

function ListUserOperations {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    LmListObjects "users", "$UserName", "operations"
}
#endregion

function RunOperation {
    param (
        [Parameter(Mandatory = $true)] [string]$OpName,
        [Parameter(Mandatory = $false)] [hashtable]$Arguments
    )

    Write-Host "*** Run action - $OpName. ***" -ForegroundColor DarkCyan

    if ($Arguments) {
        &"$OpName" @Arguments
    }
    else {
        &"$OpName"
    }
}

function SetUserSettings {
    [CmdletBinding(DefaultParameterSetName = 'Include')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]    
        [string]$UserName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
        [array]$OnlyNames,
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
        [array]$ExcludeNames
    )

    $objects = LmGetObjects "users", "$UserName", "operations", "*"

    if (-not $objects) {
        return
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Include' {
            if ($OnlyNames) {
                $objects = $objects | Where-Object { $OnlyNames -icontains $_.Name }
            }
            break
        }
        'Exclude' {
            if ($ExcludeNames) {
                $objects = $objects | Where-Object { $ExcludeNames -inotcontains $_.Name }
            }
            break
        }
    }

    #$objects = LmSortCollectionByPropertyValue -InputObject $objects -Key "order"

    foreach ($operation in $objects) {
        $_functionName = $operation.name

        # skip if operation not a function or start with '--'
        if (-not (TestFunction -Name $_functionName) -or ($_functionName.StartsWith("--"))) {
            continue
        }

        if ($operation.ContainsKey("params")) {
            $params = $operation["params"]
        }
        else {
            $params = $null
        }
        RunOperation -OpName $_functionName -Arguments $params
    }
}

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSBoundParameters
    switch ($PSCmdlet.ParameterSetName) {
        { ($_ -eq 'Include') -or ($_ -eq 'Exclude') } {
            SetUserSettings @params
            break
        }
        'ListOperations' {
            $params.Remove("ListOperations") | Out-Null
            $params.Remove("ListUsers") | Out-Null
            ListUserOperations @params
            break
        }
        'ListUsers' {
            $params.Remove("ListOperations") | Out-Null
            $params.Remove("ListUsers") | Out-Null
            ListUsers @params
            break
        }
    }
}