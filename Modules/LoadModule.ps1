[CmdletBinding()]
param (
    [Parameter()][string[]]$ModuleNames,
    [Parameter()][switch]$Force
)

Set-StrictMode -Version 3.0

#region types definition

$TypeData = @{
    TypeName   = 'System.Management.Automation.PSCustomObject'
    MemberType = 'ScriptMethod'
    MemberName = 'ContainsKey'
    Value      = {
        Param($Key)
        [bool]$this.psobject.Properties.GetEnumerator().MoveNext() -and ($this.psobject.Properties.name -match $Key)
        #[bool]($this.psobject.Properties.name -match $Key)
    }
}

Update-TypeData @TypeData -Force -ErrorAction Ignore

$TypeData = @{
    TypeName   = 'System.Management.Automation.PSCustomObject'
    MemberType = 'ScriptMethod'
    MemberName = 'Add'
    Value      = {
        Param($Key, $Value)
        Add-Member -InputObject $this -MemberType NoteProperty -Name $Key  -Value $Value
    }
}

Update-TypeData @TypeData -Force  -ErrorAction Ignore

$TypeData = @{
    TypeName   = [System.Diagnostics.Process].ToString()
    MemberType = [System.Management.Automation.PSMemberTypes]::ScriptProperty
    MemberName = 'CommandLine'
    Value      = {
        if (('Win32NT' -eq [System.Environment]::OSVersion.Platform)) {
            # it's windows
            (Get-CimInstance Win32_Process -Filter "ProcessId = $($this.Id)").CommandLine
        }
        elseif (('Unix' -eq [System.Environment]::OSVersion.Platform)) {
            # it's linux/unix
            Get-Content -LiteralPath "/proc/$($this.Id)/cmdline"
        }
        elseif (('MacOSX' -eq [System.Environment]::OSVersion.Platform)) {
            # it's macos
            # ???
        }
    }
}

Update-TypeData @TypeData -ErrorAction Ignore

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

$command = Get-Command "Get-WmiObject" -ErrorAction SilentlyContinue
if (-not $command -or ($command.CommandType -eq "Alias")) {
    if ($PSVersionTable.PSEdition -eq "Core" -and (Get-Command "Get-CimInstance")) {
        $alias = Get-Alias | Where-Object { ($_.Name -eq "Get-WmiObject") -and ($_.ReferencedCommand.Name -eq "Get-CimInstance") }
        if (-not $alias) {
            New-Alias -Name "Get-WmiObject" -Value "Get-CimInstance"
        }
    }
}

#endregion

#region Variables

$Parent = (Get-PSCallStack)[1]

$LibraryBaseFolder = "$PSScriptRoot"

$ModulePrefix = "Scriptonit"

if (-not (Test-Path "variable:global:ModulesList")) {
    $global:ModulesList = @()
}

#endregion

#region EvalParams

function EvalParams{
    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable]$params
    )

    function EvalParam {
        param(
            [Parameter(Mandatory = $true)]
            [object]$Param
        )
        $_result = $Param
        switch ($Param.GetType().FullName) {
            "System.String" {
                $_result = EvalStringParam -Param $Param
                break
            }
            "System.Boolean" {
                break
            }
            "System.Object[]" {
                $_result = EvalArray -Param $Param
                break
            }
            default {
                break
            }
        }
        return $_result
    }

    function EvalStringParam {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Param
        )
        $_result = $Param
        if ($Param -match "\$\w+") {
            if ($Param -notmatch "[^\$\w]") {
                $_result = ExpandVariable -Varname $Param
            }
            else {
                $_result = $ExecutionContext.InvokeCommand.ExpandString($Param)
            }
        }
        #$_result = Invoke-Expression $Param
        #$ast = [System.Management.Automation.Language.Parser]::ParseInput("$_value", [ref]$null, [ref]$null)
        #$r1 = $ast.EndBlock.Statements[0].PipelineElements[0].Expression.SafeGetValue()
        return $_result
    }

    function EvalArray {
        param(
            [Parameter(Mandatory = $true)]
            [array]$Param
        )
        for ([int]$i = 0; $i -lt $Param.Length; $i++ ) {
            $_result = $Param[$i]
            $_result = EvalParam -Param $Param[$i]
            $Param[$i] = $_result
        }
        return $Param
    }

    function ExpandVariable {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Varname
        )
        $retval = $null
        $_varName = $Varname -replace "^\$", ""
        if (TestVariable -Name $_varName) {
            $retval = Get-Variable -Name "$_varName" -ValueOnly
        }
        return $retval
    }


    if ($params) {
        foreach ($_key in $($params.keys)) {
            $params[$_key] = EvalParam -Param $params[$_key]
        }
    }
    return $params
}

#endregion

#region LmGetPath LmGetLocalizedResourceName LmGetObjects LmGetParams

# function ConvertTo-Hashtable {
#     [CmdletBinding()]
#     [OutputType('hashtable')]
#     param (
#         [Parameter(ValueFromPipeline)]
#         $InputObject
#     )
#     process {

#         if ($null -eq $InputObject) {
#             return $null
#         }
#         if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
#             $collection = @(
#                 foreach ($object in $InputObject) {
#                     ConvertTo-Hashtable -InputObject $object
#                 }
#             )
#             Write-Output -NoEnumerate $collection
#         }
#         elseif ($InputObject -is [psobject]) {
#             $hash = @{}
#             foreach ($property in $InputObject.PSObject.Properties) {
#                 $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
#             }
#             $hash
#         }
#         else {
#             $InputObject
#         }
#     }
# }

function LmConvertObjectToHashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }
    if ($InputObject -is [Hashtable] -or $InputObject.GetType().Name -eq 'OrderedDictionary') {
        return $InputObject
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $collection = @(
            foreach ($object in $InputObject) { LmConvertObjectToHashtable($object) }
        )

        return $collection
    }
    elseif ($InputObject -is [psobject]) {
        $hash = @{}

        foreach ($property in $InputObject.PSObject.Properties) {
            $hash[$property.Name] = LmConvertObjectToHashtable($property.Value)
        }

        return $hash
    }
    else {
        return $InputObject
    }
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
        [Parameter()][string[]]$ConfigName
    )

    $array = $ConfigName#.Split('.')

    $jsonConfigPath = (Join-Path "$PSScriptRoot" "..\.configs\$($array[0]).json") | Resolve-Path -ErrorAction SilentlyContinue

    if ((-not $jsonConfigPath) -or -not (Test-Path $jsonConfigPath)) {
        Write-Host "Config $ConfigName not found." -ForegroundColor DarkRed
        return
    }

    $jsonConfigString = Get-Content $jsonConfigPath | Out-String

    $found = $false

    $object = ConvertFrom-Json -InputObject $jsonConfigString | LmConvertObjectToHashtable

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

#region LmParamsRemoveComments

function LmParamsRemoveComments {
    param (
        [Parameter()]
        [hashtable]$Params
    )
    $keystoremove = @()
    foreach ($skey in $Params.Keys) {
        if ($skey.StartsWith("##")) {
            $keystoremove += $skey
        }
    }
    foreach ($skey in $keystoremove) {
        $Params.Remove($skey)
    }
    return $Params
}

#endregion

#region LmListObjects
function LmListObjects {
    param (
        [Parameter()][string[]]$ConfigName,
        [Parameter()][string]$Property,
        [Parameter()][int]$Color
    )
    if (-not $Color ) {
        $Color = "35"
    }
    $e = [char]27
    $objects = LmGetObjects -ConfigName $ConfigName
    if ($Property -and ($objects -is [array])) {
        $objects = $objects | Select-Object -ExpandProperty $Property
        $str = ($objects -join "=0`n") + "=0"
        $objects = ConvertFrom-StringData $str
    }

    $objects | Format-Table @{
        Label      = "$($ConfigName -join ".")";
        Expression = {
            "$e[${Color}m$($_.Key)${e}[0m"
        }
    }

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

    $hash = $hash | Sort-Object { if ($_.Value.ContainsKey($Key)) { $_.Value.$Key } else { $_.Value } }

    $sorted_hash = [System.Collections.Specialized.OrderedDictionary]@{}
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