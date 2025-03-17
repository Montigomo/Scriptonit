Set-StrictMode -Version 3.0

function GetGitCmdPath{
    $gitCmdPath = "C:\Program Files\Git\cmd\git.exe"

    if (-not (Test-Path $gitCmdPath)) {
        Write-Host "Not found git." -ForegroundColor DarkYellow
        return false
    }

    return $gitCmdPath
}

function GitConfig {

    Write-Host "[GitConfig] started ..." -ForegroundColor DarkYellow

    $gcp = GetGitCmdPath

    $path = "$([System.Environment]::GetFolderPath("UserProfile"))\.gitconfig"

    if (Test-Path $path) {
        $array = & $gcp config --global --list
    }

    if (-not $($array -icontains "safe.directory=*")) {
        & $gcp config --global --add safe.directory "*"
    }

}