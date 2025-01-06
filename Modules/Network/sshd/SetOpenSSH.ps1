Set-StrictMode -Version 3.0

# .SYNOPSIS
#     Config openssh server 
# .DESCRIPTION
# .PARAMETER PublicKeys
#     [Parameter(Mandatory=$false)] [System.Array] public keys for write to authorized_keys
# .NOTES
#     Author: Agitech; Version: 1.00.07
function SetOpenSsh {  
    param(
        [Parameter(Mandatory = $false)] [System.Array]$PublicKeys
    )

    # set ssh-agent service startup type
    if (Get-Service  ssh-agent -ErrorAction SilentlyContinue) {
        if ((get-service sshd).StartType -ne [System.ServiceProcess.ServiceStartMode]::Manual) {
            Get-Service -Name ssh-agent | Set-Service -StartupType 'Automatic'
        }
        Start-Service ssh-agent
    }

    CheckSshdConfig

    if ($PublicKeys) {
        $sshAuKeyPathItems = @{
            local       = "$([System.IO.Path]::GetFullPath([System.IO.Path]::Combine("$PSScriptRoot","..\.ssh")))\authorized_keys";
            globalAdmin = "$env:ProgramData\ssh\administrators_authorized_keys"
        }

        foreach ($key in $sshAuKeyPathItems.Keys) {
            $item = $sshAuKeyPathItems[$key]
            if (!(Test-Path $item)) {
                new-item -Path $item  -itemtype File -Force
            }
            if ($sshPublicKeys -is [System.Array]) {
                foreach ($key in $PublicKeys) {
                    If (!(Select-String -Path $item -pattern $key -SimpleMatch)) {
                        Add-Content $item $key
                    }
                }
            }
        }
    }
   

    ### Config firewall
    if ((get-netfirewallrule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
        Remove-NetFirewallRule -Name "OpenSSH-Server-In-TCP" | Out-Null
    }
    if (-not (get-netfirewallrule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    }

    # Restart service
    if (Get-Service  sshd -ErrorAction SilentlyContinue) {
        Get-Service -Name sshd | Restart-Service 
    }
}