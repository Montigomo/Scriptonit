Set-StrictMode -Version 3.0

<#
.SYNOPSIS
Restarts the Windows Explorer process.

.DESCRIPTION
This function stops and restarts the Windows Explorer process, which can be useful for applying changes to the desktop or taskbar.

.EXAMPLE
RestartExplorer

This will restart the Windows Explorer process.
#>

function RestartExplorer {
    Write-Host "Restarting Windows Explorer..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Start-Process explorer
}