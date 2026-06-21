Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Download.Common") -Force | Out-Null

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
