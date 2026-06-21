#requires -RunAsAdministrator

#using module D:\software\scripts\Modules\Windows\Health\SfcScanner.ps1

Set-StrictMode -Version Latest

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Windows.Health") -Force | Out-Null

enum DismHealthStatus {
    Healthy
    Repairable
    Error
}

#. D:\software\scripts\Modules\Windows\Health\SfcScanner.ps1

# this file should save with encoding utf8 with bom, otherwise dism.exe output will be garbled and unreadable.
# If you see garbled text in the log file, please change the encoding of this file to utf8 with bom and run again.



function SfcCheck {

    $sfc = New-SfcScannerObject

    $scanResult = $sfc.ScanOnly()

    if ($scanResult.IntegrityViolations) {

        Write-Host "System file corruption detected!" -ForegroundColor Red

        if ($scanResult.CorruptedFiles.Count -gt 0) {
            Write-Host "Corrupted files: $($scanResult.CorruptedFiles.Count)" -ForegroundColor Yellow

            $repairResult = $sfc.ScanAndRepair()

            if ($repairResult.Success) {
                Write-Host "Repair completed successfully!" -ForegroundColor Green
                Write-Host "Repaired $($repairResult.RepairedFiles.Count) files"
            }
            else {
                Write-Host "Repair failed or incomplete!" -ForegroundColor Red
                if ($repairResult.CouldNotRepairFiles.Count -gt 0) {
                    Write-Host "Files that could not be repaired:"
                    $repairResult.CouldNotRepairFiles | Write-Host -ForegroundColor Red
                }
            }
        }
    }
    else {
        Write-Host "System integrity verified - no issues found" -ForegroundColor Green
    }
}


function DismCheck {
    $dism = New-DismManager
    $_result = $dism.CheckHealth()
    Show-DismResult -Result $_result

    # Check health
    if ($_result.Health -eq [DismHealthStatus]::Repairable) {
        $_result = $dism.ScanHealth()
        Show-DismResult -Result $_result
        if ($_result.Health -eq [DismHealthStatus]::Healthy) {
            Write-Host "Image health check passed"
        }
    }

}


SfcCheck

DismCheck