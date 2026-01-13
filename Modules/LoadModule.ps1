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

$debugFlag = $true

#endregion

#region EvalParams

function EvalParams {
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

#region LmConvertObjectToHashtable LmGetLocalizedResourceName

function LmConvertObjectToHashtable {
    [CmdletBinding()]
    #[OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        [object]$InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return $null
        }
        if ($InputObject -is [Hashtable] -or $InputObject.GetType().Name -eq 'OrderedDictionary') {
            return $InputObject
        }
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    LmConvertObjectToHashtable -InputObject $object
                }
            )

            return $collection
        }
        elseif ($InputObject -is [psobject] -and ($InputObject.psobject.properties | Where-Object { $_.IsSettable })) {
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

#endregion

#region LmListObjects
function LmListObjects {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object[]]$ConfigPath,
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$PropertyName = "name",
        [Parameter(Mandatory = $false, Position = 2)]
        [int]$Color
    )
    if (-not $Color ) {
        $Color = "35"
    }
    $e = [char]27
    $objects = LmGetObjects $ConfigPath

    if ($PropertyName -and ($objects -is [array])) {
        $objects = $objects | Select-Object @{
            n = "name"
            e = {
                if ($_ -is [hashtable] -and $_.ContainsKey($PropertyName)) {
                    $_.$PropertyName
                }
                elseif ($_ -is [string]) {
                    $_
                }
            }
        }
        $objects = $objects | Select-Object -ExpandProperty "name"
        $str = ($objects -join "=0`n") + "=0"
        $objects = ConvertFrom-StringData $str
    }

    $_fullName = LmJoinObjects -Objects $ConfigPath
    $objects | Format-Table @{
        Label      = "$_fullName"
        Expression = {
            "$e[${Color}m$($_.Key)${e}[0m"
        }
    }

}

#endregion

#region LmJoinObjects LmGetConfigPath

function LmGetConfigPath {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$ConfigPath
    )
    $_outArray = @()
    for ($i = 0; $i -lt $ConfigPath.Length; $i++) {
        if ($i -eq 0 -and $ConfigPath[$i].Contains('.')) {
            $_outArray += $ConfigPath[$i].Split('.')
        }
        else {
            $_outArray += $ConfigPath[$i]
        }
    }
    return $_outArray
}

function LmJoinObjects {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Objects
    )
    $sb = [System.Text.StringBuilder]::new()

    foreach ($item in $Objects) {
        if ($item -is [string]) {
            [void]$sb.Append("$item.")
        }
        elseif ($item -is [hashtable]) {
            foreach ($key in $item.Keys) {
                [void]$sb.Append("$key-$($item[$key]).")
            }
        }
    }
    [void]$sb.Remove($sb.Length - 1, 1)
    $sb.ToString()
}

#endregion

#region LmGetObjects
# .SYNOPSIS
#     Get object from json config Filed
# .PARAMETER ConfigName
#     [Parameter(Mandatory = $true)] [string[]] Config name in config file
# .PARAMETER SelectorProperty
#     [Parameter(Mandatory = $false)] [string] Property name for select object in array
# .PARAMETER $LocationFolder
#     [Parameter(Mandatory = $false)] [string] Configs location folder
# .NOTES
#     ConfigName - array of names for get object from json config file
#     First element must be path to the folder where config file is located and config file name without extension
#     Second and next elements are names or hashtables for select object in array
#     Author : Agitech
#     Version : 0.0.1
function LmGetObjects {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object[]]$ConfigPath,
        [Parameter(Mandatory = $false)]
        [string]$SelectorProperty = "name",
        [Parameter(Mandatory = $false)]
        [string]$OrderProperty,
        [Parameter(Mandatory = $false)]
        [string]$LocationFolder = ".configs"
    )

    $array = LmGetConfigPath($ConfigPath)

    $_fullName = LmJoinObjects -Objects $ConfigPath

    $jsonConfigsFolder = Join-Path $PSScriptRoot "..\$LocationFolder" | Resolve-Path -ErrorAction SilentlyContinue

    if (-not (Test-Path -Path $jsonConfigsFolder -PathType Container)) {
        Write-Host "Invalid configs location folder $LocationFolder" -ForegroundColor Red
        return
    }

    $_object = $null
    $_found = $false

    for ($i = 0; $i -lt $array.Length; $i++) {
        $_selector = $SelectorProperty
        $_item = $array[$i]
        $_currentFolder = [System.IO.Path]::Combine([string[]]$(@($jsonConfigsFolder) + [string[]]$array[0..$i] | Where-Object { $_ -ne "*" }))
        if ($_item -is [hashtable]) {
            $_selector = [System.Linq.Enumerable]::ToArray([System.Object[]]$_item.Keys)[0]
            $_item = $_item[$_selector]
        }
        $_folder = $null
        $_rightBound = $i -eq ($array.Length - 1)
        if ($null -eq $_object) {
            if (Test-Path $_currentFolder -PathType Container) {
                $_folder = $_currentFolder
            }
            if ($_rightBound -and $_item -eq "*") {
                $_inner_object = LmGetObjects_LoadFolder -FolderPath $_currentFolder
                if ($_inner_object) {
                    $_object = $_inner_object
                }
            }
            elseif ($_rightBound -and $_folder) {
                $_object = Get-ChildItem -Path "$_folder" | Select-Object -ExpandProperty BaseName
            }
            else {
                $_currentPath = "$_currentFolder.json"
                if ((Test-Path $_currentPath -PathType Leaf)) {
                    $_object = LmGetObjects_LoadFile($_currentPath)

                }
            }
        }
        else {
            if ($_item -ne "*") {
                if ($_object -is [array]) {
                    $_object = $_object | Where-Object {
                        if ($_.ContainsKey($_selector)) {
                            $_.$_selector -eq $_item
                        }
                    }
                }
                elseif ($_object -is [hashtable]) {
                    if ($_object.ContainsKey($_item)) {
                        $_object = $_object[$_item]
                    }
                    else {
                        break
                    }
                }
                else {
                    Write-Host "The variable is of an unrecognized type."
                }
            }
        }

        if ($_rightBound -and $_object) {
            $_found = $true
        }
    }

    if (-not $_found) {
        Write-Host "Object $_fullName not found." -ForegroundColor DarkRed
        return $null
    }

    if ([System.String]::IsNullOrWhiteSpace($OrderProperty)) {
        if($_object.ContainsKey("file_name")){
            $_object = $_object | Sort-Object {$_.file_name}
        }

    }

    return $_object
}
#endregion

#region LmGetObjects_LoadFile LmGetObjects_LoadFolder

function LmGetObjects_LoadFile {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath
    )

    $_object = $null
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        return $_object
    }
    $_fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $_json = Get-Content $FilePath | Out-String
    $_object = ConvertFrom-Json -InputObject $_json
    $_object.Add("file_name",$_fileName)
    $_object = LmConvertObjectToHashtable -InputObject $_object

    return $_object
}

function LmGetObjects_LoadFolder {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FolderPath
    )

    $_object = $null
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        return $_object
    }
    $_files = Get-ChildItem -Path $FolderPath | Where-Object {
        $_.Extension -eq ".json"
    }
    foreach ($_file in $_files) {
        $_filePath = $_file.FullName
        $_inner_object = LmGetObjects_LoadFile($_filePath)
        if ($_inner_object) {
            if (-not $_object) {
                $_object = @($_inner_object)
            }
            else {
                $_object = $_object + $_inner_object
            }
        }
    }
    return $_object
}

#endregion

#region LmGetParams

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

#region LmWriteHostColorable LmTestFunction
function Write-HostColorable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Messages,
        [Parameter(Mandatory = $true, Position = 1)]
        [array]$Colors
    )
    LmWriteHostColorable @PSBoundParameters
}

function LmWriteHostColorable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Messages,
        [Parameter(Mandatory = $true, Position = 1)]
        [array]$Colors
    )
    $Colors = @($Colors)
    $c_index = 0
    for ($i = 0; $i -lt $Messages.Length; $i++) {
        $_message = $Messages[$i]
        if (-not [string]::IsNullOrEmpty($_message)) {
            if ($c_index -gt $Colors.Length - 1) {
                $c_index = 0
            }
            $params = @{
                "Object"          = "$($Messages[$i]) "
                "ForegroundColor" = $Colors[$c_index]
            }
            if ($i -lt $Messages.Length - 1) {
                $params["NoNewline"] = $true
            }
            Write-Host @params
        }
        $c_index++
    }
}

function LmTestFunction {
    param (
        [Parameter(Mandatory = $true)] [string]$Name
    )
    Test-Path -Path "function:${Name}"
}

#endregion

#region  LmSortHashtableByKey LmSortHashtableByPropertyValue

function LmSortCollectionByPropertyValue {
    param (
        [Parameter(Mandatory = $true)][System.Collections.IEnumerable]$InputObject,
        [Parameter(Mandatory = $true)][string]$Key
    )
    $_retObject = $InputObject
    $_flag = $true
    if ($InputObject -is [array]) {
        $_retObject = $InputObject | Sort-Object {
            if ($_.ContainsKey($Key)) {
                $_.$Key
            }
            else {
                $_
            }
        }
    }
    elseif ($InputObject -is [hashtable]) {
        $_retObject = LmSortHashtableByPropertyValue -InputHashtable $InputObject -Key $Key
    }
    else {
        $_flag = $false
    }
    if (-not $_flag) {
        Write-Host "Unsupported for sorting object type." -ForegroundColor DarkYellow
    }
    return  $_retObject
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

function LmTestModule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    $ChildPath = $ModuleName.Replace("$ModulePrefix.", "").Replace(".", "\")
    $result = $true
    $LibraryPath = (Join-Path $LibraryBaseFolder $ChildPath)
    try {
        $LibraryPath = Resolve-Path -Path $LibraryPath -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        $result = $false
    }
    return $result
}

function LmScanModule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleFullName
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
        if ($item.Name -match ".*_run.ps1$") {
            if ($verbose) {
                $_backup_color = $Host.PrivateData.VerboseForegroundColor
                $Host.PrivateData.VerboseForegroundColor = 'Red'
                Write-Verbose "Script: $($item.FullName) is skipped."
                $Host.PrivateData.VerboseForegroundColor = $_backup_color
            }
            continue
        }
        if ($item.FullName -ine $Parent.ScriptName) {
            $script = $script + ". $($item.FullName)" + [System.Environment]::NewLine
            if ($verbose) {
                Write-Verbose "Script: $($item.FullName) is loaded."
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
    #Import-Module $module -Scope "Local" -Force -DisableNameChecking
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
            if (-not (LmTestModule -ModuleName $ModuleName)) {
                Write-Host "Invalid module name [$ModuleName]." -ForegroundColor Red
                continue
            }
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