Set-StrictMode -Version 3.0

function ConvertFrom-FixedColumnTable {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)] [string] $InputObject
    )
    # Note:
    #  * Accepts input only via the pipeline, either line by line,
    #    or as a single, multi-line string.
    #  * The input is assumed to have a header line whose column names
    #    mark the start of each field
    #    * Column names are assumed to be *single words* (must not contain spaces).
    #  * The header line is assumed to be followed by a separator line
    #    (its format doesn't matter).
    begin {
        Set-StrictMode -Version 1
        $lineNdx = 0
    }

    process {
        $lines =
        if ($InputObject.Contains("`n")) { $InputObject.TrimEnd("`r", "`n") -split '\r?\n' }
        else { $InputObject }
        foreach ($line in $lines) {
            ++$lineNdx
            if ($lineNdx -eq 1) {
                # header line
                $headerLine = $line
            }
            elseif ($lineNdx -eq 2) {
                # separator line
                # Get the indices where the fields start.
                $fieldStartIndices = [regex]::Matches($headerLine, '\b\S').Index
                # Calculate the field lengths.
                $fieldLengths = foreach ($i in 1..($fieldStartIndices.Count - 1)) {
                    $fieldStartIndices[$i] - $fieldStartIndices[$i - 1] - 1
                }
                # Get the column names
                $colNames = foreach ($i in 0..($fieldStartIndices.Count - 1)) {
                    if ($i -eq $fieldStartIndices.Count - 1) {
                        $headerLine.Substring($fieldStartIndices[$i]).Trim()
                    }
                    else {
                        $headerLine.Substring($fieldStartIndices[$i], $fieldLengths[$i]).Trim()
                    }
                }
            }
            else {
                # data line
                $oht = [ordered] @{} # ordered helper hashtable for object constructions.
                $i = 0
                foreach ($colName in $colNames) {
                    $oht[$colName] =
                    if ($fieldStartIndices[$i] -lt $line.Length) {
                        if ($fieldLengths[$i] -and $fieldStartIndices[$i] + $fieldLengths[$i] -le $line.Length) {
                            $line.Substring($fieldStartIndices[$i], $fieldLengths[$i]).Trim()
                        }
                        else {
                            $line.Substring($fieldStartIndices[$i]).Trim()
                        }
                    }
                    ++$i
                }
                # Convert the helper hashable to an object and output it.
                [pscustomobject] $oht
            }
        }
    }

}

function InstallApplications {
    param (
        [Parameter(Mandatory = $true)][array]$Applications
    )

    Write-Host "[InstallApplications] started ..." -ForegroundColor DarkYellow

    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    $arrss = (winget list --accept-source-agreements) -match '^(\p{L}|-)' | ConvertFrom-FixedColumnTable

    $_idName = LmGetLocalizedResourceName -ResourceName "winget.id"
    foreach ($item in $Applications) {
        if( $item.StartsWith("--")){
            continue
        }
        if (-not ($arrss | Where-Object { $_."$_idName" -ieq $item })) {
            #if ((winget search --id "Microsoft.DotNet.DesktopRuntime" --exact) -match '^(\p{L}|-)' -ine "No package found matching input criteria.") {
            winget install --id "$item" --exact --source winget --silent
        }
        else {
            Write-Host "[InstallApplications] application $item already installed." -ForegroundColor DarkYellow
        }
    }

}