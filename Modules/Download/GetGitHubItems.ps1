Set-StrictMode -Version 3.0

function GetGitHubItems {
    param(
        [Parameter(Mandatory = $true)] [string]$Uri,
        [Parameter(Mandatory = $false)] [string]$ReleasePattern,
        [Parameter(Mandatory = $false)] [string]$VersionPattern,
        [Parameter(Mandatory = $false)] [int]$Deep = 1,
        [Parameter(Mandatory = $false)] [switch]$UsePreview
    )

    if([String]::IsNullOrWhiteSpace($VersionPattern)){
        #$VersionPattern =  "v?(?<version>\d?\d\.\d?\d\.?\d?\d?\.?\d?\d?)"
        $VersionPattern =  "v?(?<version>\d?\d\.\d?\d\.?\d?\d?(\.\d\d?)?)"
    }

    $Uri = "$Uri/releases" -replace "(?<!:)/{2,}", "/"

    $json = (Invoke-RestMethod -Method Get -Uri $Uri)

    $a_objects = $json | Where-Object { -not ($UsePreview -xor $_.prerelease) }
    $vresult = $true
    $b_objects = @()
    foreach ($a_object in $a_objects) {

        $_version = [System.Version]::Parse("0.0.0")

        if ($a_object."tag_name" -match $VersionPattern) {
            $vresult = $vresult -and [System.Version]::TryParse($Matches["version"], [ref]$_version)
        }

        $b_object = @{
            "published_at" = $a_object."published_at"
            "version"      = [version]$_version
            "assets"       = $a_object."assets"
        }
        $b_objects += $b_object
    }

    if ($vresult) {
        $b_objects = $b_objects | Sort-Object -Property { $_."version" } -Descending
    }
    else {
        Write-Host "Problem with version pattern." -ForegroundColor DarkYellow
        $b_objects = $b_objects | Sort-Object -Property "published_at" -Descending
    }

    $b_objects = $b_objects | Select-Object -First $Deep

    $ret_objects = @()

    foreach ($b_object in $b_objects) {
        $browser_download_url = ""
        if ($ReleasePattern) {
            $browser_download_url = $b_object.assets | Where-Object name -match $ReleasePattern | Select-Object -ExpandProperty 'browser_download_url'
        }
        else {
            $browser_download_url = $b_object.assets | Select-Object -ExpandProperty 'browser_download_url'
        }
        $ret_item = @{
            Version = $b_object."version"
            "Url"   = $browser_download_url
        }

        $ret_objects = $ret_objects + $ret_item
    }

    return $ret_objects
}