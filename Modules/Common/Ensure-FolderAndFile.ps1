function Ensure-FolderAndFile {
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseApprovedVerbs", "")]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [string]$Path
    )
    if([string]::IsNullOrWhiteSpace($Path)){
        return
    }
    $folder = Split-Path $Path -Parent
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    if (-not (Test-Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
}