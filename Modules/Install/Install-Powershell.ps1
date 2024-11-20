Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Download") | Out-Null

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

    . "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Download") | Out-Null

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
    $ReleasePattern = if ($IsOs64) { "PowerShell-\d.\d.\d-win-x64.msi" } else { "PowerShell-\d.\d.\d-win-x86.msi" }

    $item = GetGitHubItems -Uri "https://api.github.com/repos/powershell/powershell/" -ReleasePattern $ReleasePattern

    if ($item) {
        
        $remoteVersion =$item.Version
        $downloadUri = $item.Url
        Write-Host "Updating pwsh. Local version $localVersion  Remote version $remoteVersion." -ForegroundColor DarkGreen
        $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
        Invoke-WebRequest -OutFile $tmp $downloadUri

        Invoke-MsiPackage -MsiPackagePath $tmp.FullName -PackageOptions $packageOptions -IsWait:$msiIsWait       

    }
}