[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)] [string]$NetworkName,
    [Parameter(Mandatory = $false, Position = 0)] [string]$RuleSetName
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common") | Out-Null

Get-ModuleAdvanced -ModuleName "NetSecurity"

function ImportFirewallRule {
    param (
        [Parameter(Mandatory = $false, Position = 0)] [string]$NetworkName,
        [Parameter(Mandatory = $false, Position = 0)] [string]$RuleSetName
    )

    $objects = LmGetObjects -ConfigName "Firewall.$NetworkName"

    if ($RuleSetName) {
        $objects = $objects | Where-Object { $_.RulesSetName -eq $RuleSetName }
    }

    if (-not $objects) {
        Write-Host "Not any ruleset to apply." -ForegroundColor DarkYellow
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

            New-NetFirewallRule @Params
        }
    }
}

if ($PSBoundParameters.Count -gt 0) {
    $params = LmGetParams -InvParams $MyInvocation.MyCommand.Parameters -PSBoundParams $PSBoundParameters            
    ImportFirewallRule @params
}