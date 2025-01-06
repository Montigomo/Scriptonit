Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Download") | Out-Null

# <#
# .SYNOPSIS
#     Install OpenSsh
# .DESCRIPTION
#     Install OpenSsh
# .PARAMETER Zip
#     [Parameter(Mandatory = $false)][switch] Install from msi or zip
# .NOTES
#     Author: Agitech; Version: 0.1.0.0
function Install-OpenSsh {  
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][switch]$UseZip,
        [Parameter(Mandatory = $false)][switch]$Force
    )

    $IsAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    if ( -not $IsAdmin) {
        Write-Error "Run as admin!"
        exit
    }
    $localVersion = [System.Version]::Parse("0.0.0")
    
    $gitUri = "https://api.github.com/repos/powershell/Win32-OpenSSH"
    [bool]$IsOs64 = $([System.IntPtr]::Size -eq 8);
    $exePath = if ($IsOs64) {
        "C:\Program Files\OpenSSH\ssh.exe"
    }
    else {
        "C:\Program Files (x86)\OpenSSH\ssh.exe"
    }

    if (Test-Path $exePath) {
        $vtext = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($exePath)).FileVersion
        $null = [System.Version]::TryParse($vtext, [ref]$localVersion)
    }

    if ($UseZip) {
        $ReleasePattern = if ($IsOs64) { "OpenSSH-Win64.zip" }else { "OpenSSH-Win32.zip" }
    }
    else {
        $ReleasePattern = if ($IsOs64) { "OpenSSH-Win64-v\d.\d.\d.\d.msi" }else { "OpenSSH-Win32-v\d.\d.\d.\d.msi" }
    }

    $item = GetGitHubItems -Uri $gitUri -ReleasePattern $ReleasePattern
    if ($item) {
        $downloadUri = $item.Url            
        $remoteVersion = $item.Version
        Write-Host "LocalVersion: $localVersion; RemoteVersion: $remoteVersion" -ForegroundColor DarkYellow        
        if ($remoteVersion -gt $localVersion -or $Force) {
            Write-Host "Let's install version $remoteVersion" -ForegroundColor DarkYellow
            if ($UseZip) {
                # prepare
                $services = @("sshd", "ssh-agent")
                foreach ($serviceName in $services) {
                    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                    if ($service  -and ($service.Status -eq "Running")) {
                        Stop-Service -Name $serviceName
                    }
                }
                # if ((Get-Service sshd -ErrorAction SilentlyContinue) -and ((Get-Service sshd).Status -eq "Running")) {
                #     Stop-Service sshd
                # }
                # uninstall
                $destPath = "c:\Program Files\OpenSSH\"
                if (Test-Path -Path $destPath) {
                    Remove-Item -Path "$destPath\*" -Recurse -Force
                }
                else {
                    [System.IO.Directory]::CreateDirectory($destPath) | Out-Null
                }
                $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
                Invoke-WebRequest -OutFile $tmp $downloadUri
                Add-Type -Assembly System.IO.Compression.FileSystem
                $zip = [IO.Compression.ZipFile]::OpenRead($tmp.FullName)
                $entries = $zip.Entries | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Name) } #| where {$_.FullName -like 'myzipdir/c/*' -and $_.FullName -ne 'myzipdir/c/'} 
                foreach ($entry in $entries) {
                    $dpath = $destPath + $entry.Name
                    [IO.Compression.ZipFileExtensions]::ExtractToFile( $entry, $dpath, $true)
                }
                $zip.Dispose()
                Set-EnvironmentVariable -Name 'Path' -Scope 'Machine' -Value $destPath
                $tmp | Remove-Item
                # post actions
                & "$destPath\install-sshd.ps1"
            }
            else {
                $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
                Invoke-WebRequest -OutFile $tmp $downloadUri
                Install-MsiPackage -MsiPackagePath $tmp.FullName
            }
        }
    }
    

    # remove old capabilities
    $windowsCapabilities = @("OpenSSH.Server*", "OpenSSH.Client*")
    foreach ($item  in $windowsCapabilities) {
        $caps = Get-WindowsCapability -Online | Where-Object Name -like $item
        foreach ($cap in $caps) {
            if ($cap.State -eq "Installed") {
                Remove-WindowsCapability -Online  -Name  $cap.Name
            }
        }
    }

    # change default ssh shell to powershell
    # "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwshPath -PathType Leaf) {
        if (!(Test-Path "HKLM:\SOFTWARE\OpenSSH")) {
            New-Item 'HKLM:\Software\OpenSSH' -Force
        }
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value $pwshPath -PropertyType String -Force | Out-Null
    }

    #setup service startup type and start it
    $services = @("sshd", "ssh-agent")
    foreach ($serviceName in $services) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $service | Set-Service -StartupType 'Automatic' 
            Start-Service -Name $serviceName
        }
    }
}
