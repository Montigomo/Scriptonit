#Requires -RunAsAdministrator
#--Requires -Version 6.0
#--Requires -PSEdition Core

Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\Modules\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

LmMenu -JsonFilePath "main"