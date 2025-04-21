Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Network.Hosts") | Out-Null

function InstallApplications {
    param (
        [Parameter(Mandatory = $true)][array]$Applications
    )

    Get-ModuleAdvanced "Microsoft.WinGet.Client"

    Write-Host "[InstallApplications] started ..." -ForegroundColor DarkYellow

    # [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    # # winget now outputs UTF-8 e.g. for '…' in the 'Available' column, we need to account for this
    # [Console]::InputEncoding = [Console]::OutputEncoding = $InputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    # # get rid of PSSA warning
    # $null = $InputEncoding

    foreach ($id in $Applications) {
        if( $id.StartsWith("--")){
            continue
        }
        $packageLocal = Get-WinGetPackage -Id $id -MatchOption Equals
        $packageRemote = Find-WinGetPackage -Id $id -MatchOption Equals

        if (-not $packageLocal) {
            Write-Host "Package with id " -ForegroundColor DarkYellow -NoNewline
            Write-Host """$id"" " -ForegroundColor DarkGreen -NoNewline
            Write-Host "not installed." -ForegroundColor DarkYellow
            Install-WinGetPackage -Id $id -Mode Silent -Source "winget" -MatchOption Equals | Out-Null
            continue
        }

        if(-not $packageRemote){
             Write-Host "Can't find Package with id " -ForegroundColor DarkYellow -NoNewline
            Write-Host """$id""." -NoNewline -ForegroundColor DarkGreen
            continue
        }

        Write-Host "Package" -ForegroundColor DarkYellow -NoNewline
        Write-Host """$id"" " -ForegroundColor DarkGreen -NoNewline
        Write-Host "local version: " -ForegroundColor DarkYellow -NoNewline
        Write-Host "$($packageLocal.InstalledVersion), " -ForegroundColor DarkCyan -NoNewline
        Write-Host "remove version: " -ForegroundColor DarkYellow -NoNewline
        Write-Host "$($packageRemote.Version)." -ForegroundColor DarkCyan

        if($packageLocal.IsUpdateAvailable){
             Write-Host "The Package " -ForegroundColor DarkYellow -NoNewline
             Write-Host """$id"" " -ForegroundColor DarkGreen -NoNewline
             Write-Host "needs to be updated." -ForegroundColor DarkYellow
             Update-WinGetPackage -Id $id -Mode Silent -Force -Source "winget" | Out-Null
             continue
        }
    }
}