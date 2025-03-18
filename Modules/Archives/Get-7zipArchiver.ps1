Set-StrictMode -Version 3.0

# .SYNOPSIS
#     Try to get path to 7zip archiver exe.
# .NOTES
#     Author : Agitech  Version : 0.0.0.1
function Get-7zipArchiver {

    $filePath = "C:\Program Files\7-Zip\7z.exe"

    if (Test-path "HKLM:\SOFTWARE\7-Zip") {
        $value = Get-ItemProperty "HKLM:\SOFTWARE\7-Zip\" -Name "Path" -ErrorAction SilentlyContinue
        if ($value) {
            $filePath = "{0}7z.exe" -f $value.Path
        }
    }

    if (-not (Test-Path $filePath)) {
        if (Test-Path -Path "$PSScriptRoot\install-7zip.ps1") {
            Import-Module -Name "$PSScriptRoot\install-7zip.ps1"
            Install-7Zip
            if (Test-path "HKLM:\SOFTWARE\7-Zip") {
                $value = Get-ItemProperty "HKLM:\SOFTWARE\7-Zip\" -Name "Path" -ErrorAction SilentlyContinue
                if ($value) {
                    $filePath = "{0}7z.exe" -f $value.Path
                }
            }
        }
        else {
            $filePath = $null
        }
    }

    return $filePath
}