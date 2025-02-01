Set-StrictMode -Version 3.0

function TestFunction{
    param(
        [Parameter(Mandatory = $true)] [string]$Name
    )
    Test-Path -Path "function:${Name}"
}

function TestClass([Parameter(Mandatory = $true, Position = 0)][string]$Name) {
    $type = $Name -as [type]
    return ($null -ne $type)
}

function TestVariable([Parameter(Mandatory = $true)] [string]$Name) {
    return (Test-Path "variable:global:$Name")
}

function TestTypes() {
    $functions = @(
        "WriteLog"
        "GetReleaseInfo"
        "RunOperation"
        "GetOperation"
    )

    foreach ($item in $functions) {
        if (-not (TestFunction($item))) {
            return $false
        }
    }
    $classes = @(
        "ClsSettings"
    )
    foreach ($item in $classes) {
        if (-not (TestClass($item))) {
            return $false
        }
    }

    $variables = @(
        "RootFileFolder"
    )
    foreach ($item in $variables) {
        if (-not (TestVariable($item))) {
            return $false
        }
    }

    return $true
}