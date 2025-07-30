function DoProcessActions {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [ValidateSet('Stop')]
        [string]$Action = 'Stop',
        [Parameter(Mandatory = $false)]
        [switch]$ExePath
    )
    begin {

    }
    process {
        if ($ExePath) {
            $_processes = Get-Process | Where-Object { $_.Path -like $Name }
            foreach ($_process in $_processes) {
                Write-Host "Stopping process: $($_process.ProcessName) with ID: $($_process.Id)" -ForegroundColor DarkGreen
                Stop-Process -Id $_process.Id -Force
            }
        }
        else {
            $_item = Get-Process -Name $Name -ErrorAction SilentlyContinue
            if ($_item) {
                switch ($Action) {
                    'Stop' {
                        $_item | Stop-Process -ErrorAction SilentlyContinue -Force -Confirm:$false
                        break
                    }
                    Default {
                        break
                    }
                }
            }
        }
        $Name
    }
    end {

    }
}