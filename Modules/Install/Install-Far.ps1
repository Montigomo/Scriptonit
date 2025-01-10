Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Download") | Out-Null

# .SYNOPSIS
#     Install far
# .DESCRIPTION
# .PARAMETER IsWait
# .PARAMETER UsePreview
# .NOTES
#     Author: Agitech; Version: 1.00.11
function Install-Far {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)] [switch]$IsWait,
        [Parameter(Mandatory = $false)] [switch]$UsePreview
    )

    $farPath = "C:\Program Files\Far Manager\Far.exe";
    $farFolder = [System.IO.Path]::GetDirectoryName($farPath);
    [bool]$IsOs64 = $([System.IntPtr]::Size -eq 8);
    
    [version]$localVersion = [System.Version]::new(0, 0, 0)

    if (Test-Path $farPath) {
        $localVersion = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($farPath)).ProductVersion.Split(" ")[0]
    }

    [version]$remoteVersion = [System.Version]::new(0, 0, 0)
    $repoUri = "https://api.github.com/repos/FarGroup/FarManager"
    $versionPattern = "ci\/v(?<version>\d\.\d\.\d\d\d\d\.\d\d\d\d)"
    $ReleasePattern = if ($IsOs64) { "Far.x64.\d.\d.\d\d\d\d.\d\d\d\d.[a-z0-9]{40}.msi" }else { "Far.x86.\d.\d.\d\d\d\d.\d\d\d\d.[a-z0-9]{40}.msi" }

    $object = GetGitHubItems -Uri $repoUri -ReleasePattern $ReleasePattern -VersionPattern @($versionPattern) -UsePreview:$UsePreview
    $remoteVersion = $object.Version
    $remoteVersion = [System.Version]::new($remoteVersion.Major, $remoteVersion.Minor, $remoteVersion.Build, 0)
    $downloadUri = $object.Url

    Write-Host "LocalVersion: $localVersion; RemoteVersion: $remoteVersion" -ForegroundColor DarkYellow

    if (($localVersion -lt $remoteVersion) -and ($downloadUri)) {
        Write-Host "Let's install version $remoteVersion" -ForegroundColor DarkGreen
        $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
        Invoke-WebRequest -Uri $downloadUri -OutFile $tmp
        Invoke-MsiPackage -MsiPackagePath $tmp.FullName -PackageOptions "ADDLOCAL=ALL" -IsWait
        Set-EnvironmentVariable -Value $farFolder -Scope "Machine" -Action "Add"
    }
}