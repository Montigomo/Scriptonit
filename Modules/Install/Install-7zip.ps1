Set-StrictMode -Version 3.0

# .SYNOPSIS
#       Install 7zip
# .DESCRIPTION
# .PARAMETER InstallFolder
#       Folder to where 7zip will be installed.
# .NOTES
#     Author: Agitech; Version: 1.00.07
function Install-7zip {
    param
    (
        [Parameter(Mandatory = $false)][string]$InstallFolder
    )

    . "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Archives", "Download") -Force | Out-Null

    #How can I install 7-Zip in silent mode?
    #For exe installer: Use the "/S" parameter to do a silent installation and the /D="C:\Program Files\7-Zip" parameter to specify the "output directory". These options are case-sensitive.
    #For msi installer: Use the /q INSTALLDIR="C:\Program Files\7-Zip" parameters.

    #region Variables

    [bool]$IsOs64 = $([System.IntPtr]::Size -eq 8)
    [version]$localVersion = [System.Version]::new(0, 0, 0)

    $filePath = Get-7zipArchiver
    $_result = $false
    $_fromGit = $true
    $requestUri = $null
    [version]$remoteVersion = [System.Version]::new(0, 0, 0)
    #endregion

    if ($filePath -and (Test-Path -Path $filePath -ErrorAction SilentlyContinue)) {
        $verinfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath)
        $null = [System.Version]::TryParse($verinfo.ProductVersion, [ref]$localVersion);
    }

    if ($_fromGit) {
        $ReleasePattern = "7z\d?\d\d?\d" # 7z2601-x64.msi

        if ($IsOs64) {
            $ReleasePattern = "$ReleasePattern-x64.msi"
        }
        else {
            $ReleasePattern = "$ReleasePattern.msi"
        }
        $item = GetGitHubItems -Uri "https://github.com/ip7z/7zip" -ReleasePattern $ReleasePattern
        if ($item) {
            $remoteVersion = $item.Version
            $requestUri = $item.Url
            $_result = $true
        }
    }
    else {
        if (-not (Get-Command "Get-ModuleAdvanced" -ErrorAction SilentlyContinue)) {
            Write-Host "Can't find function with name 'Get-ModuleAdvanced'" -ForegroundColor DarkYellow
            return $false
        }
        Get-ModuleAdvanced -ModuleName "PowerHTML"
        $htmlDoc = ConvertFrom-Html -URI "https://7-zip.org/download.html"
        $downloadUrix64 = $null
        $downloadUrix86 = $null
        $node = $htmlDoc.SelectSingleNode('/html[1]/body[1]/table[1]//tr[1]/td[2]/p[1]/b')
        if ($node) {
            $nodeText = $node.InnerText
            if ($nodeText -match "Download 7-Zip (?<version>\d\d.\d\d) \((?<date>\d\d\d\d-\d\d-\d\d)\)") {
                $remoteVersion = [System.Version]::Parse($Matches["version"]);
            }
        }
        $node = $htmlDoc.SelectSingleNode('/html/body/table/tr/td[2]/table[1]/tr[5]/td[1]/a') # msi
        if ($node -and $node.Attributes.Contains("href") ) {
            $downloadUrix64 = $node.Attributes["href"].Value
            $_result = $true
        }
        $node = $htmlDoc.SelectSingleNode('/html/body/table/tr/td[2]/table[1]/tr[6]/td[1]/a'); # msi
        if ($node -and $node.Attributes.Contains("href") ) {
            $downloadUrix86 = $node.Attributes["href"].Value
            $_result = $true
        }
        $requestUri = $downloadUrix64
        if (-not $IsOs64) {
            $requestUri = $downloadUrix86
        }
    }
    if ($_result -and $localVersion -lt $remoteVersion) {
        $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
        (New-Object System.Net.WebClient).DownloadFile("$requestUri", "$tmp")
        $PackageParams = "/q"
        Install-MsiPackage -MsiPackagePath $tmp.FullName -PackageOptions $PackageParams -IsWait
    }
    return $_result
}