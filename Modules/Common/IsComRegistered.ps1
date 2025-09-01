
function IsComRegistered {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Guid,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$DllPath

    )
    $regKey = "Registry::HKEY_CLASSES_ROOT\CLSID\$Guid"
    $inProcServerKey = "Registry::HKEY_CLASSES_ROOT\CLSID\$Guid\InprocServer32"
    if(Test-Path -Path $regKey){
        $reg = Get-ItemProperty -Path $regKey -ErrorAction Stop
        $defValue = $reg.'(default)'
        if(Test-Path -Path $inProcServerKey){
            $reg = Get-ItemProperty $inProcServerKey -ErrorAction Stop
            if($reg.'(default)' -eq $DllPath){
                return $true
            }
        }
    }
    return $false
}

function Get-ComRegisteredDllPath {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$DllPath

    )
    $regKey = "Registry::HKEY_CLASSES_ROOT\CLSID\$Guid"
    $inProcServerKey = "Registry::HKEY_CLASSES_ROOT\CLSID\$Guid\InprocServer32"
    if(Test-Path -Path $regKey){
        $reg = Get-ItemProperty -Path $regKey -ErrorAction Stop
        $defValue = $reg.'(default)'
        if(Test-Path -Path $inProcServerKey){
            $reg = Get-ItemProperty $inProcServerKey -ErrorAction Stop
            if($reg.'(default)' -eq $DllPath){
                return $true
            }
        }
    }
    return $false
}