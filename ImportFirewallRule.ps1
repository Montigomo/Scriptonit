#R-equires -Version 6.0
#R-equires -PSEdition Core
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Work')]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false, ParameterSetName = 'List')]
    [Parameter(Mandatory = $false)]
    [object]$ConfigPath,
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false)]
    [string]$RuleSetName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    [Parameter(Mandatory = $false, ParameterSetName = 'List')]
    [switch]$ListRules
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

Get-ModuleAdvanced -ModuleName "NetSecurity"

#region ListFirewallRule
function ListFirewallRule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    LmListObjects -ConfigName "users", "$UserName", "firewall"
}

#endregion

function ImportFirewallRule {
    param (
        [Parameter(Mandatory = $true)]
        [object]$ConfigPath,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $objects = LmGetObjects -ConfigName $ConfigPath

    if (-not $objects) {
        Write-Host "Not any rules to apply." -ForegroundColor DarkYellow
        return
    }

    foreach ($ruleset in $objects) {
        $RuleSetName = $ruleset.RulesSetName
        foreach ($rule in $ruleset.Objects) {
            $RuleName = $rule.RuleName

            $Params = @{}
            foreach ($item in $rule.RuleParams.GetEnumerator()) {
                $key = $item.Key
                $value = $item.Value
                $value = $value -replace "{RulesSetName}", $RuleSetName
                $value = $value -replace "{RuleName}", $RuleName
                $Params[$key] = $value
            }

            $RuleName = $Params["Name"]
            $rule = Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
            if($rule){
                if($Force){
                    Write-Host "NetFireWall Rule with name $RuleName already exist. Removing it." -ForegroundColor DarkYellow
                    Remove-NetFirewallRule -Name $RuleName | Out-Null
                }
                else{
                    Write-Host "NetFireWall Rule with name $RuleName  already exist." -ForegroundColor DarkYellow
                    continue
                }
            }

            New-NetFirewallRule @Params | Out-Null
            Write-Host "NetFireWall Rule $RuleName added succesefully." -ForegroundColor DarkYellow
        }
    }
}

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSCmdlet.MyInvocation.BoundParameters
    switch ($PSCmdlet.ParameterSetName) {
        'Work' {
            ImportFirewallRule @params
            break
        }
        'List' {
            $params.Remove("ListRules")
            ListFirewallRule @params
            break
        }
    }
}