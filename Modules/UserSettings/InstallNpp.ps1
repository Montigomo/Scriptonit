Set-StrictMode -Version 3.0

function InstallNpp {

    Write-Host "[InstallNpp] started ..." -ForegroundColor DarkYellow

    Get-ModuleAdvanced "Microsoft.WinGet.Client"

    InstallNotepadPlusPlus
}