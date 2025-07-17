Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

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
        "linux"   = "https://www.virtualhere.com/usb_server_software"
        "windows" = "https://www.virtualhere.com/windows_server_software"
        "macos"   = "https://www.virtualhere.com/osx_server_software"
        "android" = "https://www.virtualhere.com/android"
    }

    $root = [ordered]@{}


    #region Server

    $server = [ordered]@{}

    [uri]$Uri = $null

    if (-not([uri]::TryCreate($UriServer["linux"], [UriKind]::Absolute, [ref]$Uri))) {
        Write-Host "Can't create uri." -ForegroundColor Red
        return
    }

    $htmlDoc = ConvertFrom-Html -URI $Uri
    $UrlHost = "$($Uri.Scheme)://$($Uri.Host)"

    $_currentNode = $server

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

    $_currentVersion = $serverVersion.ToString()
    $_currentNode.Add($_currentVersion, [ordered]@{})
    $_currentNode = $server[$_currentVersion]

    $_currentNode.Add(".", [System.Uri]"https://www.virtualhere.com/sites/default/files/usbserver/SHA1SUM")

    #region linux

    $_currentNode.Add("linux", [ordered]@{})
    $_currentNode = $_currentNode["linux"]

    $_subNode = './/li/a'

    # Linux

    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[1]/td/ul'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $_currentNode.Add(".", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # ARM 32-bit
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[1]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $_currentNode.Add("arm32", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # ARM 64-bit
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[2]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $_currentNode.Add("arm64", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # MIPS Big Endian
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[3]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $_currentNode.Add("mips", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # MIPS Little Endian
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[4]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $_currentNode.Add("mipsel", $_ulrs)
    # Start-Sleep -Seconds $pause01

    # x86_64
    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/table/tbody/tr[2]/td/ul[5]'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $_currentNode.Add("x86_64", $_ulrs)

    #endregion

    #region windows

    [uri]$Uri = $null

    if (-not([uri]::TryCreate($UriServer["windows"], [UriKind]::Absolute, [ref]$Uri))) {
        Write-Host "Can't create uri." -ForegroundColor Red
        return
    }

    $htmlDoc = ConvertFrom-Html -URI $Uri
    $UrlHost = "$($Uri.Scheme)://$($Uri.Host)"

    $node = $htmlDoc.SelectSingleNode('/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/p[2]/a')
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

    $_currentVersion = $serverVersion.ToString()

    if (-not ($server.Contains($_currentVersion))) {
        $_currentNode.Add($_currentVersion, [ordered]@{})
    }

    $_currentNode = $server[$_currentVersion]

    $_currentNode.Add("windows", [ordered]@{})
    $_currentNode = $_currentNode["windows"]

    $_subNode = './/li/a'

    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/ul'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $_currentNode.Add(".", $_ulrs)

    # Start-Sleep -Seconds $pause01

    #endregion

    #region macos

    [uri]$Uri = $null

    if (-not([uri]::TryCreate($UriServer["macos"], [UriKind]::Absolute, [ref]$Uri))) {
        Write-Host "Can't create uri." -ForegroundColor Red
        return
    }

    $htmlDoc = ConvertFrom-Html -URI $Uri
    $UrlHost = "$($Uri.Scheme)://$($Uri.Host)"

    $node = $htmlDoc.SelectSingleNode('/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/p[4]/a')
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

    $_currentVersion = $serverVersion.ToString()

    if (-not ($server.Contains($_currentVersion))) {
        $_currentNode.Add($_currentVersion, [ordered]@{})
    }

    $_currentNode = $server[$_currentVersion]

    $_currentNode.Add("macos", [ordered]@{})
    $_currentNode = $_currentNode["macos"]

    $_subNode = './/li/a'

    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/ol'
    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost
    $_currentNode.Add(".", $_ulrs)

    # Start-Sleep -Seconds $pause01

    #endregion

    #region android

    [uri]$Uri = $null

    if (-not([uri]::TryCreate($UriServer["android"], [UriKind]::Absolute, [ref]$Uri))) {
        Write-Host "Can't create uri." -ForegroundColor Red
        return
    }

    $htmlDoc = ConvertFrom-Html -URI $Uri
    $UrlHost = "$($Uri.Scheme)://$($Uri.Host)"


    $_currentNode = $server[$_currentVersion]

    $_currentNode.Add("android", [ordered]@{})
    $_currentNode = $_currentNode["android"]

    #/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/p[7]/a

    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div/p[6]/a'

    $node = $htmlDoc.SelectSingleNode($XPathValue)

    if ($node) {

        $url = [string]$node.Attributes["href"].Value

        if (-not $url.StartsWith("http")) {
            $url = [System.Uri]"$UrlHost$url"
        }


        $_currentNode.Add(".", $url)
    }

    # Start-Sleep -Seconds $pause01

    #endregion

    $root.Add("server", [ordered]@{})
    $root["server"] = $server


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
    $_currentNode = $root["client"]

    $_currentVersion = $clientVersion.ToString()
    $_currentNode.Add($_currentVersion, [ordered]@{})
    $_currentNode = $_currentNode[$_currentVersion]

    #$_currentNode.Add(".", [System.Uri]"https://www.virtualhere.com/sites/default/files/usbclient/SHA1SUM")

    $_subNode = './/p/a'

    $XPathValue = '/html/body/div[2]/main/div/div[2]/div/div/div[3]/article/div/div'

    $_ulrs = DvhGetUrls -HtmlDoc $htmlDoc -XPath $XPathValue -XPathSubNode $_subNode -UrlHost $UrlHost -Client

    $_ulrs = $_ulrs + @([System.Uri]"https://www.virtualhere.com/sites/default/files/usbclient/SHA1SUM")

    $_currentNode.Add(".", $_ulrs)

    #endregion


    ConvertTo-Json -InputObject $root -Depth 32 | Set-Clipboard

    DownloadFromJson -DestinationFolder $DestinationFolder -RootObject $root

}

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

function DownloadVirtualHere {
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


    DvhGetObjects -DestinationFolder $DestinationFolder
}