Set-StrictMode -Version 3.0

function SetRdpConnections {
    param(
        [Parameter(Mandatory = $false)][switch]$Disable
    )

    Write-Host "[SetRdpConnections] started ..." -ForegroundColor DarkYellow

    $resName = LmGetLocalizedResourceName -ResourceName "NetFirewal.DisplayGroup.Remote Desktop"

    if ($Disable) {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 1
        Disable-NetFirewallRule -DisplayGroup "$resName"
    }
    else {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
        Enable-NetFirewallRule -DisplayGroup "$resName"
    }
}