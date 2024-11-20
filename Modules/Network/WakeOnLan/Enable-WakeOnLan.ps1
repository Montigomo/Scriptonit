Set-StrictMode -Version 3.0

function Enable-WakeOnLan {
	param(
        [Parameter(Mandatory=$true)][ciminstance]$NetAdapter
	)

	$paramsSet = @{
		"Wake on Magic Packet"      = "Enabled|On"
		#"Wake on Pattern Match" = ""
		"Shutdown Wake-On-Lan"      = "Enabled"
		"Shutdown Wake Up"          = "Enabled"
		"Energy Efficient Ethernet" = "Disabled|Off"
		"Green Ethernet"            = "Disabled"
	}

    $adapterProperties = Get-NetAdapterAdvancedProperty -InterfaceDescription $NetAdapter.InterfaceDescription

	$paramsKey = $paramsSet.Keys | Where-Object { [System.Array]::Exists($adapterProperties, ([Predicate[Object]] { param($s) 	 $s.DisplayName -eq $_ })) }

	foreach ($item in $paramsKey) {
		foreach ($value in $paramsSet[$item].Split("|")) {
			try {
                $valueAdapter =Get-NetAdapterAdvancedProperty -InterfaceDescription $NetAdapter.InterfaceDescription -DisplayName $item
                Write-Host "$item is set $($valueAdapter.DisplayValue) must be $value" -ForegroundColor Green
				Set-NetAdapterAdvancedProperty -InterfaceDescription $NetAdapter.InterfaceDescription -DisplayName $item -DisplayValue $value -ErrorAction Stop
				break;
			}
			catch [Microsoft.Management.Infrastructure.CimException] {
				Write-Verbose $_.Exception.Message
			}
		}
	}
}