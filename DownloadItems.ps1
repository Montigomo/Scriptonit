[CmdletBinding(DefaultParameterSetName = 'Include')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListItems')]
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [string[]]$IncludeNames,
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string[]]$ExcludeNames,
    [Parameter(Mandatory = $false, ParameterSetName = 'ListItems')]
    [switch]$ListItems
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Download") -Force | Out-Null

function ListItems {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    LmListObjects -ConfigPath $ConfigPath
}

function DownloadItems {
    [CmdletBinding(DefaultParameterSetName = 'Include')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Include')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Exclude')]
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
        [string[]]$IncludeNames,
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
        [string[]]$ExcludeNames
    )

    #$IsVerbose = $PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue'
    $objects = LmGetObjects -ConfigPath @($ConfigPath, "*")

    switch ($PSCmdlet.ParameterSetName) {
        'Include' {
            if ($IncludeNames) {
                $objects = $objects | Where-Object { $IncludeNames -icontains $_.Name }
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

    foreach ($object in $objects) {
        Write-Host "Project name $($object["Name"])" -ForegroundColor Blue
        switch ($object["Type"]) {
            "github" {
                $params = $object."params"
                DownloadGitHubItems @params
                break
            }
            "direct" {
                $name = $object["JobName"]
                $JobName = "Download$name"
                if (-not (TestFunction -Name $JobName)) {
                    break
                }
                $params = $object."params"
                &"$JobName" @params
                break
            }
        }
    }
}

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSBoundParameters
    switch ($PSCmdlet.ParameterSetName) {
        { ($_ -eq 'Include') -or ($_ -eq 'Exclude') } {

            DownloadItems @params
            break
        }
        'ListItems' {
            $params.Remove("ListItems") | Out-Null
            ListItems @params
            break
        }

    }
}