Set-StrictMode -Version 3.0

enum ServiceAction {
    Start
    Stop
    Restart
}


# .SYNOPSIS
#     
# .DESCRIPTION
#     
# .OUTPUTS
#     Author : Agitech   Version : 0.0.0.1
function Set-ServicesAction {
    param (
        [Parameter()][array]$Services,
        [Parameter()][ServiceAction]$Action
    )
    
    foreach ($serviceName in $Services) {
        switch ($Action) {
            Restart {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    $service | Restart-Service
                }
                break
            }
            Stop {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    $service | Stop-Service -ErrorAction SilentlyContinue
                }
                break
            }
            Start {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    $service | Set-Service -StartupType 'Automatic' | Start-Service
                }
            }
        }
    }
}