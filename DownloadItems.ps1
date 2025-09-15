[CmdletBinding(DefaultParameterSetName = 'Only')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Only')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [Parameter(Mandatory = $false)] [string]$UserName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Only')]
    [string[]]$OnlyNames,
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string[]]$ExcludeNames
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Download") -Force | Out-Null

function DownloadItems {
    [CmdletBinding(DefaultParameterSetName = 'Only')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Only')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Exclude')]
        [Parameter(Mandatory = $false)] [string]$UserName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Only')]
        [string[]]$OnlyNames,
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
        [string[]]$ExcludeNames
    )
    $IsVerbose = $PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue'
    $objects = LmGetObjects "users", "$UserName", "downloads"

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
    $params = $PSCmdlet.MyInvocation.BoundParameters
    DownloadItems @params
}