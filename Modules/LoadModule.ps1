[CmdletBinding()]
param (
    [Parameter()][string[]]$ModuleNames,
    [Parameter()][switch]$Force
)

Set-StrictMode -Version 3.0

#region types definition

$TypeParam = @{
    TypeName   = 'System.Array'
    MemberType = 'ScriptMethod'
    MemberName = 'ArrContainsName'
    Value      = {
        Param($Name)
        #return ($this.BinarySearch($Name, [ObjComparer]::new()) -ge 0)
        if (-not $this) {
            return $false
        }
        return ([System.Array]::FindIndex($this, [Predicate[pscustomobject]] { param($s)$s.Name -eq $Name }) -ge 0)
    }
}

Update-TypeData @TypeParam -Force

$TypeParam = @{
    TypeName   = 'System.Array'
    MemberType = 'ScriptMethod'
    MemberName = 'ArrFindName'
    Value      = {
        Param($Name)
        #return ($this.BinarySearch($Name, [ObjComparer]::new()) -ge 0)
        return ([System.Array]::Find($this, [Predicate[pscustomobject]] { param($s)$s.Name -eq $Name }))
    }
}

Update-TypeData @TypeParam -Force


#endregion

#region Variables

$Parent = (Get-PSCallStack)[1]

$LibraryBaseFolder = "$PSScriptRoot"

$ModulePrefix = "Scriptonit"

if (-not (Test-Path "variable:global:ModulesList")) {
    $global:ModulesList = @()
}

#endregion

#region LmGetPath LmGetLocalizedResourceName LmGetObjects LmGetParams

# function LmLoadModule01 {
#     param (
#         [Parameter(Mandatory = $true)][string]$ModuleName
#     )ModuleName

#     $ChildPath = $ModuleName.Replace(".", "\")

#     $LibraryPath = (Join-Path $LibraryBaseFolder $ChildPath) | Resolve-Path

#     if (-not (Test-Path -Path $LibraryPath)) {
#         Write-Host "Library $ModuleName not found." -ForegroundColor DarkYellow
#         return
#     }

#     $items = Get-ChildItem -Path $LibraryPath -Filter "*.ps1"

#     foreach ($item in $items) {
#         Write-Verbose "Importing $($item.FullName)"
#         $script = Get-Content $item.FullName
#         $script = $script -replace '^function\s+((?!global[:]|local[:]|script[:]|private[:])[\w-]+)', 'function Global:$1'
#         $script = $script -replace '\$PSScriptRoot', "$LibraryBaseFolder"
#         $ofs = "`r`n"
#         . ([scriptblock]::Create($script))

#         #. $item.FullName
#     }
#     Write-Host "Library $LibraryName loaded successfully." -ForegroundColor DarkGreen
# }

function LmGetPath {

    $LogFilePath = "$PSScriptRoot"

    #\$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)).log"

    $t1 = $PSCommandPath
    $options = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant'
    $m001 = [regex]::Match($t1, "\\scripts\\modules", $options)

    $rr = (Get-PSCallStack)[1].Command

    if (-not $m001.Success) {

    }
    else {
        $ind = $m001.Index + $m001.Length
        $p01 = $t1.Substring(0, $ind)
        $t1 = (Join-Path $p01 "Logs" ) | Resolve-Path -ErrorAction SilentlyContinue
    }

    return $t1
}

function LmGetLocalizedResourceName {
    param (
        [Parameter()][string] $ResourceName
    )

    $jsonConfigPath = (Join-Path "$PSScriptRoot" "..\.configs\resx.json") | Resolve-Path -ErrorAction SilentlyContinue

    $ui = Get-UICulture

    $array = $ResourceName.Split('.')

    $jsonConfigString = Get-Content $jsonConfigPath | Out-String

    [hashtable]$objects = ConvertFrom-Json -InputObject $jsonConfigString -AsHashtable -Depth 256

    $pointer = $objects

    for ($i = 0; $i -lt $array.Count; $i++) {
        $_key = $array[$i]
        if ($pointer.ContainsKey($_key)) {
            $pointer = $pointer[$_key]
        }
    }

    if ($pointer -eq $objects) {
        $pointer = $null
    }

    if (-not $pointer.ContainsKey($ui.Name)) {
        $pointer = $null
    }

    if (-not $pointer) {
        Write-Host "Can't find localized name for recource $ResourceName" -ForegroundColor DarkYellow
        return
    }

    return $pointer[$ui.Name]
}

function LmGetObjects {
    param (
        [Parameter()][string]$ConfigName
    )

    $array = $ConfigName.Split('.')

    $jsonConfigPath = (Join-Path "$PSScriptRoot" "..\.configs\$($array[0]).json") | Resolve-Path -ErrorAction SilentlyContinue

    if ((-not $jsonConfigPath) -or -not (Test-Path $jsonConfigPath)) {
        Write-Host "Config $ConfigName not found." -ForegroundColor DarkRed
        return
    }

    $jsonConfigString = Get-Content $jsonConfigPath | Out-String

    $found = $false

    $object = ConvertFrom-Json -InputObject $jsonConfigString -AsHashtable -Depth 256

    if ($array.Length -gt 1) {
        $array = $array[1..($array.length - 1)]

        for ($i = 0; $i -lt $array.Count; $i++) {
            $_key = $array[$i]
            if ($object.ContainsKey($_key)) {
                $found = $true
                $object = $object[$_key]
            }

        }

        if (-not $found) {
            Write-Host "Object $ConfigName not fiound." -ForegroundColor DarkYellow
            return $null
        }
    }

    return $object
}

function LmGetParams {
    param (
        [Parameter(Mandatory = $true)] [hashtable]$InvocationParams,
        [Parameter(Mandatory = $true)] [hashtable]$PSBoundParams
    )
    $params = $null
    foreach ($h in $InvocationParams.GetEnumerator()) {
        try {
            $key = $h.Key
            $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
            if (([String]::IsNullOrEmpty($val) -and (!$PSBoundParams.ContainsKey($key)))) {
                throw "A blank value that wasn't supplied by the user."
            }
            Write-Verbose "$key => '$val'"
            if (-not $params) {
                $params = @{}
            }
            $params[$key] = $val
        }
        catch {}
    }

    return $params
}

#endregion

#region LmTestFunction LmSortHashtableByKey LmSortHashtableByPropertyValue

function LmTestFunction {
    param (
        [Parameter(Mandatory = $true)] [string]$Name
    )
    Test-Path -Path "function:${Name}"
}

function LmSortHashtableByKey {
    param (
        [Parameter()][hashtable]$InputHashtable
    )

    $_shash = [System.Collections.Specialized.OrderedDictionary]@{}

    foreach ($key in $InputHashtable.Keys | Sort-Object) {
        $_object = $InputHashtable[$key]
        if ($_object -is [hashtable]) {
            $_object = LmSortHashtableByKey -InputHashtable $_object
        }
        $_shash[$key] = $_object
    }
    return $_shash
}

function LmSortHashtableByPropertyValue {
    param (
        [Parameter(Mandatory = $true)][hashtable]$InputHashtable,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $hash = $InputHashtable.GetEnumerator()
    $hash = $hash | Sort-Object { $_.Value.$Key }

    $sorted_hash = [ordered]@{}
    foreach ($item in $hash) {
        $sorted_hash.Add($item.Key, $item.Value)
    }

    return $sorted_hash
}

#endregion

#region LmScanModule LmLoadModule

function LmScanModule {
    param (
        [Parameter(Mandatory = $true)][string]$ModuleFullName
    )

    $ChildPath = $ModuleFullName.Replace("$ModulePrefix.", "").Replace(".", "\")

    $LibraryPath = (Join-Path $LibraryBaseFolder $ChildPath) | Resolve-Path

    $items = Get-ChildItem -Path "$LibraryPath" -Filter "*.ps1"

    foreach ($item in $items) {
        if ($item.FullName -ine $Parent.ScriptName) {
            $content = Get-Content $item.FullName | Where-Object { $_.Contains("LoadModule.ps1") }
            if ($content) {
                foreach ($item in $content) {
                    $modules = $null
                    switch -regex ($item) {
                        '(\..*LoadModule\.ps1\"\s+\-ModuleNames\s+\@\((?<modules>.*)\).*(?<force>-Force)?.*Out-Null)' {
                            $modules = $Matches["modules"].split(",").trim().Trim('"')
                            break
                        }
                        # '(\..*LoadModule\.ps1\"\s+\-ModuleNames\s+\@\((?<modules>.*)\).|\s+Out-Null)' {
                        #     $modules = $Matches["modules"].split(",").trim().Trim('"')
                        #     break
                        # }
                        # Default {}
                    }
                    if ($modules) {
                        foreach ($ModuleName in $modules) {
                            if (-not $global:ModulesList.ArrContainsName($ModuleName)) {
                                $global:ModulesList += [pscustomobject]@{Name = $ModuleName; Scanned = $false }
                            }
                        }
                    }
                }
            }
        }
    }

}
function LmLoadModule {
    param (
        [Parameter(Mandatory = $true)][string]$ModuleFullName
    )

    $verbose = $VerbosePreference -ne 'SilentlyContinue'
    if (Get-Module | Where-Object { $_.Name -ieq "$ModuleFullName" }) {
        if ($verbose) {
            Write-Verbose "Module $ModuleFullName already exist!"
        }
        return
    }
    Write-Host "Loading module $ModuleFullName" -ForegroundColor DarkGreen

    $ChildPath = $ModuleFullName.Replace("$ModulePrefix.", "").Replace(".", "\")

    $LibraryPath = (Join-Path $LibraryBaseFolder $ChildPath) | Resolve-Path

    $items = Get-ChildItem -Path "$LibraryPath" -Filter "*.ps1"

    $script = "Set-StrictMode -Version 3.0" + [System.Environment]::NewLine

    foreach ($item in $items) {
        if ($item.FullName -ine $Parent.ScriptName) {
            $script = $script + ". $($item.FullName)" + [System.Environment]::NewLine
            if ($verbose) {
                Write-Verbose "Script: $($item.FullName)"
            }
        }
        else {
            if ($verbose) {
                Write-Host "$item.FullName not loaded. Recursive call." -ForegroundColor Red
            }
        }

    }

    $OFS = "`r`n"
    $sb = [ScriptBlock]::Create($script)
    $arguments = @{
        ScriptBlock = $sb
        Name        = $ModuleFullName
    }
    $module = New-Module @arguments
    Import-Module $module -Scope Global -Force -DisableNameChecking
    Remove-Variable -Name "OFS" -ErrorAction SilentlyContinue
}

function LoadModule {
    param (
        [Parameter(Mandatory = $true)][string[]]$ModuleNames,
        [Parameter(Mandatory = $false)][switch]$Force
    )

    $lmflag = (Get-PSCallStack | Select-Object -ExpandProperty Command) -icontains "lmloadmodule"
    if (-not $lmflag) {
        $global:ModulesList = @()
        $global:LmFlag = $true

        foreach ($ModuleName in $ModuleNames) {
            if (-not $global:ModulesList.ArrContainsName($ModuleName)) {
                $global:ModulesList += [pscustomobject]@{Name = $ModuleName; Scanned = $false }
            }
        }

        do {
            for ($i = 0; $i -lt $global:ModulesList.Count; $i++) {
                $item = $global:ModulesList[$i]
                if (-not $item.Scanned) {
                    LmScanModule -ModuleFullName $item.Name
                    $item.Scanned = $true
                }
            }
        }until ($null -eq ($global:ModulesList | Where-Object { -not $_.Scanned }))

        foreach ($item in $global:ModulesList) {
            $ModuleFullName = "$ModulePrefix.$($item.Name)"
            if ($Force -and (Get-Module -Name $ModuleFullName)) {
                Write-Verbose "Removing module $ModuleFullName"
                Remove-Module -Name $ModuleFullName -Force
            }
            LmLoadModule -ModuleFullName $ModuleFullName
        }

    }
}

#endregion

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSBoundParameters
    LoadModule @params
}