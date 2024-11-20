[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)] [string]$SetName,
    [Parameter(Mandatory = $false)] [string]$Name
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Download") | Out-Null

function DownloadItems {
    param (
        [Parameter(Mandatory = $false)] [string]$SetName,
        [Parameter(Mandatory = $false)] [string]$Name
    )

    $objects = LmGetObjects -ConfigName "Software.$SetName"

    if ($Name) {
        $objects = ($objects | Where-Object { $_."Name" -ieq $Name })
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

$params = LmGetParams -InvParams $MyInvocation.MyCommand.Parameters -PSBoundParams $PSBoundParameters

if ($params) {
    DownloadItems @params
}