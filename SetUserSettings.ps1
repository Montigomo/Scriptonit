#Requires -RunAsAdministrator
#--Requires -Version 6.0
#--Requires -PSEdition Core

[CmdletBinding(DefaultParameterSetName = 'Work')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListOperations')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListUsers')]
    [string]$UserName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [array]$Operations,
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
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        [Parameter(Mandatory = $false)]
        [array]$Operations
    )

    $objects = LmGetObjects "users", "$UserName", "operations"

    if (-not $objects) {
        return
    }

    $objects = LmSortCollectionByPropertyValue -InputObject $objects -Key "order"

    foreach ($operation in $objects) {
        $_functionName = $operation.name

        # skip if specified operations list and item not in
        if ((-not [System.String]::IsNullOrWhiteSpace($Operations) -and $Operations -inotcontains $_functionName)) {
            continue
        }
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
        'Work' {
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