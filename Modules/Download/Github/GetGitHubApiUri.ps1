Set-StrictMode -Version 3.0

function GetGitHubApiUri{
    param(
        [Parameter(Mandatory = $true)] [string]$GitProjectUrl
    )
    
    [uri]$_gitProjectUri = $null
    [uri]$_gitProjectApiUri = $null
    
    if (-not([uri]::TryCreate($GitProjectUrl, [UriKind]::Absolute, [ref]$_gitProjectApiUri))) {
        return
    }

    $uriBuilder = [System.UriBuilder]::new($_gitProjectApiUri)
    if (($uriBuilder.Host -ieq "github.com") -and (-not $uriBuilder.Path.StartsWith("/repos"))) {
        $_gitProjectUri = $uriBuilder.Uri
        $uriBuilder.Host = "api.github.com"
        $uriBuilder.Path = "/repos$($uriBuilder.Path)"
        $_gitProjectApiUri = $uriBuilder.Uri
    }
    elseif (($uriBuilder.Host -ieq "api.github.com") -and ($uriBuilder.Path.StartsWith("/repos"))) {
        $_gitProjectApiUri = $uriBuilder.Uri
        $uriBuilder.Host = "github.com"
        $uriBuilder.Path = ($uriBuilder.Path -replace "^/repos", "")
        $_gitProjectUri = $uriBuilder.Uri
    }
    else {
        Write-Host "Wrong url - $GitProjectUrl" -ForegroundColor DarkYellow
        return
    }

    return $_gitProjectApiUri
}
