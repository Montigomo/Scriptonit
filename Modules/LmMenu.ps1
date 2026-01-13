[CmdletBinding()]
param (
    [Parameter()][string[]]$ModuleNames,
    [Parameter()][switch]$Force
)

Set-StrictMode -Version 3.0

#region LmMenu
function LmMenuRunOperation {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Action,
        [Parameter(Mandatory = $false)]
        [string]$NameProperty = "name",
        [Parameter(Mandatory = $false)]
        [string]$ParamsProperty = "params",
        [Parameter(Mandatory = $false)]
        [string]$ModulesProperty = "modules"
    )

    $_job = $Action

    if (-not $_job.ContainsKey($NameProperty)) {
        Write-Host "Can't get job name." -ForegroundColor Red
        return
    }

    $_jobName = $_job.$NameProperty

    $_modules = $null
    if ($_job.ContainsKey($ModulesProperty)) {
        $_modules = $_job.$ModulesProperty
    }

    $_params = $null
    if ($_job.ContainsKey($ParamsProperty)) {
        $_params = $_job.$ParamsProperty
    }

    $script = "Set-StrictMode -Version 3.0" + [System.Environment]::NewLine
    $script += '$_lparams = $_params' + [System.Environment]::NewLine
    $script += '$_jobName = $_jobName' + [System.Environment]::NewLine
    if ($_modules) {
        $modstr = ($_modules | ForEach-Object { '"' + $_ + '"' }) -join ", "
        $script += '. "' + $PSScriptRoot + '\LoadModule.ps1" -ModuleNames @(' + $modstr + ') -Force | Out-Null' + [System.Environment]::NewLine
    }
    #$script = $script + 'Write-Host $_params' + [System.Environment]::NewLine

    $script = $script +
    @'
if (-not (Test-Path -Path "function:${_jobName}")) {
    Write-Host "Job with name $_jobName not found."
    return
}
Write-Host "Starting job $_jobName ..."
if ($_lparams) {
    $_lparams = LmConvertObjectToHashtable $_lparams
    $_lparams = EvalParams -params $_lparams
    return &"$_jobName" @_lparams
}
else {
    return &"$_jobName"
}
'@

    $sb = [ScriptBlock]::Create($script)
    return &$sb
}

function LmMenuSelectObject {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Objects,
        [Parameter(Mandatory = $false)]
        [string]$OrderProperty = "order",
        [Parameter(Mandatory = $false)]
        [string]$NameProperty = "name",
        [Parameter(Mandatory = $false)]
        [string]$IdProperty = "id",
        [Parameter(Mandatory = $false)]
        [string]$MenuMessage = "Select item"
    )

    $SelectedObject = $null

    $items = $Objects

    [array]$list = @()

    if (-not $items) {
        Write-Host "Empty menu level" -ForegroundColor DarkYellow
        break
    }

    if ($OrderProperty) {
        $items = $items | Sort-Object -Property {
            if (($_ -is [hashtable]) -and $_.ContainsKey($OrderProperty)) {
                $_.$OrderProperty
            }
        }
    }

    $j = 0
    $i = 1
    $indarr = @("0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,j,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,x,z" -split ",")

    foreach ($item in $items) {

        if ($list -and ($list | Where-Object { $_.$NameProperty -eq $item.$NameProperty } )) {
            continue
        }
        $_i = $($indarr[$i])
        $_j = $($indarr[$j])
        if ($_i -eq "q" -and $_j -eq 0) {
            $i++
            $_i = $($indarr[$i])
        }
        if ($_j -eq "0") {
            $_j = ""
        }
        $_index = "$_j$_i"
        $i++
        if ($i -ge $indarr.Length) {
            $i = 0
            $j++
        }
        $list += [pscustomobject]@{
            $IdProperty   = $_index
            $NameProperty = $item.$NameProperty
        }
    }

    $list += [pscustomobject]@{
        $IdProperty   = "q"
        $NameProperty = "Exit"
    }

    foreach ($item in $list) {
        Write-Host "$($item.id) - "$($item.name)""
    }

    $key = Read-Host $MenuMessage

    if ($key -eq "Q") {
        $SelectedObject = "quit"
    }
    else {
        $_item = $list | Where-Object { $_.$IdProperty -eq $key }
        if ($_item) {
            $SelectedObject = $Objects | Where-Object { $_.$NameProperty -eq $_item.$NameProperty }
        }
        else {
            Write-Host "Wrong choise." -ForegroundColor DarkYellow
        }
    }
    return $SelectedObject
}

function LmMenuParseList {
    param (
        [Parameter(Mandatory = $true)]
        [object]$ListNode
    )

}

function LmMenuParseLeaf {
    param (
        [Parameter(Mandatory = $true)]
        [object]$LeafNode
    )

}


function LmMenu {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'JsonString')]
        [string]$JsonString,
        [Parameter(Mandatory = $true, ParameterSetName = 'JsonFilePath')]
        [string]$JsonFilePath,
        [Parameter(Mandatory = $true, ParameterSetName = 'Object')]
        [hashtable]$InputObject
    )

    function getNodeProperty {
        param(
            [Parameter(Mandatory = $true)]
            [object]$inputObject,
            [Parameter(Mandatory = $true)]
            [string]$propertyName,
            [Parameter(Mandatory = $false)]
            [object]$defaultValue
        )

        $retValue = $defaultValue

        if ((-not $inputObject.ContainsKey($propertyName))) {
            Write-Host "Menu level objects not have [$($propertyName)] property." -ForegroundColor DarkYellow
            return $null
        }

        $retValue = $Object.$propertyName
        return $retValue
    }

    switch ($PSCmdlet.ParameterSetName) {
        'JsonString' {
            $Object = ConvertFrom-Json -InputObject $SettingsJsonString | LmConvertObjectToHashtable
            break
        }
        'JsonFilePath' {
            $Object = LmGetObjects -ConfigName $JsonFilePath -LocationFolder ".menu"
            break
        }
        'Object' {
            $Object = $InputObject
            break
        }
    }

    if (-not $Object) {
        return
    }

    $_nodeType = getNodeProperty -inputObject $Object -propertyName "type" -defaultValue "list"


    switch ($_nodeType) {
        "list" {
            LmMenuParseList -ListNode $Object
            break
        }
        "leaf" {
            LmMenuParseLeaf -LeafNode $Object
            break
        }
        Default {
            Write-Host "Unknown node type: $_nodeType"
            break
        }
    }



    $value = getObjectProperty -inputObject $Object -propertyName "value"

    $menuMessage = getObjectProperty -inputObject $Object -propertyName "message" -defaultValue "Select item"

    #region Filed map

    $OrderProperty = "order"
    $NameProperty = "name"
    $IdProperty = "id"

    if ($Object.ContainsKey("fieldsMap")) {
        $filedsMap = $Object."fieldsMap"
        if ($filedsMap.ContainsKey("OrderProperty")) {
            $OrderProperty = $filedsMap."OrderProperty"
        }
        if ($filedsMap.ContainsKey("NameProperty")) {
            $OrderProperty = $filedsMap."NameProperty"
        }
        if ($filedsMap.ContainsKey("IdProperty")) {
            $OrderProperty = $filedsMap."IdProperty"
        }
    }

    #endregion

    $valueType = getObjectProperty -inputObject $value -propertyName "valueType"

    $_retValue = $null

    while ($true) {
        $_resObject = $null
        $_arrayObject = $null
        switch ($valueType) {
            "script" {
                $_scriptName = $Object."objects"
                $_scriptPath = $PSScriptRoot + "\..\.menu\$_scriptName"
                $_scriptPath = Resolve-Path $_scriptPath
                if (Test-Path $_scriptPath) {
                    $_arrayObject = & "$_scriptPath"
                }
                break
            }
            "function" {
                $_retValue = LmMenuRunOperation -Action $InputObject
                break
            }
            "config" {
                $configName = $Object."objects"
                $_arrayObject = LmGetObjects -ConfigName $configName
                break

            }
            "array" {
                $_arrayObject = $Object."objects"
                break
            }
            "value" {
                $_retValue = $Object."value"
                break
            }
            default {
                Write-Host "Wrong menu type" -ForegroundColor Red
                break
            }
        }
        if (-not $_arrayObject) {
            $_resObject = $null
        }
        else {
            $_resObject = LmMenuSelectObject -Objects $_arrayObject -MenuMessage $MenuMessage
        }
        if (($_resObject -is [string] -and $_resObject -eq "quit") -or ($null -eq $_resObject)) {
            break
        }
        else {
            $_value = LmMenu -InputObject $_resObject
            $Object.value = $_value
        }
    }

    return $_retValue
}
#endregion
