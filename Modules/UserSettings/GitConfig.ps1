Set-StrictMode -Version 3.0

function GitConfig {

    Write-Host "[GitConfig] started ..." -ForegroundColor Green
    
    $array = git config --global --list
    if (-not $($array -icontains "safe.directory=*")) {
        git config --global --add safe.directory "*"
    }
}