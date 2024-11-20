Set-StrictMode -Version 3.0

function GetGitHubItems {
    param(
        [Parameter(Mandatory = $true)] [string]$Uri,
        [Parameter(Mandatory = $false)] [string]$ReleasePattern,
        [Parameter(Mandatory = $false)] [string[]]$VersionPattern,
        [Parameter(Mandatory = $false)] [int]$Deep = 1,
        [Parameter(Mandatory = $false)] [switch]$UsePreview
    )

    $Uri = "$Uri/releases" -replace "(?<!:)/{2,}", "/"
    $json = (Invoke-RestMethod -Method Get -Uri $Uri)
    $objects = $json | Where-Object { (-not $_.prerelease) -or ($UsePreview -and $_.prerelease) } | Sort-Object -Property published_at -Descending
    $objects = $objects | Select-Object -First $Deep
    $_remoteVersion = [System.Version]::Parse("0.0.0")
    $_objects = @()

    foreach ($object in $objects) {
        $vpresult = $false
        $vstring = $object.tag_name

        if ($VersionPattern) {
            if ($vstring -match $VersionPattern) {
                $vpresult = [System.Version]::TryParse($Matches["version"], [ref]$_remoteVersion)
            }        
        }
    
        if (-not $vpresult) {
            switch -Regex ($vstring) {
                "(?<v1>\d?\d\.\d\d?)-beta(?<v2>\d\d?)" {
                    $vpresult = [System.Version]::TryParse("$($Matches["v1"]).$($Matches["v2"])", [ref]$_remoteVersion)
                    break 
                }            
                "v?(?<version>\d?\d\.\d?\d\.?\d?\d?\.?\d?\d?)" { 
                    $vpresult = [System.Version]::TryParse($Matches["version"], [ref]$_remoteVersion)
                    break 
                }

            }
        }
        if (-not $vpresult) {
            throw "Can't parse version info."
        }
        $browser_download_url = ""
        if ($ReleasePattern) {
            $browser_download_url = $object.assets | Where-Object name -match $ReleasePattern | Select-Object -ExpandProperty 'browser_download_url'
        }
        else {
            $browser_download_url = $object.assets | Select-Object -ExpandProperty 'browser_download_url'
        }
        $_objects = $_objects + @{Version = $_remoteVersion; "Url" = $browser_download_url}
    }
    return $_objects
}