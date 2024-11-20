Set-StrictMode -Version 3.0

function UpdateTypeData() {

    $td = Get-TypeData -TypeName "System.Management.Automation.PSCustomObject"
    if ((-not $td) -or ($td -and (-not $td.Members.ContainsKey("ContainsKey")))) {
        $params = @{
            TypeName   = 'System.Management.Automation.PSCustomObject'
            MemberType = 'ScriptMethod'
            MemberName = 'ContainsKey'
            Value      = { 
                Param($Key)
                [bool]$this.psobject.Properties.GetEnumerator().MoveNext() -and ($this.psobject.Properties.name -match $Key)
                #[bool]($this.psobject.Properties.name -match $Key) 
            }
        }
    
        Update-TypeData @params -Force
    }

    if ((-not $td) -or ($td -and (-not $td.Members.ContainsKey("Add")))) {
        $params = @{
            TypeName   = 'System.Management.Automation.PSCustomObject'
            MemberType = 'ScriptMethod'
            MemberName = 'Add'
            Value      = { 
                Param($Key, $Value) 
                Add-Member -InputObject $this -MemberType NoteProperty -Name $Key  -Value $Value 
            }
        }
    
        Update-TypeData @params -Force
    }
}

function Disable-FastStartUp {
    #Disable Windows 10 fast boot via Powershell
    # /v is the REG_DWORD /t Specifies the type of registry entries /d Specifies the data for the new entry /f Adds or deletes registry content without prompting for confirmation.
    #REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d "0" /f
    # /v is the REG_DWORD /t Specifies the type of registry entries /d Specifies the data for the new entry /f Adds or deletes registry content without prompting for confirmation.
    #REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d "0" /f

    UpdateTypeData

    $riParams = @{
        Path         = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
        Name         = "HiberbootEnabled"
        PropertyType = "DWord"
        Value        = 0
    }

    $regi = Get-ItemProperty -Path $riParams.Path

    $needAction = (-not $regi.ContainsKey("HiberbootEnabled")) -or ($regi.HiberbootEnabled -ne 0)

    if ($needAction) {
        if (-not $regi.ContainsKey("HiberbootEnabled")) {
            Write-Host "Faststartup reg key doesn't exist." -ForegroundColor DarkYellow
            New-ItemProperty @riParams | Out-Null
        }
        else {
            $params = @{
                Path  = $riParams.Path
                Name  = $riParams.Name
                Value = $riParams.Value
            }
            Write-Host "Change faststartup reg key value." -ForegroundColor DarkYellow
            Set-ItemProperty @params
        }
    }
    Write-Host "Fast startup disabled." -ForegroundColor DarkYellow
    
}