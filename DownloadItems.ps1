[CmdletBinding(DefaultParameterSetName = 'Include')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [Parameter(Mandatory = $false)] [string]$SetName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [string[]]$IncludeNames,
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string[]]$ExcludeNames
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Download") -Force | Out-Null

function DownloadItems {
    [CmdletBinding(DefaultParameterSetName = 'Include')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Include')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Exclude')]
        [Parameter(Mandatory = $false)] [string]$SetName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
        [string[]]$IncludeNames,
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
        [string[]]$ExcludeNames
    )

    $objects = LmGetObjects -ConfigName "Downloads",  "$SetName"

    switch ($PSCmdlet.ParameterSetName) {
        'Include' {
            if ($IncludeNames) {
                $objects = $objects | Where-Object { $IncludeNames -icontains $_.Name}
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
        switch ($object["Type"]) {
            "github" {
                $Arguments = @{
                    "GitProjectUrl"     = $object["Url"]
                    "DestinationFolder" = $object["Destination"]
                    "UsePreview"        = $object["UsePreview"]
                    "Force"             = $object["Force"]
                    "Deep"              = $object["Deep"]
                }
                if (-not $Arguments.Deep) {
                    $Arguments.Deep = 1
                }
                DownloadGitHubItems @Arguments
                break
            }
            "direct" {
                $name = $object["Url"]
                $JobName = "Download$name"
                if (TestFunction -Name $JobName) {
                    $Arguments = @{
                        "DestinationFolder" = $object["Destination"]
                    }
                    &"$JobName" @Arguments
                }
                break
            }
        }
    }
}

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSCmdlet.MyInvocation.BoundParameters
    DownloadItems @params
}