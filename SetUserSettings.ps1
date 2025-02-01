#Requires -Version 6.0
#Requires -PSEdition Core
#Requires -RunAsAdministrator
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

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "UserFolders", "Network", "UserSettings") -Force | Out-Null

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

    #Invoke-Expression "$OpName $Arguments"
}

function ListUsers {
    $objects = LmGetObjects -ConfigName "Users"
    $objects | Format-Table -AutoSize
}

function ListUserOperations {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )

    $objects = LmGetObjects -ConfigName "Users.$UserName.Operations"
    $objects | Format-Table -AutoSize
}


function SetUserSettings {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        [Parameter(Mandatory = $false)]
        [array]$Operations
    )

    $objects = LmGetObjects -ConfigName "Users.$UserName.Operations"

    if (-not $objects) {
        return
    }

    $objects = LmSortHashtableByPropertyValue -InputHashtable $objects -Key "order"

    foreach ($key in $objects.Keys) {
        # skip if specified operations list and item not in
        if ((-not [System.String]::IsNullOrWhiteSpace($Operations) -and $Operations -inotcontains $key)) {
            continue
        }
        # skip if operation not a function or start with '--'
        if (-not (TestFunction -Name $key) -or ($key.StartsWith("--"))) {
            continue
        }
        $operation = $objects["$key"]
        if ($operation.ContainsKey("params")) {
            $params = $operation["params"]
        }
        else {
            $params = $null
        }
        RunOperation -OpName $key -Arguments $params
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