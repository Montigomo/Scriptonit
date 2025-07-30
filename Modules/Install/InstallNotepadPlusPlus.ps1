Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Archives", "Download") -Force | Out-Null

function InstallNppShell {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$DestinationFolder = "D:\software\notepad++",
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $IsAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

    if ( -not $IsAdmin) {
        Write-Error "Run as admin!"
        exit
    }

    [version]$localVersion = [System.Version]::Parse("0.0.0")
    [version]$remoteVersion = [System.Version]::new(0, 0, 0)
    [bool]$IsOs64 = $([System.IntPtr]::Size -eq 8);
    $programFolder = "$DestinationFolder\contextmenu"
    $programExePath = "$programFolder\NppShell.dll"

    if (Test-Path $programExePath) {
        $vtext = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($programExePath)).ProductVersion.Split(" ")[0]
        $null = [System.Version]::TryParse($vtext, [ref]$localVersion)
    }

    #$versionPattern = "\d?\d.\d?\d.\d?\d"

    if ($IsOs64) {
        $ReleasePattern = "^NppShell.x64.7z$"
    }
    else {
        $ReleasePattern = "^NppShell.7z$"
    }

    $object = GetGitHubItems -Uri "https://github.com/Montigomo/NppShell" -ReleasePattern $ReleasePattern
    if (-not $object) {
        Write-Host "No releases found for Notepad++" -ForegroundColor Red
        return
    }
    $remoteVersion = $object.Version
    $downloadUri = $object.Url

    Write-Host "NppShell: LocalVersion: $localVersion; RemoteVersion: $remoteVersion" -ForegroundColor DarkYellow

    if (($localVersion -lt $remoteVersion) -and ($downloadUri)) {
        Write-Host "Let's install version $remoteVersion" -ForegroundColor DarkGreen

        if (-not (Test-Path -Path $programFolder)) {
            [System.IO.Directory]::CreateDirectory($programFolder) | Out-Null
        }
        $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru

        Invoke-WebRequest -OutFile $tmp $downloadUri

        Unpack-7zipToFolder -ArchivePath $tmp.FullName -DestinationFolder $programFolder

        $tmp | Remove-Item
    }


}



function InstallNotepadPlusPlus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$DestinationFolder = "D:\software\notepad++",
        [Parameter(Mandatory = $false)]
        [switch]$IsWait,
        [Parameter(Mandatory = $false)]
        [switch]$UseMsi,
        [Parameter(Mandatory = $false)]
        [switch]$UsePreview
    )

    $IsAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

    if ( -not $IsAdmin) {
        Write-Error "Run as admin!"
        exit
    }

    [version]$localVersion = [System.Version]::Parse("0.0.0")
    [version]$remoteVersion = [System.Version]::new(0, 0, 0)
    [bool]$IsOs64 = $([System.IntPtr]::Size -eq 8);
    $UseZip = -not $UseMsi
    $programFolder = "$DestinationFolder"
    $programExePath = "$programFolder\notepad++.exe"


    # if (-not (Test-Path $programExePath)) {
    #     if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions\31ab5147-9a97-4452-8443-d9709f0516e1" -ErrorAction SilentlyContinue) {
    #         $programExePath = "{0}pwsh.exe" -f (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions\31ab5147-9a97-4452-8443-d9709f0516e1\" -Name "InstallLocation").InstallLocation
    #     }
    # }

    if (Test-Path $programExePath) {
        $vtext = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($programExePath)).ProductVersion.Split(" ")[0]
        $null = [System.Version]::TryParse($vtext, [ref]$localVersion)
    }

    $versionPattern = "\d?\d.\d?\d.\d?\d"

    if ($IsOs64) {
        $ReleasePattern = "^npp.$versionPattern.portable.x64.7z$"
    }
    else {
        $ReleasePattern = "^npp.$versionPattern.portable.7z$"
    }

    $object = GetGitHubItems -Uri "https://github.com/notepad-plus-plus/notepad-plus-plus" -ReleasePattern $ReleasePattern

    if (-not $object) {
        Write-Host "No releases found for Notepad++" -ForegroundColor Red
        return
    }

    $remoteVersion = $object.Version
    $downloadUri = $object.Url

    Write-Host "LocalVersion: $localVersion; RemoteVersion: $remoteVersion" -ForegroundColor DarkYellow

    if (($localVersion -lt $remoteVersion) -and ($downloadUri)) {
        Write-Host "Let's install version $remoteVersion" -ForegroundColor DarkGreen
        if ($UseZip) {
            # uninstall
            if (Test-Path -Path $programFolder) {
                DoProcessActions -Name $programExePath -ExePath
                if (NppRegisterShell -ProgramFolder $programFolder -u) {
                    RestartExplorer
                }
                try {
                    Remove-Item -Path "$programFolder\*" -Recurse -Force
                }
                catch {
                    Write-Host "Can't remove $programFolder, please close Notepad++ and try again." -ForegroundColor Red
                    return
                }
            }
            else {
                [System.IO.Directory]::CreateDirectory($programFolder) | Out-Null
            }

            $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru

            Invoke-WebRequest -OutFile $tmp $downloadUri

            Unpack-7zipToFolder -ArchivePath $tmp.FullName -DestinationFolder $programFolder

            $tmp | Remove-Item
        }
        else {
            $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
            Invoke-WebRequest -Uri $downloadUri -OutFile $tmp
            Invoke-MsiPackage -MsiPackagePath $tmp.FullName -PackageOptions "$packageOptions" -IsWait
        }
        Set-EnvironmentVariable -Value $programFolder -Scope "Machine" -Action "Add"
    }

    InstallNppShell -DestinationFolder $programFolder -Force:$Force
    NppRegisterShell -ProgramFolder $programFolder
}
