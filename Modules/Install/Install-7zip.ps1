Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Download") | Out-Null

# .SYNOPSIS
#     Install 7zip
# .DESCRIPTION
# .PARAMETER IsWait
# .PARAMETER UsePreview
# .NOTES
#     Author: Agitech; Version: 1.00.07
function Install-7zip {
    param
    (   
        [Parameter(Mandatory = $false)][string]$InstallFolder
    )

    #How can I install 7-Zip in silent mode?
    #For exe installer: Use the "/S" parameter to do a silent installation and the /D="C:\Program Files\7-Zip" parameter to specify the "output directory". These options are case-sensitive.
    #For msi installer: Use the /q INSTALLDIR="C:\Program Files\7-Zip" parameters.

    #region Variables
    
    [bool]$IsOs64 = $([System.IntPtr]::Size -eq 8)
    [version]$localVersion = [System.Version]::new(0, 0, 0)

    $filePath = "C:\Program Files\7-Zip\7z.exe"

    #endregion

    #region functions
    if (Test-path "HKLM:\SOFTWARE\7-Zip") {
        $value = Get-ItemProperty "HKLM:\SOFTWARE\7-Zip\" -Name "Path" -ErrorAction SilentlyContinue
        if ($value) {
            $filePath = "{0}7z.exe" -f $value.Path
        }
    }

    if (Test-Path $filePath) {
        $verinfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath)
        #$localVersion = $verinfo.ProductVersion
        $null = [System.Version]::TryParse($verinfo.ProductVersion, [ref]$localVersion);
    }

    if (-not (Get-Variable -Name "LogFile" -Scope Global -ErrorAction SilentlyContinue)) {
        $Logfile = "$PSScriptRoot\$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)).log"
    }

    if (-not (Get-Command "WriteLog" -ErrorAction SilentlyContinue)) {
        function WriteLog {
            Param (
                [Parameter()][string]$LogString,
                [Parameter()][switch]$WithoutFunctionName
            )
            $Stamp = Get-Date -Format "yyyy.MM.dd HH:mm:ss"
            if (-not $WithoutFunctionName) {
                $LogString = "[$((Get-PSCallStack)[1].Command)]: $LogString"
            }  
            Write-Host $LogString -ForegroundColor DarkYellow
            $LogString = "$Stamp $LogString"  
            Add-content $LogFile -value $LogString
        }
    }

    if (-not (Get-Command "Get-ModuleAdvanced" -ErrorAction SilentlyContinue)) {
        Write-Host "Can't find function with name 'Get-ModuleAdvanced'" -ForegroundColor DarkYellow
        return $false
    }

    #endregion

    Get-ModuleAdvanced -ModuleName "PowerHTML"

    $htmlDoc = ConvertFrom-Html -URI "https://7-zip.org/download.html"

    $downloadUrix64 = $null

    $downloadUri = $null

    [version]$remoteVersion = [System.Version]::new(0, 0, 0)

    $node = $htmlDoc.SelectSingleNode('/html[1]/body[1]/table[1]//tr[1]/td[2]/p[1]/b')
    if ($node) {
        $nodeText = $node.InnerText
        if ($nodeText -match "Download 7-Zip (?<version>\d\d.\d\d) \((?<date>\d\d\d\d-\d\d-\d\d)\)") {
            $remoteVersion = [System.Version]::Parse($Matches["version"]);
        }
    }
    #$node = $htmlDoc.SelectSingleNode('/html/body/table/tr/td[2]/table[1]/tr[2]/td[1]/a') # exe
    $node = $htmlDoc.SelectSingleNode('/html/body/table/tr/td[2]/table[1]/tr[5]/td[1]/a') # msi
    #$node = $htmlDoc.SelectSingleNode('/html[1]/body[1]/table[1]/tr[1]/td[2]/table[1]/tr[1]/td[1]/table[1]/tr[2]/td[1]/a[1]') # main page
    if ($node) {
        $downloadUrix64 = "https://7-zip.org/{0}" -f $node.Attributes["href"].Value
    }
    $node = $htmlDoc.SelectSingleNode('/html/body/table/tr/td[2]/table[1]/tr[6]/td[1]/a'); # msi
    #$node = $htmlDoc.SelectSingleNode('/html[1]/body[1]/table[1]/tr[1]/td[2]/table[1]/tr[1]/td[1]/table[1]/tr[3]/td[1]/a[1]') # main page
    if ($node) {
        $downloadUri = "https://7-zip.org/{0}" -f $node.Attributes["href"].Value
    }

    if ($localVersion -ge $remoteVersion) {
        return $true;
    }

    $requestUri = $downloadUrix64
    if (-not $IsOs64) {
        $requestUri = $downloadUri
    }

    $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'msi' } -PassThru
    Invoke-WebRequest -OutFile $tmp $requestUri
    $PackageParams = "/q"
    Invoke-MsiPackage -MsiPackagePath $tmp.FullName -PackageOptions $PackageParams -IsWait
    return $true
}