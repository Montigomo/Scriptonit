Set-StrictMode -Version 3.0

function DeleteFolderExcludeSubfolders {
    param(
        [string]$Folder,
        [string[]]$ExcludeFolders
    )

    if (-not (Test-Path -Path $Folder)) {
        Write-Host "Folder '$Folder' does not exist." -ForegroundColor Red
        return
    }

    $_temp = @()
    foreach ($excludeFolder in $ExcludeFolders) {
        if (-not ($excludeFolder.StartsWith($Folder))) {
            $_temp += [System.IO.Path]::Combine($Folder, $excludeFolder).ToString()
        }else{
            $_temp += $excludeFolder
        }
    }
    $ExcludeFolders = $_temp
    $items = Get-ChildItem -Path $Folder -Recurse
    $items = $items | Where-Object {
        if ($_ -is [System.IO.DirectoryInfo]) {
            $_item = $_
            $_res = $ExcludeFolders | Where-Object { $_item.FullName.StartsWith($_) }
        }
        elseif ($_ -is [System.IO.FileInfo]) {
            $_item = $_
            $_res = $ExcludeFolders | Where-Object { $_item.DirectoryName.StartsWith($_) }
        }
        if ($null -eq $_res) {
            return $true
        }
    }
    $items = $items | Select-Object -ExpandProperty FullName
    $items = $items | Sort-Object length -Descending
    $items | Remove-Item -Recurse -Force
}