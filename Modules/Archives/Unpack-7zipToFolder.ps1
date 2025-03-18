Set-StrictMode -Version 3.0

# .SYNOPSIS
#     Unzip 7zip archive to folder
# .PARAMETER ArchivePath
#     [string] path to archive file
# .PARAMETER FilesToExtract
#     [string] files list
# .PARAMETER DestinationFolder
#     [switch] folder to where archive will be extracted
# .NOTES
#     Author : Agitech  Version : 0.0.0.1
# https://7-zip.opensource.jp/chm/cmdline/index.htm
function Unpack-7zipToFolder {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        [Parameter(Mandatory = $false)]
        [string]$FilesToExtract = "*",
        [Parameter(Mandatory = $true)]
        [string]$DestinationFolder
    )

    $archiverPath = Get-7zipArchiver

    $argumentString = "x -bso0 -bsp1 -bse1 -aoa $ArchivePath $filesToExtract -o""$DestinationFolder"""

    if ($archiverPath) {
        Start-Process -FilePath $archiverPath -NoNewWindow -ArgumentList $argumentString -Wait
    }
}