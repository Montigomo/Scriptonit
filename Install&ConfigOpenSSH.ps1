#Requires -RunAsAdministrator



Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Install", "Network.sshd") -Force | Out-Null


Install-OpenSsh -UseZip -Force


#CheckSshdConfig


