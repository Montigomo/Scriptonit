

function DoTasksActions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [array]$Tasks,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Disable', 'Enable', 'Start', 'Stop', 'Register', 'Unregister')]
        [string]$Action
    )
    begin {

    }
    process {
        foreach ($item in $Tasks) {
            $_task = Get-ScheduledTask -TaskName $item -ErrorAction SilentlyContinue
            if ((-not $_task)) {
                continue
            }
            switch ($Action) {
                'Disable' {
                    $_task | Disable-ScheduledTask -Confirm:$false;
                    break
                }
                'Enable' {
                    $_task | Enable-ScheduledTask -Confirm:$false;
                    break
                }
                'Start' {
                    $_task | Start-ScheduledTask -Confirm:$false;
                    break
                }
                'Stop' {
                    $_task | Stop-ScheduledTask #-Confirm:$false;
                    break
                }
                'Register' {
                    Write-Host "Not ready yet."
                    break
                }
                'Unregister' {
                    $_task | Unregister-ScheduledTask -Confirm:$false;
                    break
                }
                Default {
                    break
                }
            }
        }
    }
    end {
        $Tasks
    }
}