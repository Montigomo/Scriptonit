
$ScriptLogFileName = "$PSScriptRoot\log.log"
$LogVerbosityLevel = 00

#region Capture Write-Host

if (get-Item function:\write-host -ErrorAction SilentlyContinue) {
    Remove-Item function:\write-host -ErrorAction SilentlyContinue
}

$WriteHostCmdlet = Get-Command Write-Host

function global:Write-Host() {
    Param (
        [Parameter(Mandatory = $false)] [string]$Object,
        [Parameter(Mandatory = $false)] [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::DarkYellow,
        [Parameter(Mandatory = $false)] [string]$LogFilePath = $ScriptLogFileName,
        [Parameter(Mandatory = $false)] [string]$FunctionName,
        [Parameter(Mandatory = $false)] [switch]$WithoutFunctionName,
        [Parameter(Mandatory = $false)] [int]$VerbocityLevel = 00,
        [Parameter(Mandatory = $false)] [switch]$NotWriteHost
    )

    $LogString = $Object

    if (-not(Test-Path -LiteralPath $LogFilePath -IsValid)) {
        Write-Host "Incorrect [LogFilePath] parameter value" -ForegroundColor Red
        return
    }

    if (-not (Test-Path $LogFilePath)) {
        New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
    }

    if ($VerbocityLevel -gt $LogVerbosityLevel) {
        return
    }

    $Stamp = Get-Date -Format "yyyy.MM.dd HH:mm:ss"

    $Prefix = [System.String]::Empty
    if ($FunctionName) {
        $Prefix = "[$FunctionName]:"
    }
    elseif (-not $WithoutFunctionName) {
        $Prefix = "[$((Get-PSCallStack)[1].Command)]:"
    }

    $LogString = "$Prefix $LogString"

    $LogString = "$Stamp $LogString"

    if ($WriteHostCmdlet) {
        $params = @{
            Object          = $LogString
            ForegroundColor = $ForegroundColor
        }
        & $WriteHostCmdlet @params
    }

    Add-content $LogFilePath -value $LogString
}

#endregion

Write-Host "Test"

& "$PSScriptRoot\CWH_cs.ps1"

exit