Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

<#
.SYNOPSIS
    Register Notepad++ shell integration
.DESCRIPTION
    This script registers or unregisters the NppShell.dll for Notepad++ context menu
.PARAMETER ProgramFolder
    [string] The folder where Notepad++ is installed.
.PARAMETER Unregister
    [switch] If specified, unregisters the NppShell.dll for context menu integration.
.EXAMPLE
    NppRegisterShell -ProgramFolder "C:\Program Files\Notepad++"
.EXAMPLE
    NppRegisterShell -ProgramFolder "C:\Program Files\Notepad++" -Unregister
.NOTES
    Requires the Register-Dll function from the Common module
#>
function NppRegisterShell {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (Test-Path $_ -PathType Container) { $true }
            else { throw "Path '$_' is not a valid directory" }
        })]
        [string]$ProgramFolder,
        [Parameter(Mandatory = $false)]
        [Alias("u")]
        [switch]$Unregister
    )

    # Ensure the Register-Dll function is available
    if (-not (Get-Command -Name "Register-Dll" -ErrorAction SilentlyContinue)) {
        Write-Error "Register-Dll function not found. Ensure the Common module is loaded."
        return $false
    }

    # Normalize the path and construct the DLL path
    $normalizedProgramFolder = $ProgramFolder.TrimEnd('\', '/')
    $shellDllPath = Join-Path -Path $normalizedProgramFolder -ChildPath "NppShell.dll"

    if (Test-Path -Path $shellDllPath -PathType Leaf) {
        try {
            if ($Unregister) {
                Register-Dll -Path $shellDllPath -Unregister
           }
            else {
                Register-Dll -Path $shellDllPath
            }
        }
        catch {
            Write-Error "Failed to $(if ($Unregister) { 'unregister' } else { 'register' }) NppShell.dll: $($_.Exception.Message)"
        }
    }
    else {
        Write-Error "NppShell.dll not found at: $shellDllPath"
    }
}
