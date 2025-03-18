Set-StrictMode -Version 3.0

# .SYNOPSIS
#     Install far
# .DESCRIPTION
# .PARAMETER IsWait
#       wait until program will be installed
# .PARAMETER UseMsi
#       msi or 7zip used to install program
# .PARAMETER UsePreview
#       preview or release
# .NOTES
#     Author: Agitech; Version: 1.00.11
function Install-Far {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)] [switch]$IsWait,
        [Parameter(Mandatory = $false)] [switch]$UseMsi,
        [Parameter(Mandatory = $false)] [switch]$UsePreview
    )

    . "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Archives", "Download") -Force | Out-Null

    # https://forum.farmanager.com/viewtopic.php?t=9889

    $farPath = "C:\Program Files\Far Manager\Far.exe"
    $UseZip = -not $UseMsi
    if ($UseZip) {
        $farPath = "D:\software\far\Far.exe"
    }

    $farFolder = [System.IO.Path]::GetDirectoryName($farPath)

    [bool]$IsOs64 = $([System.IntPtr]::Size -eq 8)

    [version]$localVersion = [System.Version]::new(0, 0, 0)

    if (Test-Path $farPath -PathType Leaf) {
        $localVersion = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($farPath)).ProductVersion.Split(" ")[0]
    }

    [version]$remoteVersion = [System.Version]::new(0, 0, 0)
    $repoUri = "https://api.github.com/repos/FarGroup/FarManager"
    $versionPattern = "ci\/v(?<version>\d\.\d\.\d\d\d\d\.\d\d\d\d)"

    # xy : x - os type: 0-x86, 1-x64; y - installation type: 0-zip, 1-msi
    $rphash = @{
        "00" = "Far.x86.\d.\d.\d\d\d\d.\d\d\d\d.[a-z0-9]{40}.7z"
        "01" = "Far.x86.\d.\d.\d\d\d\d.\d\d\d\d.[a-z0-9]{40}.msi"
        "10" = "Far.x64.\d.\d.\d\d\d\d.\d\d\d\d.[a-z0-9]{40}.7z"
        "11" = "Far.x64.\d.\d.\d\d\d\d.\d\d\d\d.[a-z0-9]{40}.msi"
    }

    $ReleasePattern = $rphash["$([int]$IsOs64)$([int]$UseMsi.ToBool())"]

    if ([string]::IsNullOrWhiteSpace($ReleasePattern)) {
        Write-Host "Error gatting download url." -ForegroundColor DarkYellow
    }

    $object = GetGitHubItems -Uri $repoUri -ReleasePattern $ReleasePattern -VersionPattern @($versionPattern) -UsePreview:$UsePreview
    $remoteVersion = $object.Version
    $remoteVersion = [System.Version]::new($remoteVersion.Major, $remoteVersion.Minor, $remoteVersion.Build, 0)
    $downloadUri = $object.Url

    Write-Host "LocalVersion: $localVersion; RemoteVersion: $remoteVersion" -ForegroundColor DarkYellow

    if (($localVersion -lt $remoteVersion) -and ($downloadUri)) {
        Write-Host "Let's install version $remoteVersion" -ForegroundColor DarkGreen
        if ($UseZip) {
            # uninstall
            if (Test-Path -Path $farFolder) {
                Remove-Item -Path "$farFolder\*" -Recurse -Force
            }
            else {
                [System.IO.Directory]::CreateDirectory($farFolder) | Out-Null
            }

            $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru

            Invoke-WebRequest -OutFile $tmp $downloadUri

            Unpack-7zipToFolder -ArchivePath $tmp.FullName -DestinationFolder $farFolder

            $tmp | Remove-Item
            # post actions
        }
        else {
            $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
            Invoke-WebRequest -Uri $downloadUri -OutFile $tmp
            #$packageOptions = "ADDLOCAL=Colors,Macros,SetUp,Shell,XLat,Align.Changelogs,Align.FExcept,Align.Russian,_7z.dll,arclite.Changelogs,arclite.FExcept,arclite.Russian,sfx,AutoWrap.Changelogs,AutoWrap.FExcept,AutoWrap.Russian,Brackets.Changelogs,Brackets.FExcept,Brackets.Russian,Compare.Changelogs,Compare.FExcept,Compare.Russian,DrawLine.Changelogs,DrawLine.FExcept,DrawLine.Russian,EditCase.Changelogs,EditCase.FExcept,EditCase.Russian,Align,AutoWrap,Brackets,DrawLine,EditCase,EMenu.Changelogs,EMenu.FExcept,EMenu.Russian,Addons,Changelogs,Changelogs.FExcept,Docs,Docs.Russian,FExcept,FarShortcuts,Languages,Plugins,SDK,System,FARCmds.Changelogs,FARCmds.FExcept,FARCmds.Russian,FarColorer.Changelogs,FarColorer.FExcept,FarColorer.Ignore.base,FarColorer.Russian,FarColorer.Ignore.base_hrc,FarColorer.Ignore.base_hrd,FarColorer.Ignore.base_hrc_auto,FarColorer.Ignore.base_hrd_console,FarColorer.Ignore.base_hrd_css,FarColorer.Ignore.base_hrd_rgb,FarColorer.Ignore.base_hrd_text,FarProgramsShortcut,FarQuickLaunchShortcut,FarStartMenuShortcut,FileCase.Changelogs,FileCase.FExcept,FileCase.Russian,HlfViewer.Changelogs,HlfViewer.FExcept,HlfViewer.Russian,Czech,German,Hungarian,Polish,Russian,Slovak,Spanish,LuaMacro.Changelogs,LuaMacro.FExcept,LuaMacro.Russian,NetBox.Changelogs,NetBox.Russian,Network.Changelogs,Network.FExcept,Network.Russian,Compare,EMenu,Editor,FARCmds,FarColorer,FileCase,HlfViewer,LuaMacro,NetBox,Network,Proclist,SameFolder,TmpPanel,arclite,Proclist.Changelogs,Proclist.FExcept,Proclist.Russian,SameFolder.Changelogs,SameFolder.FExcept,SameFolder.Russian,Pascal,_7z.sfx,_7zCon.sfx,_7zS2.sfx,_7zS2con.sfx,_7zSD.sfx,AppPaths,FarHere,TmpPanel.Changelogs,TmpPanel.FExcept,TmpPanel.Russian"
            $packageOptions = "ADDLOCAL=ALL"
            Invoke-MsiPackage -MsiPackagePath $tmp.FullName -PackageOptions "$packageOptions" -IsWait
        }
        Set-EnvironmentVariable -Value $farFolder -Scope "Machine" -Action "Add"
    }
}