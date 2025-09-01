


function DoServicesActions {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Services,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Restart', 'Stop', 'Start')]
        [string]$Action
    )

    foreach ($serviceName in $Services) {
        switch ($Action) {
            'Restart' {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    $service | Restart-Service
                }
                break
            }
            'Stop' {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service -and ($service.Status -ne 'Stopped')) {
                    Write-Host "Stopping " -ForegroundColor DarkGreen -NoNewline
                    Write-Host " $($service.Name) " -ForegroundColor DarkYellow -NoNewline
                    Write-Host "service" -ForegroundColor DarkGreen
                    $service | Stop-Service -ErrorAction SilentlyContinue
                }
                break
            }
            'Start' {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    $service | Set-Service -StartupType 'Automatic' | Start-Service
                }
            }
        }
    }
}