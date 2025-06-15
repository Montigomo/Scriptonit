#--Requires -RunAsAdministrator
#--Requires -Version 6.0
#--Requires -PSEdition Core

Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\Modules\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

$SettingsJsonString = @"
{
    "type": "array",
    "message": "Select parameter",
    "objects": [
        {
            "name": "Network name",
            "order": "01",
            "type": "script",
            "message": "Select network",
            "objects": "GetNetworksNames.ps1",
            "value": null
        },
        {
            "name": "IncludeHosts",
            "order": "02",
            "message": "Select hosts to prepare.",
            "type": "array",
            "objects": []
        },
        {
            "name": "ExcludeHosts",
            "order": "03",
            "message": "Select hosts to skip.",
            "type": "array",
            "objects": []
        },
        {
            "name": "InstallMSUpdates",
            "order": "22",
            "message": "Run InstallMSUpdates with selected params",
            "type": "array",
            "objects": []
        }
    ]
}
"@

$SettingsJsonString = $SettingsJsonString -replace "([^\\])\\([^\\])", '$1\\$2'


LmMenu -JsonString $SettingsJsonString