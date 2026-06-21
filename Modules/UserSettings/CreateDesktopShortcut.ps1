#Requires -RunAsAdministrator

Set-StrictMode -Version 3.0


#. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Windows.Shortcuts") -Force | Out-Null


function CreateDesktopShortcut {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [array]$Arguments,
        [Parameter(Mandatory = $true)]
        [switch]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Description,
        [Parameter(Mandatory = $false)]
        [string]$IconLocation
    )

    if(-not $(Test-Function  "Set-Shortcut")) {
        Write-Host "Set-Shortcut function is not available. Please ensure the Windows.Shortcuts module is loaded." -ForegroundColor Red
        return
    }


    $_desktopPath = [Environment]::GetFolderPath("Desktop")
    $_shortcutPath = Join-Path -Path $_desktopPath -ChildPath "Network adapters.lnk"

    $params = @{
        TargetPath   = "C:\Windows\System32\rundll32.exe"
        Arguments    = "shell32.dll,Control_RunDLL ncpa.cpl"
        LinkPath     = $_shortcutPath
        Description  = "Open Network Adapters Control Panel"
        IconLocation = "%SystemRoot%\System32\SHELL32.dll,18"
    }

    Set-Shortcut @params
}

