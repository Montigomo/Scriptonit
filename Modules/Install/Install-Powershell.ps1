Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Download") -Force | Out-Null

# .SYNOPSIS
#     Install latest Powershell core
# .DESCRIPTION
#   Install latest Powershell core
#   [version : 1.0.1.0]
# .PARAMETER IsWait
#     [switch] Waits for the installation process to complete
# .PARAMETER UsePreview
#     [switch] Use or not beta versions
# .NOTES
#     Author: Agitech; Version: 0.1.0.0
function Install-Powershell {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)] [switch]$IsWait,
        [Parameter(Mandatory = $false)] [switch]$UsePreview
    )

    # https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5

    $IsAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    if ( -not $IsAdmin) {
        Write-Error "Run as admin!"
        exit
    }
    [version]$localVersion = [System.Version]::Parse("0.0.0")
    [version]$remoteVersion = [System.Version]::new(0, 0, 0)

    [bool]$IsOs64 = $([System.IntPtr]::Size -eq 8);
    # check pwsh and get it version
    $pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (-not (Test-Path $pwshPath)) {
        if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions\31ab5147-9a97-4452-8443-d9709f0516e1" -ErrorAction SilentlyContinue) {
            $pwshPath = "{0}pwsh.exe" -f (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions\31ab5147-9a97-4452-8443-d9709f0516e1\" -Name "InstallLocation").InstallLocation
        }
    }
    if (Test-Path $pwshPath) {
        $vtext = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($pwshPath)).ProductVersion.Split(" ")[0]
        $null = [System.Version]::TryParse($vtext, [ref]$localVersion)
    }
    else {
        $localVersion = $PSVersionTable.PSVersion
    }

    #region Release pattern

    # PowerShell-7.4.10-win-arm64.exe
    # PowerShell-7.4.10-win-arm64.msi
    # PowerShell-7.4.10-win-arm64.zip
    # PowerShell-7.4.10-win-fxdependent.zip
    # PowerShell-7.4.10-win-fxdependentWinDesktop.zip
    # PowerShell-7.4.10-win-x64.exe
    # PowerShell-7.4.10-win-x64.msi
    # PowerShell-7.4.10-win-x64.zip
    # PowerShell-7.4.10-win-x86.exe
    # PowerShell-7.4.10-win-x86.msi
    # PowerShell-7.4.10-win-x86.zip
    # PowerShell-7.4.10.msixbundle

    $ReleasePattern = "PowerShell-\d?\d.\d?\d.\d?\d"

    if ($IsOs64) {
        $ReleasePattern = "$ReleasePattern-win-x64.msi"
    }
    else {
        $ReleasePattern = "$ReleasePattern-win-x86.msi"

    }

    #endregion

    $item = GetGitHubItems -Uri "https://api.github.com/repos/powershell/powershell/" -ReleasePattern $ReleasePattern

    if ($item) {

        $remoteVersion = $item.Version
        $downloadUri = $item.Url
        Write-Host "LocalVersion: $localVersion; RemoteVersion: $remoteVersion" -ForegroundColor DarkYellow
        if ($remoteVersion -gt $localVersion) {
            Write-Host "Let's install version $remoteVersion" -ForegroundColor DarkGreen
            $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
            Invoke-WebRequest -OutFile $tmp $downloadUri
            $packageOptions = "ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1"
            Invoke-MsiPackage -MsiPackagePath $tmp.FullName -PackageOptions $packageOptions -IsWait:$IsWait
        }
    }
}