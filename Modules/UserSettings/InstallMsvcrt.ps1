Set-StrictMode -Version 3.0

function InstallMsvcrt {

    Write-Host "[InstallMsvcrt] started ..." -ForegroundColor DarkYellow

    Get-ModuleAdvanced "Microsoft.WinGet.Client"

    $items = @(
        "Microsoft.VCRedist.2015+.x86"
        "Microsoft.VCRedist.2015+.x64"
        "Microsoft.VCRedist.2013.x86"
        "Microsoft.VCRedist.2013.x64"
        "Microsoft.VCRedist.2012.x86"
        "Microsoft.VCRedist.2012.x64"
        "Microsoft.VCRedist.2010.x86"
        "Microsoft.VCRedist.2010.x64"
        "Microsoft.VCRedist.2008.x86"
        "Microsoft.VCRedist.2008.x64"
        "Microsoft.VCRedist.2005.x86"
        "Microsoft.VCRedist.2005.x64"
    )

    foreach ($id in $items) {
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
