Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

#region functions

function DownloadFromJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DestinationFolder,
        [Parameter(Mandatory = $true)]
        [hashtable]$RootObject
    )

    $root = $RootObject

    #region Download

    foreach ($key in $root.Keys) {

        $folderPath = $DestinationFolder

        if (-not(Test-Path $folderPath -PathType Container)) {
            New-Item -Path $folderPath -ItemType Directory | Out-Null
        }
        if ($key -ne ".") {
            $folderPath = [System.IO.Path]::Combine($DestinationFolder, $key)
        }
        else {
            $folderPath = $DestinationFolder
        }

        if (-not(Test-Path $folderPath -PathType Container)) {
            New-Item -Path $folderPath -ItemType Directory | Out-Null
        }

        $object = $root[$key]

        if ($object -is [Hashtable] -or $object.GetType().Name -eq 'OrderedDictionary') {
            DownloadFromJson -DestinationFolder $folderPath -RootObject $object
        }
        else {
            foreach ($item in $object) {

                [uri]$url = $null

                $result = $false

                if ($item -is [uri]) {
                    $result = $true
                    $url = $item
                }
                elseif ($item -is [string]) {
                    $result = [uri]::TryCreate($item, [UriKind]::Absolute, [ref]$url)
                }

                if ($result) {
                    $fileName = $url.Segments[$url.Segments.Length - 1]
                    $filePath = Join-Path $folderPath $fileName
                    if (Test-Path $filePath) {
                        if ($Force) {
                            Write-Host "File $filePath already exist." -ForegroundColor DarkYellow
                        }
                        else {
                            Write-Host "File $filePath already exist." -ForegroundColor DarkGray
                            continue
                        }
                    }

                    Write-Host "Downloading $url -> $filePath" -ForegroundColor Yellow

                    $__ProgressPreference = $ProgressPreference
                    $ProgressPreference = 'SilentlyContinue'
                    Invoke-WebRequest -Uri $url -OutFile $filePath
                    $ProgressPreference = $__ProgressPreference

                    if (-not (Test-Path $filePath)) {
                        Write-Host "Error when downloading $($url.AbsoluteUri)"
                    }
                }
                else {

                }
            }
        }

    }

    #endregion

}

#endregion

function DownloadTortoiseGit {
    param (
        [Parameter(Mandatory = $true)] [string]$DestinationFolder,
        [Parameter(Mandatory = $false)] [switch]$Force
    )

    #region Get-ModuleAdvanced
    if (-not (Get-Command "Get-ModuleAdvanced" -ErrorAction SilentlyContinue)) {
        Write-Host "Can't find function with name 'Get-ModuleAdvanced'" -ForegroundColor DarkRed
        return
    }
    #endregion

    Get-ModuleAdvanced -ModuleName "PowerHTML"

    $_root = [ordered]@{}
    $_currentNode = $_root
    [uri]$_siteUri = $null

    if (-not([uri]::TryCreate("https://tortoisegit.org/download/", [UriKind]::Absolute, [ref]$_siteUri))) {
        Write-Host "Can't create uri." -ForegroundColor Red
        return
    }

    try {
        $htmlDoc = ConvertFrom-Html -URI $_siteUri
        $UrlHost = "$($_siteUri.Scheme)://$($_siteUri.Host)"
    }
    catch {
        Write-Host "Error when getting html from $($_siteUri.AbsoluteUri)" -ForegroundColor Red
        return
    }
    
    $_version = [System.Version]::Parse("0.0.0")
    $_currentVersion = $_version.ToString()

    $XPathValue = '/html/body/div[1]/div[3]/div/p[1]/strong'
    $node = $HtmlDoc.SelectSingleNode($XPathValue)
    if ($node.InnerText -match "The current stable version is:\s+(?<version>\d\d?\.\d\d?\.\d\d?)") {
        $versionTxt = $Matches["version"]

        if (-not ([System.Version]::TryParse($versionTxt, [ref]$_version))) {
            Write-Host -Object "Can't parse version." -ForegroundColor DarkRed
            return
        }
    }
    else {
        Write-Error "Can't find version"
        return 
    }
    $_currentVersion = $_version.ToString()


    $XPathValue = '/html/body/div[1]/div[3]/div/table[@class="downloadtable"]'
    $node = $HtmlDoc.SelectSingleNode($XPathValue)
    $_currentNode = @()
    for ($i = 0; $i -lt 3; $i++) {
        $a = $node.ChildNodes[0].ChildNodes[1].ChildNodes[$i].ChildNodes | Where-Object { $_.Name -eq "a" }
        if ($null -ne $a) {
            $url = $a.Attributes["href"].Value
            if (-not $url.StartsWith("http")) {
                $url = [System.Uri]"http:$url"
            }
            $_currentNode = @($_currentNode) + @($url)
        }
        else {
            Write-Error "Can't find download link"
            return
        }
    }
    $_root.Add($_currentVersion, $_currentNode)

    DownloadFromJson -DestinationFolder $DestinationFolder -RootObject $_root
}

#DownloadTortoiseGit -DestinationFolder "\\STORAGE\software\development\git\TortouseGit" -Force
