
Set-StrictMode -Version 3.0

function Send-MagicPacket {
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$')] [string[]]$MacAddresses,
        [Parameter(Mandatory = $false)] [string]$BroadcastProxy,
        [Parameter(Mandatory = $false)] [int]$Port = 9
    )

    begin {
        # instantiate a UDP client:
        $UDPclient = [System.Net.Sockets.UdpClient]::new()
        $UdpClient.Client.EnableBroadcast = $true
    }
    process {
        foreach ($_ in $MacAddresses) {
            try {
                $mac = $_

                #region compose the "magic packet"
                # create a byte array with 102 bytes initialized to 255 each:
                # leave the first 6 bytes untouched, and repeat the target mac address bytes in bytes 7 through 102:
                $bmac = $mac -split '[:-]' | ForEach-Object { [System.Convert]::ToByte($_, 16) }
                # $bmac = $mac -Split ':' | ForEach-Object { [byte]('0x' + $_) }
                # $mac = (($mac.replace(":", "")).replace("-", "")).replace(".", "")
                # $bmac = 0, 2, 4, 6, 8, 10 | ForEach-Object { [convert]::ToByte($mac.substring($_, 2), 16) }

                $packet = [byte[]](, 0xFF) * 102
                6..101 | Foreach-Object { $packet[$_] = $bmac[($_ % 6)] }

                # $synchronization = [byte[]](, 0xFF) * 6
                # $packet = $synchronization + $bmac * 16

                # $packet = (, [byte]255 * 6) + ($bmac * 16)
                #endregion

                #region getting broadcast address
                $bip = [System.Net.IPAddress]::Broadcast;
                if ($BroadcastProxy) {
                    [Net.IPAddress]::TryParse($BroadcastProxy, [ref]$bip) | Out-Null
                }
                #endregion

                $UDPclient.Connect($bip, $Port)
                $UDPclient.Send($packet, $packet.Length) | Out-Null

                Write-Host "Magic packet with MAC-address " -ForegroundColor DarkGreen -NoNewline
                Write-Host "$mac " -ForegroundColor DarkYellow  -NoNewline
                Write-Host "sended to broadcast address " -ForegroundColor DarkGreen -NoNewline
                Write-Host "$($bip.ToString())" -ForegroundColor DarkYellow

            }
            catch {
                Write-Warning "Unable to send ${mac}: $_"
            }
        }
    }
    end {
        # release the UDF client and free its memory:
        $UDPclient.Close()
        $UDPclient.Dispose()
    }
}