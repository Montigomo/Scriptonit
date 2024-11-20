function Test-Ping {
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)][string] $IPAddress,
        [int] $TimeoutMillisec = 1000
    )
    
    begin {
        $pinger = [Net.NetworkInformation.Ping]::new() 
    }
    process {
        $reply = $pinger.Send($IPAddress, $TimeoutMillisec) 
        [ PSCustomObject]@{
            IPAddress = $IPAddress
            Port      = "ping"
            Response  = ($reply.Status -eq 'Success')
        }
    }
    end {
        $pinger.Dispose()
    }
}