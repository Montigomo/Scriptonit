#Requires -RunAsAdministrator
#--Requires -Version 6.0
#--Requires -PSEdition Core

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "UserFolders", "Network", "winget", "UserSettings") -Force | Out-Null


#region Menu

function JsonMenuRunOperation {
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Action,
        [Parameter(Mandatory = $false)]
        [string]$ActionProperty = "name",
        [Parameter(Mandatory = $false)]
        [string]$ParamsProperty = "params"
    )
    $_currentJob = $Action
    $_currentJobName = $_currentJob.$ActionProperty
    if (-not (Test-Path -Path "function:${_currentJobName}")) {
        Write-Host "Job with name $_currentJobName not found."
        continue
    }
    $_params = $_currentJob[$ParamsProperty]
    Write-Host "Starting job $_currentJobName ..."
    if ($_params) {
        $_params = LmConvertObjectToHashtable $_params
        $_params = EvalParams -params $_params
        &"$_currentJobName" @_params
    }
    else {
        &"$_currentJobName"
    }
}

function JsonMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Object
    )

    $ref_keys = @("type", "message", "objects")
    $menu_keys = [array]$Object.Keys
    #$res = Compare-Object -ReferenceObject $keys -DifferenceObject $keysd -IncludeEqual
    #$res = Compare-Object -ReferenceObject $keys -DifferenceObject $keysd | Where-Object {$_.sideindicator -eq "<="} | ForEach-Object {$_.inputobject}
    $keys_result = -not @($ref_keys | Where-Object { $menu_keys -notcontains $_ }).Count

    if (-not $keys_result) {
        Write-Host "Wrong menu level tags" -ForegroundColor DarkYellow
        return
    }

    $MenuMessage = $Object["message"]
    $MenuObjects = $Object["objects"]
    $OrderProperty = $Object["OrderProperty"]
    $NameProperty = "name"
    $IdProperty = "index"
    if (-not $IdProperty) {
        $IdProperty = "id"
    }
    if (-not $OrderProperty) {
        $OrderProperty = "order"
    }
    if (-not $MenuMessage) {
        Write-Host "Wrong menu level message" -ForegroundColor DarkYellow
        return
    }

    while ($true) {

        $items = $MenuObjects
        [array]$list = $null
        if (-not $items) {
            Write-Host "Empty menu level" -ForegroundColor DarkYellow
            break
        }

        if ($OrderProperty) {
            $items = $items | Sort-Object -Property { $_[$OrderProperty] }
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

        $list | Format-Table

        $key = Read-Host $MenuMessage

        if ($key -eq "Q") {
            break
        }
        $_item = $list | Where-Object { $_.$IdProperty -eq $key }
        if ($_item) {
            $SelectedObject = $MenuObjects | Where-Object { $_.$NameProperty -eq $_item.$NameProperty }
            $itemType = $SelectedObject."type"
            switch ($itemType) {
                "action" {
                    JsonMenuRunOperation -Action $SelectedObject
                    break
                }
                "list" {
                    JsonMenu -Object $SelectedObject
                    break
                }
            }
        }
        else {
            Write-Host "Wrong choise." -ForegroundColor DarkYellow
        }
        Start-Sleep -Milliseconds 500
    }
}

#endregion


JsonMenu -Object $(LmGetObjects -ConfigName @("Users"))