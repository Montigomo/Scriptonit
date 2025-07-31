Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Archives", "Download", "Install") -Force | Out-Null

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
    $nppExePath = "$DestinationFolder\notepad++.exe"

    if (Test-Path $programExePath) {
        $vtext = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($programExePath)).ProductVersion.Split(" ")[0]
        $null = [System.Version]::TryParse($vtext, [ref]$localVersion)
    }

    if ($IsOs64) {
        $ReleasePattern = "^NppShell.x64.7z$"
    }
    else {
        $ReleasePattern = "^NppShell.7z$"
    }

    $object = GetGitHubItems -Uri "https://github.com/Montigomo/NppShell" -ReleasePattern $ReleasePattern
    if (-not $object) {
        Write-Host "No releases found for NppShell." -ForegroundColor Red
        return
    }
    $remoteVersion = $object.Version
    $downloadUri = $object.Url

    Write-Host "NppShell: LocalVersion: $localVersion; RemoteVersion: $remoteVersion" -ForegroundColor DarkYellow

    if (($localVersion -lt $remoteVersion) -and ($downloadUri)) {
        Write-Host "Let's install version $remoteVersion" -ForegroundColor DarkGreen
        DoProcessActions -Name $nppExePath -ExePath
        if (-not (Test-Path -Path $programFolder)) {
            [System.IO.Directory]::CreateDirectory($programFolder) | Out-Null
        }
        else {
            if (IsComRegistered -Guid "{B298D29A-A6ED-11DE-BA8C-A68E55D89593}" -DllPath $programExePath) {
                NppRegisterShell -ProgramFolder $programFolder -Unregister
                RestartExplorer
                Start-Sleep -Seconds 1
            }
            try {
                Remove-Item -Path "$programFolder\*" -Recurse -Force -ErrorAction Stop
            }
            catch {
                Write-Host "Can't remove $programFolder, please close Notepad++ and try again." -ForegroundColor Red
                return
            }
        }
        $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
        Invoke-WebRequest -OutFile $tmp $downloadUri
        Unpack-7zipToFolder -ArchivePath $tmp.FullName -DestinationFolder $programFolder
        $tmp | Remove-Item
    }
    if (-not (IsComRegistered -Guid "{B298D29A-A6ED-11DE-BA8C-A68E55D89593}" -DllPath $programExePath)) {
        NppRegisterShell -ProgramFolder $programFolder
    }
}