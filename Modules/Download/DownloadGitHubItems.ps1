Set-StrictMode -Version 3.0

function DownloadGitHubItems {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string]$GitProjectUrl,
        [Parameter(Mandatory = $true)] [string]$DestinationFolder,
        [Parameter(Mandatory = $false)] [int]$Deep = 1,
        [Parameter(Mandatory = $false)] [switch]$UsePreview,
        [Parameter(Mandatory = $false)] [switch]$Force
    )
    
    [uri]$_gitProjectApiUri = GetGitHubApiUri -GitProjectUrl $GitProjectUrl

    $objects = GetGitHubItems -Uri $_gitProjectApiUri -UsePreview:$UsePreview -Deep $Deep

    if(-not $objects){
        
    }

    foreach ($object in $objects) {

        $_destinationFolder = Join-Path $DestinationFolder $object.Version

        if (-not (Test-Path -PathType Container $_destinationFolder)) {
            New-Item -ItemType Directory -Path $_destinationFolder | Out-Null
        }

        Write-Host "Project $GitProjectUrl;  Version $($object.Version); Destination folder: $_destinationFolder" -ForegroundColor DarkYellow
        
        foreach ($surl in $object.Url) {


            [uri]$uri = $null
            if ([uri]::TryCreate($surl, [UriKind]::Absolute, [ref]$uri)) {
                $_fileName = $uri.Segments[$uri.Segments.Count - 1]
                $_destinationPath = Join-Path $_destinationFolder $_fileName
                if ((-not (Test-Path $_destinationPath)) -or $Force) {
                    Write-Host "Writing file $_fileName" -ForegroundColor DarkYellow
                    Invoke-WebRequest -Uri $uri -OutFile $_destinationPath
                }
                else {
                    Write-Host "File $_fileName exist, skipping." -ForegroundColor DarkGray
                }
            }
        }
    }
}