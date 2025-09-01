
function DeleteDirectories {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FoldersArray
    )

    foreach ($folder in $FoldersArray) {
        if (Test-Path -Path $folder) {
            Write-Host "Trying to delete $folder  folder." -ForegroundColor Cyan
            #[System.IO.Directory]::Delete($folder, $true)
            Remove-Item -Path $folder -Recurse -Force  -ErrorAction SilentlyContinue
            Write-Host "Folder $folder wiped." -ForegroundColor DarkGreen
        }
    }
}