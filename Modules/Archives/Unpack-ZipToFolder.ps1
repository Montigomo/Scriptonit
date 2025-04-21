Set-StrictMode -Version 3.0

# .SYNOPSIS
#     Unzip zip archive to folder
# .PARAMETER MsiPackagePath
#     [string] path to msi package
# .PARAMETER PackageOptions
#     [string] specific msi package options
# .PARAMETER IsWait
#     [switch] wait untill msi executed
# .NOTES
#     Author : Agitech  Version : 0.0.0.1
# https://learn.microsoft.com/en-us/windows/win32/msi/command-line-options
function Unpack-ZipToFolder {
    param
    (
        [Parameter(Mandatory = $true)]  [string]$ZipArchivePath,
        [Parameter(Mandatory = $true)]  [string]$DestinationFolder
    )

    Add-Type -Assembly System.IO.Compression.FileSystem

    $zip = [IO.Compression.ZipFile]::OpenRead($ZipArchivePath)

    $entries = $zip.Entries | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Name) } #| where {$_.FullName -like 'myzipdir/c/*' -and $_.FullName -ne 'myzipdir/c/'}

    foreach ($entry in $entries) {

        $DestinationPath = [System.IO.Path]::Combane($DestinationFolder, $entry.Name)

        [IO.Compression.ZipFileExtensions]::ExtractToFile( $entry, $DestinationPath, $true)

    }

    $zip.Dispose()
}