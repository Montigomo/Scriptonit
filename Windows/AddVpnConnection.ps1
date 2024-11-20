

# https://winitpro.ru/index.php/2022/01/24/upravlenie-vpn-podklyucheniyami-powershell/
# 

if (!(net session)) { $path = "& '" + $myinvocation.mycommand.definition + "'" ; Start-Process powershell -Verb runAs -ArgumentList $path ; exit }

function ConnectVpn{
    param (
        [Parameter()][string]$Name,
        [Parameter()][switch]$Disconnect
    )
    $vpn = Get-VpnConnection -Name $Name  -ErrorAction SilentlyContinue;
    if (-not $vpn) {
        return
    }

    if(-not $Disconnect -and ($vpn.ConnectionStatus -eq "Disconnected")){
        rasphone -d $Name
    }

    if(-not $Disconnect -and ($vpn.ConnectionStatus -eq "Connected")){
        rasphone -h $Name
    }    
}

function AddVpnConnection {
    param (
        [Parameter()][hashtable]$Params
    )

    if (-not (Get-VpnConnection -Name $Params["Name"] -ErrorAction SilentlyContinue)) {
        Add-VpnConnection @Params
    }
}

$params = @{
    "Name"                  = "JustNetKeeDns"
    "ServerAddress"         = "justnet.keenetic.name"
    "TunnelType"            = "sstp"
    "AuthenticationMethod"  = "MSChapv2" 
    "EncryptionLevel"       = "Optional" 
    "DnsSuffix"             = "justnet.local"
    "SplitTunneling"        = $true
    "IdleDisconnectSeconds" = 900 
    "RememberCredential"    = $true
    "AllUserConnection"     = $false
}

AddVpnConnection $params


$params = @{
    "Name"                  = "JustNetIp"
    "ServerAddress"         = "192.168.1.222"
    "TunnelType"            = "sstp"
    "AuthenticationMethod"  = "MSChapv2" 
    "EncryptionLevel"       = "Optional" 
    "DnsSuffix"             = "justnet.local"
    "SplitTunneling"        = $true
    "IdleDisconnectSeconds" = 900 
    "RememberCredential"    = $true
    "AllUserConnection"     = $false
}

AddVpnConnection $params






Install-Module -Name VPNCredentialsHelper

$params = @{
    "connectionname" = "JustNetKeeDns"
    "username"       = "agidesktop"
    "password"       = '5Aswby8X$85nd#JsS'
    "PassThru"       = $true
}

Set-VpnConnectionUsernamePassword @params

$params = @{
    "connectionname" = "JustNetIp"
    "username"       = "agidesktop"
    "password"       = '5Aswby8X$85nd#JsS'
    "PassThru"       = $true
}

Set-VpnConnectionUsernamePassword @params


#Remove-VpnConnection

#Add-VpnConnection -Name $VPNconnectionL2TP -ServerAddress $SRVaddressL2TP -TunnelType $VPNtypeL2TP -AuthenticationMethod $auth_method -L2tpPsk $l2tp_key -EncryptionLevel "Optional" -DnsSuffix $dnssuf  -SplitTunneling -IdleDisconnectSeconds 900 -RememberCredential -AllUserConnection