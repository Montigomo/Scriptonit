Set-StrictMode -Version 3.0

function MakeSimLinks {
    param (
        [Parameter(Mandatory = $true)][hashtable]$SimLinks
    )


    Write-Host "[MakeSimLinks] started ..." -ForegroundColor Green

    foreach ($key in $SimLinks.Keys) {
        $itemPath = "$([System.Environment]::GetFolderPath("UserProfile"))$key"
        $itemDstPath = $SimLinks[$key]

        if (Test-Path $itemDstPath) {
            if ((Test-Path -Path $itemPath)) {
                $item = Get-Item "$itemPath" -ErrorAction SilentlyContinue
                if (
                    $item -and (
                    ($item.GetType() -ne [System.IO.FileInfo]) -or 
                    (-not $item.LinkType) -or 
                    (-not ($item.LinkType -eq "SymbolicLink"))) -or
                    ($item.LinkTarget -ine $itemDstPath)
                ) {
                    Write-Host "[MakeSimLinks] Simlink $itemPath found but its target path not correct. Remove it." -ForegroundColor DarkYellow
                    Remove-Item -Path $itemPath -Force -ErrorAction SilentlyContinue
                }
            }
            if (-not (Test-Path -Path $itemPath)) {
                Write-Host "[MakeSimLinks] Create simlink $itemPath." -ForegroundColor DarkGreen
                New-Item -Path $itemPath -ItemType SymbolicLink -Value $itemDstPath | Out-Null
            }
            else {
                Write-Host "[MakeSimLinks] Simlink $itemPath exists and correct." -ForegroundColor DarkGreen
            }
        }
        else {
            Write-Host "File $itemDstPath does not exist." -ForegroundColor DarkRed
        }
    }

}