#Requires -RunAsAdministrator
#--Requires -Version 6.0
#--Requires -PSEdition Core
[CmdletBinding(DefaultParameterSetName = 'Operate')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'ListOperations')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListUsers')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Operate')]
    [string]$ConfigPath,
    [Parameter(Mandatory = $false, ParameterSetName = 'Operate')]
    [array]$Actions,
    [Parameter(Mandatory = $false, ParameterSetName = 'Operate')]
    [switch]$Exclude,
    [Parameter(Mandatory = $false, ParameterSetName = 'ListOperations')]
    [switch]$ListOperations,
    [Parameter(Mandatory = $false, ParameterSetName = 'ListUsers')]
    [switch]$ListUsers

)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "UserFolders", "Network", "Network.Hosts", "UserSettings") -Force | Out-Null

#region ListUsers ListUserOperations
function ListUsers {
    LmListObjects $ConfigPath, "users"
}

function ListUserOperations {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    LmListObjects $ConfigPath, "operations", "*"
}
#endregion

function SetUserSettings {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        [Parameter(Mandatory = $false)]
        [array]$Actions,
        [Parameter(Mandatory = $false)]
        [switch]$Exclude
    )

    $objects = LmGetObjects -ConfigPath @("$ConfigPath", "operations", "*")

    if (-not $objects) {
        return
    }

    if ($Actions) {
        if ($Exclude) {
            $objects = @($objects | Where-Object { $Actions -inotcontains $_.Name })
        }
        else {
            $objects = @($objects | Where-Object { $Actions -icontains $_.Name })
        }
    }

    foreach ($operation in $objects) {
        $_functionName = $operation.name
        $_params = $null
        $_modules = $null

        if ($_functionName.StartsWith("--")) {
            Write-Host "Skip operation - $_functionName." -ForegroundColor Yellow
            continue
        }

        if ($operation.ContainsKey("params")) {
            $_params = $operation["params"]
        }

        if ($operation.ContainsKey("modules")) {
            $_modules = $operation["modules"]
        }

        if ($_modules) {
            . "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames $_modules | Out-Null
        }

        if (-not (TestFunction -Name $_functionName) -and -not (Get-Command $_functionName -errorAction SilentlyContinue)) {
            Write-Host "Function - $_functionName not found." -ForegroundColor Red
            continue
        }

        Write-Host "*** Run action - $_functionName. ***" -ForegroundColor DarkCyan

        if ($_params) {
            &"$_functionName" @_params
        }
        else {
            &"$_functionName"
        }
    }
}

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSBoundParameters
    switch ($PSCmdlet.ParameterSetName) {
        { ($_ -eq 'Operate') -or ($_ -eq 'Operate') } {
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