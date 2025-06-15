#--Requires -RunAsAdministrator
#--Requires -Version 6.0
#--Requires -PSEdition Core

Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\Modules\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

$items = LmGetObjects -ConfigName "Networks"
$items = $items | Select-Object -ExpandProperty "name"
if (-not $items) {
    return
}
$_objects = @()
foreach ($item in $items) {
    $_object = @{
        "name"  = $item
        "type" = "value"
        "value" = $item
    }
    $_objects += $_object
}

return $_objects