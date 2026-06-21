

$script:OriginalWriteHost = Get-Command -Name 'Microsoft.PowerShell.Utility\Write-Host' -CommandType Cmdlet
$script:CwrLogFile = $null

function Start-WriteHostCapture {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string]$ScriptLogFileName
    )

    $script:CwrLogFile = $ScriptLogFileName

    function global:Write-Host {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
            [Object]$Object,
            [string]$ForegroundColor,
            [string]$BackgroundColor,
            [switch]$NoNewline,
            [Object]$Separator
        )

        process {
            # Prepare parameters for the original Write-Host call
            $boundParams = @{}
            if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
                $boundParams['ForegroundColor'] = $ForegroundColor
            }
            if ($PSBoundParameters.ContainsKey('BackgroundColor')) {
                $boundParams['BackgroundColor'] = $BackgroundColor
            }
            if ($PSBoundParameters.ContainsKey('NoNewline')) {
                $boundParams['NoNewline'] = $NoNewline
            }
            if ($PSBoundParameters.ContainsKey('Separator')) {
                $boundParams['Separator'] = $Separator
            }


            Ensure-FolderAndFile -Path $script:CwrLogFile

            # 1. Write to the file
            $Object | Out-File -FilePath $script:CwrLogFile -Append

            # 2. Call the original Write-Host to show it in the console
            & $script:OriginalWriteHost -Object $Object @boundParams
        }
    }
}


function Stop-WriteHostCapture {
    while (get-Item function:\write-host -ErrorAction SilentlyContinue) {
        Remove-Item -Path "Function:\Write-Host" -ErrorAction SilentlyContinue
    }
}


function GetFormatedLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputLine,
        [Parameter(Mandatory = $false)]
        [string]$FormatChar = "-",
        [Parameter(Mandatory = $false)]
        [int]$StringLength = 64,
        [Parameter(Mandatory = $false)]
        [switch]$ReplaceMultiNewLine = $false
    )
    if ([string]::IsNullOrWhiteSpace($InputLine)) {
        $_inputLine = ""
    }
    else {
        $_inputLine = " $InputLine "
    }

    $_inputLine = $_inputLine + " " * ($_inputLine.length % 2)
    $_inputLine_side = ""
    if (($StringLength - $_inputLine.Length) -ge 0) {
        $_inputLine_side = $FormatChar * (($StringLength - $_inputLine.Length) / 2)
    }
    $_result = @("$_inputLine_side$_inputLine$_inputLine_side")
    return $_result
}