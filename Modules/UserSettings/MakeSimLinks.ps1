Set-StrictMode -Version 3.0

function MakeSimLinks {
    param (
        [Parameter(Mandatory = $true)][hashtable]$SimLinks
    )

    Write-Host "[MakeSimLinks] started ..." -ForegroundColor DarkYellow


    foreach ($key in $SimLinks.Keys) {

        $itemSrcPath = MakeSubstitutions -SubsString $key

        $itemDstPath = $SimLinks[$key]

        if (Test-Path $itemDstPath) {
            if ((Test-Path -Path $itemSrcPath)) {
                $item = Get-Item "$itemSrcPath" -ErrorAction SilentlyContinue
                if (
                    $item -and (
                    ($item.GetType() -ne [System.IO.FileInfo]) -or 
                    (-not $item.LinkType) -or 
                    (-not ($item.LinkType -eq "SymbolicLink"))) -or
                    ($item.LinkTarget -ine $itemDstPath)
                ) {
                    Write-Host "[MakeSimLinks] Simlink $itemSrcPath found but its target path not correct. Remove it." -ForegroundColor DarkYellow
                    Remove-Item -Path $itemSrcPath -Force -ErrorAction SilentlyContinue
                }
            }
            if (-not (Test-Path -Path $itemSrcPath)) {
                Write-Host "[MakeSimLinks] Create simlink $itemSrcPath." -ForegroundColor DarkGreen
                New-Item -Path $itemSrcPath -ItemType SymbolicLink -Value $itemDstPath | Out-Null
            }
            else {
                Write-Host "[MakeSimLinks] Simlink $itemSrcPath exists and correct." -ForegroundColor DarkGreen
            }
        }
        else {
            Write-Host "File $itemDstPath does not exist." -ForegroundColor DarkRed
        }
    }

}