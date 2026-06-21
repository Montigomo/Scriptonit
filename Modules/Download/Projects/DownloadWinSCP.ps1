Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Download.Common") -Force | Out-Null

function DownloadWinSCP {
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
    $UrlHost = $null

    if (-not([uri]::TryCreate("https://winscp.net/eng/downloads.php", [UriKind]::Absolute, [ref]$_siteUri))) {
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

    $XPathValue = '/html/body/div[1]/main/div/section/section[1]/ul[2]/li[1]/a'
    $node = $HtmlDoc.SelectSingleNode($XPathValue)
    if ($node -and $node.InnerText -match "Download\s+WinSCP\s+(?<version>\d\d?\.\d\d?\.\d\d?)\s+\(.*\)") {
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

    $_currentNode = @()
    $XPathValue = '/html/body/div[1]/main/div/section/section[1]/ul[2]/li[1]/a'
    $node = $HtmlDoc.SelectSingleNode($XPathValue)
    if ($null -ne $node) {
        $url = $node.Attributes["href"].Value
        if (-not $url.StartsWith("http")) {
            $url = [System.Uri]"$UrlHost$url"
        }
        $_currentNode = @($_currentNode) + @($url)
    }
    else {
        Write-Error "Can't find version"
        return 
    }

    # $_currentNode = @()
    # for ($i = 0; $i -lt 3; $i++) {
    #     $a = $node.ChildNodes[0].ChildNodes[1].ChildNodes[$i].ChildNodes | Where-Object { $_.Name -eq "a" }
    #     if ($null -ne $a) {
    #         $url = $a.Attributes["href"].Value
    #         if (-not $url.StartsWith("http")) {
    #             $url = [System.Uri]"http:$url"
    #         }
    #         $_currentNode = @($_currentNode) + @($url)
    #     }
    #     else {
    #         Write-Error "Can't find download link"
    #         return
    #     }
    # }

    $_root.Add($_currentVersion, $_currentNode)

    DownloadFromJson -DestinationFolder $DestinationFolder -RootObject $_root -Force:$Force
}