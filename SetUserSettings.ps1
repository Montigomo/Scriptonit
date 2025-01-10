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

function SetUserSettings {
    [CmdletBinding(DefaultParameterSetName = 'Work')]    
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Work')]
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]    
        [string]$UserName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
        [array]$Operations,
        [Parameter(Mandatory = $true, ParameterSetName = 'List')]    
        [switch]$ListOperations
    )


    switch ($PSCmdlet.ParameterSetName) {
        'List' {
            $UserOperations = LmGetObjects -ConfigName "Users.$UserName.Operations"
            $UserOperations.Keys | Format-Table -AutoSize
            break
        }
        'Work' {
            $UserOperations = LmGetObjects -ConfigName "Users.$UserName.Operations"
            if(-not $UserOperations){
                return
            }
            $UserOperations = LmSortHashtableByPropertyValue -InputHashtable $UserOperations -Key "order"
        
            foreach ($key in $UserOperations.Keys) {
                # skip if specified operations list and item not in 
                if ((-not [System.String]::IsNullOrWhiteSpace($Operations) -and $Operations -inotcontains $key)) {
                    continue
                }                
                # skip if operation not a function or start with '--'
                if (-not (TestFunction -Name $key) -or ($key.StartsWith("--"))) {
                    continue
                }
                $operation = $UserOperations["$key"]
                if ($operation.ContainsKey("params")) {
                    $params = $operation["params"]
                }
                else {
                    $params = $null
                }
                RunOperation -OpName $key -Arguments $params
            }
            break
        }
    }

}

if ($PSBoundParameters.Count -gt 0) {
    switch ($PSCmdlet.ParameterSetName) {
        'Work' {
            SetUserSettings @PSBoundParameters
            break
        }
        'List' {
            $params = LmGetParams -InvParams $MyInvocation.MyCommand.Parameters -PSBoundParams $PSBoundParameters            
            SetUserSettings @params
            break
        }
    }
}