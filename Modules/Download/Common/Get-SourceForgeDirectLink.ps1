Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\..\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

function Get-SourceForgeDirectLink {
    param(
        [string]$ProjectUrl,
        [string]$OutputPath
    )
    
    # Follow redirects to get the actual download URL
    $response = Invoke-WebRequest -Uri $ProjectUrl -MaximumRedirection 0 -ErrorAction SilentlyContinue
    
    if ($response.StatusCode -eq 302) {
        $downloadUrl = $response.Headers.Location
        Write-Host "Actual download URL: $downloadUrl"
        
        # Download the file
        Invoke-WebRequest -Uri $downloadUrl -OutFile $OutputPath
        Write-Host "Download completed: $OutputPath"
    } else {
        Write-Error "Failed to get download URL"
    }
}
#
#  UNDER CONCTRUCTION !!!!
#
# Usage
# https://sourceforge.net/projects/winscp/files/WinSCP/6.5.4/WinSCP-6.5.4-Portable.zip/download
#Get-SourceForgeDownload -ProjectUrl "https://sourceforge.net/projects/notepad-plus-plus/files/latest/download" -OutputPath "C:\Downloads\npp.zip"
