Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

#.synopsis
#     Register Notepad++ shell integration
# .description
#     This script registers or unregisters the NppShell.dll for Notepad++ context menu
# .parameter ProgramFolder
#   [string] The folder where Notepad++ is installed.
# .parameter Register
#   [switch] If specified, registers the NppShell.dll for context menu integration.
# .notes
function NppRegisterShell {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProgramFolder,
        [Parameter(Mandatory = $false)]
        [Alias("u")]
        [switch]$UnRegister
    )
    $shellExePath = "$ProgramFolder/contextmenu/NppShell.dll"
    if (Test-Path $shellExePath) {
        if ($UnRegister) {
            Register-Dll -Path $shellExePath -u
        }
        else {
            Register-Dll -Path $shellExePath
        }
        return $true
    }
    else {
        Write-Host "NppShell.dll not found at $shellExePath" -ForegroundColor Red
        return $false
    }
}
