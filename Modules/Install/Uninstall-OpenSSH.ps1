Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common") -Force| Out-Null

# <#
# .SYNOPSIS
#     Install OpenSsh
# .DESCRIPTION
#     Install OpenSsh
# .PARAMETER Zip
#     [Parameter(Mandatory = $false)][switch] Install from msi or zip
# .NOTES
#     Author: Agitech; Version: 0.1.0.0
function Uninstall-OpenSsh {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][switch]$UseZip,
        [Parameter(Mandatory = $false)][switch]$Force
    )
    function WinGetUninstallPackage {
        param (
            [Parameter(Mandatory = $true)]
            [string]$PackageID
        )

        winget uninstall --silent --exact --id $PackageID --all-versions

        #Uninstall-WinGetPackage -Id $PackageID -MatchOption Equals -Confirm:$false -Exact -Force -ErrorAction SilentlyContinue -Version "*"

    }
    $IsAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    if ( -not $IsAdmin) {
        Write-Error "Run as admin!"
        exit
    }
    [bool]$IsOs64 = $([System.IntPtr]::Size -eq 8);

    $programFolder = "C:\Program Files\OpenSSH"

    if (-not $IsOs64) {
        $programFolder = "C:\Program Files (x86)\OpenSSH"
    }

    $exePath = [System.IO.Path]::Combine($programFolder, "ssh.exe")
    $exePath = [System.IO.Path]::GetFullPath([System.Uri]::new($exePath).LocalPath)

    Write-Host "Going to uninstall OpenSSH_Win32." -ForegroundColor Cyan

    $services = @("sshd", "ssh-agent")

    DoServicesActions -Services $services -Action Stop

    $PackageID = "OpenSSH.Beta"

    WinGetUninstallPackage -PackageID $PackageID

    $_folders = @(
        "C:\Program Files\OpenSSH"
        "C:\ProgramData\ssh"
    )

    DeleteDirectories -FoldersArray $_folders
}