Set-StrictMode -Version 3.0

if ((Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    exit
}

# .SYNOPSIS
#     Write log
# .PARAMETER LogString
#     log info string
# .PARAMETER WithoutFunctionName
#     [switch] write or not a calling function to log string
# .NOTES
#     Author : Agitech; Version : 0.0.0.1
function Write-Log {
    param (
        [Parameter(Mandatory = $false)] [string] $LogString,
        [Parameter(Mandatory = $false)] [switch] $WithoutFunctionName
    )


    #if (-not (Get-Variable -Name "LogFileLocation" -ErrorAction SilentlyContinue)) {
    #$t0 = LmGetPath
    #}

    $Stamp = Get-Date -Format "yyyy.MM.dd HH:mm:ss"

    if (-not $WithoutFunctionName) {
        $LogString = "[$((Get-PSCallStack)[1].Command)]: $LogString"
    }  
    Write-Host $LogString -ForegroundColor DarkYellow
    $LogString = "$Stamp $LogString"  
    #Add-content $LogFilePath -value $LogString
    Write-Host $LogString -ForegroundColor DarkGreen
}

function WriteLog {
    Write-Log @args
}