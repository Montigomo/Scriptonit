#--Requires -Version 6.0
#--Requires -PSEdition Core
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Work')]
param (
	[Parameter(Mandatory = $false, ParameterSetName = 'Work')]
	[Parameter(Mandatory = $false, ParameterSetName = 'ListServers')]
	[string]$ConfigPath,
	[Parameter(Mandatory = $false, ParameterSetName = 'ListServers')]
	[switch]$ListServers
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Backup", "Network") -Force | Out-Null


function BackuperListServers {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ConfigPath
	)
	LmListObjects -ConfigPath @($ConfigPath, "*") -PropertyName "servername"
}


if ($PSBoundParameters.Count -gt 0) {
	$params = $PSBoundParameters
	switch ($PSCmdlet.ParameterSetName) {
		'Work' {
			BackuperMakeBackup @params
			break
		}
		'ListServers' {
			$params.Remove('ListServers') | Out-Null
			BackuperListServers @params
			break
		}
	}
}
