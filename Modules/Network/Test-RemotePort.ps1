function Test-RemotePort {
    param
    (
        [Parameter(Mandatory)] [int] $Port ,
        [string] $IPAddress,
        [int] $TimeoutMilliSec = 1000
    )
    
    try {
        $client = [Net.Sockets.TcpClient]:: new()
        $task = $client.ConnectAsync($IPAddress , $Port)
        if ($task.Wait($TimeoutMilliSec )) {
            $success = $client.Connected
        }
        else {
            $success = $false 
        }
    }
    catch { $success = $false }
    finally {
        $client.Close()
        $client. Dispose()
    }
    
    [ PSCustomObject]@{
        IPAddress = $IPAddress
        Port      = $Port
        Response  = $success
    }
}