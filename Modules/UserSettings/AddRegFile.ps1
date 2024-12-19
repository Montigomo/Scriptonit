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
        [Parameter(Mandatory = $false)][string]$Folder = "$PSScriptRoot\Windows\Registry"
    )
    Write-Host "[AddRegFiles] started ..." -ForegroundColor Green

    foreach ($item in $Items) {
        $filePath = "$Folder{0}" -f $item
        if (Test-Path -Path $filePath) {
            AddRegFile -RegFilePath $filePath
            Write-Host "[AddRegFiles] $filePath added." -ForegroundColor DarkGreen
        }
        else {
            Write-Host "[AddRegFiles] $filePath does not exist." -ForegroundColor DarkGreen
        }
    }

}
