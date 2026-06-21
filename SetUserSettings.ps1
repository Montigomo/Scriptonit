#Requires -RunAsAdministrator
#--Requires -Version 6.0
#--Requires -PSEdition Core
[CmdletBinding(DefaultParameterSetName = 'ConfigPath')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigPath')]
    [string]$ConfigPath,
    [Parameter(Mandatory = $false, ParameterSetName = 'CommonUsers')]
    [array]$UserName,
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigPath')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CommonUsers')]
    [array]$Actions,
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigPath')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CommonUsers')]
    [switch]$Exclude,
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigPath')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CommonUsers')]
    [switch]$ListOperations,
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigPath')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CommonUsers')]
    [switch]$ListUsers

)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "UserFolders", "Network", "Network.Hosts", "UserSettings") -Force | Out-Null

#region ListUsers ListUserOperations
function ListUsers {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    LmListObjects -ConfigPath  @("$ConfigPath")
}

function ListUserOperations {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    LmListObjects -ConfigPath @("$ConfigPath", "operations", "*") -PropertyName "name" -OrderPropertyName "order"
}
#endregion

#region SetUserSettings
function SetUserSettings {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        [Parameter(Mandatory = $false)]
        [array]$Actions,
        [Parameter(Mandatory = $false)]
        [switch]$Exclude
    )

    $objects = LmGetObjects -ConfigPath @("$ConfigPath", "operations", "*")  -OrderPropertyName "order"

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

#endregion

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSBoundParameters
    $_paramSetName = $PSCmdlet.ParameterSetName


    if ($ListUsers) {
        if (-not $params.ContainsKey("ConfigPath")) {
            $params.Add("ConfigPath", "users")
        }
        $params.Remove("ListOperations") | Out-Null
        $params.Remove("ListUsers") | Out-Null
        ListUsers @params
    }
    else {
        if (-not $params.ContainsKey("ConfigPath") -and -not $params.ContainsKey("UserName")) {
            Write-Host "Please specify either ConfigPath or UserName parameter." -ForegroundColor Red
        }
        else {
            if (-not $params.ContainsKey("ConfigPath")) {
                $params.Add("ConfigPath", "users.$UserName")

            }
            $params.Remove("UserName") | Out-Null
            $params.Remove("ListOperations") | Out-Null
            $params.Remove("ListUsers") | Out-Null
            if ($ListOperations) {
                ListUserOperations @params
            }
            else {
                SetUserSettings @params
            }
        }
    }
}