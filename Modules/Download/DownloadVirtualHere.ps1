Set-StrictMode -Version 3.0

#region functions

function DvhGetUrls {
    param (
        [Parameter()][object]$HtmlDoc,
        [Parameter()][string]$XPath,
        [Parameter()][string]$XPathSubNode,
        [Parameter()][string]$UrlHost,
        [Parameter()][switch]$Client
    )

    $node = $HtmlDoc.SelectSingleNode($XPath)
    $nodes = $node.SelectNodes($XPathSubNode)
    if ($Client) {
        $nodes = $nodes | Where-Object { [string]$_.Attributes["href"].Value -imatch ".*\/usbclient\/.*" }
    }
    if ($nodes.Count -lt 1) {
        Write-Host "Can't get urls" -ForegroundColor DarkYellow
        return
    }
    $urlArray = @()
    foreach ($node in $nodes) {
        $url = [string]$node.Attributes["href"].Value
        if (-not $url.StartsWith("http")) {
            $urlArray += [System.Uri]"$UrlHost$url"
        }
    }

    return $urlArray
}

function DvhGetObjects {
    param (
        [Parameter(Mandatory = $true)] [string] $DestinationFolder
    )

    $UriClient = "https://www.virtualhere.com/usb_client_software"

    $UriServer = @{
        "linux" = "https://www.virtualhere.com/usb_server_software"
    }

    $root = [ordered]@{}


    #region Server

    [uri]$Uri = $null
    if (-not([uri]::TryCreate($UriServer["linux"], [UriKind]::Absolute, [ref]$Uri))) {
        return
    }

    $htmlDoc = ConvertFrom-Html -URI $Uri
    $UrlHost = "$($Uri.Scheme)://$($Uri.Host)"

    $root.Add("server", [ordered]@{})

    $node = $htmlDoc.SelectSingleNode('/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/thead/tr/th/strong')
    if ((-not $node) -or ($node.InnerText -inotmatch "^version\s(?<version>\d\d?\.\d\d?\.\d\d?)")) {
        Write-Host "Can't parse version." -ForegroundColor DarkYellow
        exit
    }

    $versionTxt = $Matches["version"]
    $serverVersion = [System.Version]::Parse("0.0.0")
    if (-not ([System.Version]::TryParse($versionTxt, [ref]$serverVersion))) {
        Write-Host -Object "Can't parse version." -ForegroundColor DarkRed
        return
    }

    $root["server"].Add("version", $serverVersion)
    $root["server"].Add("assets", [ordered]@{})

    $assets = $root["server"]["assets"]

    $_subNode = './/li/a'
    # Linux
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[1]/td/ul'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $_ulrs = $_ulrs + @([System.Uri]"https://www.virtualhere.com/sites/default/files/usbserver/SHA1SUM")
    $assets.Add("root", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # ARM 32-bit
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[1]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $assets.Add("arm32", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # ARM 64-bit
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[2]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $assets.Add("arm64", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # MIPS Big Endian
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[3]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $assets.Add("mips", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # MIPS Little Endian
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[4]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $assets.Add("mipsel", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # x86_64
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[5]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $assets.Add("x86_64", $_ulrs)
    #endregion


    #region Client

    [uri]$Uri = $null
    if (-not([uri]::TryCreate($UriClient, [UriKind]::Absolute, [ref]$Uri))) {
        return
    }

    $htmlDoc = ConvertFrom-Html -URI $Uri

    $UrlHost = "$($Uri.Scheme)://$($Uri.Host)"

    $node = $htmlDoc.SelectSingleNode('/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/p[5]/strong')
    if ((-not $node) -or ($node.InnerText -inotmatch "^version\s(?<version>\d\d?\.\d\d?\.\d\d?)")) {
        Write-Host "Can't parse version." -ForegroundColor DarkYellow
        exit
    }

    $versionTxt = $Matches["version"]
    $clientVersion = [System.Version]::Parse("0.0.0")
    if (-not ([System.Version]::TryParse($versionTxt, [ref]$clientVersion))) {
        Write-Host -Object "Can't parse version." -ForegroundColor DarkRed
        return
    }

    $root.Add("client", [ordered]@{})
    $root["client"].Add("version", $clientVersion)
    $root["client"].Add("assets", [ordered]@{})

    $assets = $root["client"]["assets"]

    $_subNode = './/p/a'
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div'

    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost -Client

    $_ulrs = $_ulrs + @([System.Uri]"https://www.virtualhere.com/sites/default/files/usbclient/SHA1SUM")

    $assets.Add("root", $_ulrs)
    #endregion

    #region Download

    foreach ($key in $root.Keys) {
        $version = $root[$key]["version"].ToString()

        $folderPath = $DestinationFolder
        if (-not(Test-Path $folderPath -PathType Container)) {
            New-Item -Path $folderPath -ItemType Directory | Out-Null
        }

        $folderPath = [System.IO.Path]::Combine($DestinationFolder, $key, $version)
        #$folderPath = Join-Path $DestinationFolder -ChildPath $key | Join-Path -ChildPath $version

        if (-not(Test-Path $folderPath -PathType Container)) {
            New-Item -Path $folderPath -ItemType Directory | Out-Null
        }

        foreach ($jkey in $root[$key]["assets"].Keys) {
            if ($jkey -ieq "root") {
                $subFolderPath = $folderPath
            }
            else {
                $subFolderPath = Join-Path $folderPath $jkey
            }
            if (-not(Test-Path $subFolderPath -PathType Container)) {
                New-Item -Path $subFolderPath -ItemType Directory | Out-Null
            }
            foreach ($url in $root[$key]["assets"][$jkey]) {
                $fileName = $url.Segments[$url.Segments.Length - 1]
                $filePath = Join-Path $subFolderPath $fileName

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

                Invoke-WebRequest -Uri $url -OutFile $filePath
                #Write-Host "$response" -ForegroundColor Green

                if (-not (Test-Path $filePath)) {
                    Write-Host "Error when downloading $($url.AbsoluteUri)"
                }
            }
        }
    }
    #endregion

}

#endregion

function DownloadVirtualHere {
    param (
        [Parameter(Mandatory = $false)] [string]$DestinationFolder,
        [Parameter(Mandatory = $false)] [switch]$Force
    )

    #region Get-ModuleAdvanced
    if (-not (Get-Command "Get-ModuleAdvanced" -ErrorAction SilentlyContinue)) {
        Write-Host "Can't find function with name 'Get-ModuleAdvanced'" -ForegroundColor DarkRed
        return
    }
    #endregion

    Get-ModuleAdvanced -ModuleName "PowerHTML"


    DvhGetObjects -DestinationFolder $DestinationFolder
}