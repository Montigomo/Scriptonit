Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\..\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

function DownloadFromJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DestinationFolder,
        [Parameter(Mandatory = $true)]
        [hashtable]$RootObject,
        [Parameter(Mandatory = $false)]
        [switch]$Force
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
                            Write-Host "File $filePath already exist." -ForegroundColor DarkGray
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
