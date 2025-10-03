Set-StrictMode -Version 3.0


# .SYNOPSIS
#   get id hash nased on pc hardware components
# .DESCRIPTION
#   get id hash nased on pc hardware components (CPU, bios> matherbord)
# .OUTPUTS
#   [string] iad ahsh string
function Get-HardwareHashId {

    function GetIdentifier {
        [CmdletBinding()]
        param (
            [Parameter()][string]$ClassName,
            [Parameter()][string[]]$Properties
        )
        $result = [System.String]::Empty
        $items = Get-WmiObject -Class $ClassName;
        foreach ($item in $items) {
            foreach ($property in $Properties) {
                $result += $item | Select-Object -ExpandProperty $property -ErrorAction SilentlyContinue
            }
        }
        return $result
    }

    $command = Get-Command "Get-WmiObject" -ErrorAction SilentlyContinue
    if (-not $command -or ($command.CommandType -eq "Alias")) {
        if ($PSVersionTable.PSEdition -eq "Core" -and (Get-Command "Get-CimInstance")) {
            $alias = Get-Alias | Where-Object { ($_.Name -eq "Get-WmiObject") -and ($_.ReferencedCommand.Name -eq "Get-CimInstance") }
            if (-not $alias) {
                New-Alias -Name "Get-WmiObject" -Value "Get-CimInstance"
            }
        }
    }


    $hstr = GetIdentifier -ClassName "Win32_Processor" -Properties "UniqueId"

    if ([System.String]::IsNullOrWhiteSpace($hstr)) {
        $hstr = GetIdentifier -ClassName "Win32_Processor" -Properties "ProcessorId"
        if ([System.String]::IsNullOrWhiteSpace($hstr)) {
            $hstr = GetIdentifier -ClassName "Win32_Processor" -Properties "Name"
            if ([System.String]::IsNullOrWhiteSpace($hstr)) {
                $hstr = GetIdentifier -ClassName "Win32_Processor" -Properties "Manufacturer"
            }
            $hstr += GetIdentifier -ClassName "Win32_Processor" -Properties "MaxClockSpeed"
        }
    }
    $hstr += GetIdentifier -ClassName "Win32_BIOS" -Properties @("Manufacturer", "SMBIOSBIOSVersion", "IdentificationCode", "SerialNumber", "ReleaseDate", "Version")
    $hstr += GetIdentifier -ClassName "Win32_BaseBoard" -Properties @("Model", "Manufacturer", "Name", "SerialNumber")
    $hstr += GetIdentifier -ClassName "Win32_VideoController" -Properties @("PNPDeviceID")
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($hstr))) -replace "-", ""
    return $hash.ToLower()
}

#Get-HardwareHashId