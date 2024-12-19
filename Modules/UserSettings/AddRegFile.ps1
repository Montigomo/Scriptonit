Set-StrictMode -Version 3.0


function AddRegFile {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $RegFilePath
    )
    $startprocessParams = @{
        FilePath     = "$Env:SystemRoot\REGEDIT.exe"
        ArgumentList = '/s', """$RegFilePath"""
        Verb         = 'RunAs'
        PassThru     = $true
        Wait         = $true
    }
    $proc = Start-Process @startprocessParams
    
    # if ($proc.ExitCode -eq 0) {
    #     'Success!'
    # }
    # else {
    #     "Fail! Exit code: $($Proc.ExitCode)"
    # }
}

function AddRegFiles {
    param (
        [Parameter(Mandatory = $true)][array]$Items,
        [Parameter(Mandatory = $false)][string]$Folder = "$PSScriptRoot\..\..\Windows\Registry"
    )

    Write-Host "[AddRegFiles] started ..." -ForegroundColor Green

    foreach ($item in $Items) {
        $filePath = "$Folder{0}" -f $item
        if (Test-Path -Path $filePath) {
            $filePath = $filePath  | Resolve-Path
            AddRegFile -RegFilePath $filePath
            Write-Host "[AddRegFiles] " -NoNewline -ForegroundColor DarkGreen
            Write-Host """$filePath"" " -NoNewline -ForegroundColor DarkBlue
            Write-Host "added to the registry." -ForegroundColor DarkGreen
        }
        else {
            Write-Host "[AddRegFiles] File " -NoNewline -ForegroundColor DarkYellow
            Write-Host """$filePath"" " -NoNewline -ForegroundColor DarkBlue
            Write-Host "does not exist." -ForegroundColor DarkYellow
        }
    }

}
