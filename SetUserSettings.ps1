#Requires -Version 6.0
#Requires -PSEdition Core
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Work')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false, ParameterSetName = 'List')]    
    [string]$UserName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [array]$Operations,
    [Parameter(Mandatory = $false, ParameterSetName = 'List')]    
    [switch]$ListOperations
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


function ListUserSettings {
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
    #$params = LmGetParams -InvocationParams $MyInvocation.MyCommand.Parameters -PSBoundParams $PSBoundParameters
    $params = $PSCmdlet.MyInvocation.BoundParameters
    switch ($PSCmdlet.ParameterSetName) {
        'Work' {
            SetUserSettings @params
            break
        }
        'List' {
            $params.Remove("ListOperations") | Out-Null
            ListUserSettings @params
            break
        }
    }
}