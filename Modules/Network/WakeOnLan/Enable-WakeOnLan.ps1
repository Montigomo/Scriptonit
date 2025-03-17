Set-StrictMode -Version 3.0

function Enable-WakeOnLan {
    param(
        [Parameter(Mandatory = $true)][ciminstance]$NetAdapter
    )

    $paramsSet = @{
        "*EEE"                        = "0"
        "AdvancedEEE"                 = "0"
        "Green Ethernet"              = "0"
        "EnableGreenEthernet"         = "0"
        "*WakeOnMagicPacket"          = "1"
        "*WakeOnPattern"              = "1"
        "S5WakeOnLan"                 = "1"
        "PowerSavingMode"             = "0"
        "ModernStandbyWoLMagicPacket" = "1"
    }

    $adapterProperties = Get-NetAdapterAdvancedProperty -InterfaceDescription $NetAdapter.InterfaceDescription -IncludeHidden

    #$paramsKey = $paramsSet.Keys | Where-Object { [System.Array]::Exists($adapterProperties, ([Predicate[Object]] { param($s) $s.RegistryKeyword -eq $_ })) }

    foreach ($property in $adapterProperties) {

        $propertyName = $property.RegistryKeyword
        $propertyValue = $property.RegistryValue
        $propertyValidValues = $property.ValidRegistryValues

        $items = @($paramsSet.Keys | Where-Object { $propertyName -eq $_ })

        if (-not $items ) {
            continue
        }
        elseif ($items.Count -gt 1) {
            Write-Host "Property " -ForegroundColor DarkGreen -NoNewline
            Write-Host "$propertyName " -ForegroundColor DarkYellow -NoNewline
            Write-Host "collision." -ForegroundColor DarkGreen

        }
        else {
            try {
                $value = $paramsSet[$propertyName]
                $colorWarning = [System.ConsoleColor]::DarkGreen
                if ($propertyValue -ne $value) {
                    $colorWarning = [System.ConsoleColor]::DarkRed
                }
                Write-Host "Property " -ForegroundColor DarkGreen -NoNewline
                Write-Host "$propertyName " -ForegroundColor DarkYellow -NoNewline
                Write-Host "value is " -ForegroundColor DarkGreen -NoNewline
                Write-Host "$propertyValue " -ForegroundColor DarkYellow -NoNewline
                Write-Host "must be " -ForegroundColor $colorWarning -NoNewline
                Write-Host "$value" -ForegroundColor DarkYellow

                if ($propertyValidValues -notcontains $value) {
                    Write-Host "Value " -ForegroundColor DarkGreen -NoNewline
                    Write-Host "$value " -ForegroundColor DarkYellow -NoNewline
                    Write-Host "is not valid for this property." -ForegroundColor DarkGreen

                }
                else {
                    if ($propertyValue -ne $value) {

                        Set-NetAdapterAdvancedProperty -InterfaceDescription $NetAdapter.InterfaceDescription -RegistryKeyword $propertyName -RegistryValue $value -ErrorAction Stop

                        $propertyValue = $property.RegistryValue
                        Write-Host "Property " -ForegroundColor DarkGreen -NoNewline
                        Write-Host "$propertyName " -ForegroundColor DarkYellow -NoNewline
                        Write-Host "value changed to " -ForegroundColor DarkGreen -NoNewline
                        Write-Host "$propertyValue." -ForegroundColor DarkYellow
                    }
                }
            }
            catch [Microsoft.Management.Infrastructure.CimException] {
                Write-Verbose $_.Exception.Message
            }
        }
    }

}