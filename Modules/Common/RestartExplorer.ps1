Set-StrictMode -Version 3.0

function RestartExplorer {
    <#
    .SYNOPSIS
    Restarts the Windows Explorer process.

    .DESCRIPTION
    This function stops and restarts the Windows Explorer process, which can be useful for applying changes to the desktop or taskbar.

    .EXAMPLE
    RestartExplorer

    This will restart the Windows Explorer process.
    #>

    Write-Host "Restarting Windows Explorer..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer
}