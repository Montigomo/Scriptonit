
class SfcScanner {
    # Properties
    [string]$LogPath
    [string]$LastOutput
    [datetime]$LastScanTime
    [int]$LastExitCode

    # Constructor
    SfcScanner() {
        $this.LogPath = "$env:TEMP\SfcScanner_$(Get-Date -Format 'yyyyMMdd').log"
        $this.LastExitCode = -1
    }

    SfcScanner([string]$CustomLogPath) {
        $this.LogPath = $CustomLogPath
        $this.LastExitCode = -1
    }

    # Run SFC scan (verify only, no repair)
    [PSCustomObject] ScanOnly() {
        return $this.RunSfcCommand("/verifyonly")
    }

    # Run SFC scan with repair
    [PSCustomObject] ScanAndRepair() {
        return $this.RunSfcCommand("/scannow")
    }

    # Run custom SFC command
    [PSCustomObject] RunCustomCommand([string]$Parameters) {
        return $this.RunSfcCommand($Parameters)
    }

    # Private method to execute SFC commands
    hidden [PSCustomObject] RunSfcCommand([string]$Parameters) {
        $this.LastScanTime = Get-Date

        try {
            # Execute SFC command
            $_params = @{
                FilePath               = "sfc.exe"
                ArgumentList           = $Parameters
                NoNewWindow            = $true
                PassThru               = $true
                Wait                   = $true
                RedirectStandardOutput = "$env:TEMP\sfc_output.txt"
                RedirectStandardError  = "$env:TEMP\sfc_error.txt"
            }

            $process = Start-Process @_params

            $this.LastExitCode = $process.ExitCode

            # Read output
            $output = Get-Content "$env:TEMP\sfc_output.txt" -Raw
            $errorOutput = Get-Content "$env:TEMP\sfc_error.txt" -Raw

            $this.LastOutput = $output

            # Log the output
            $this.LogOutput($output, $errorOutput)

            # Parse the output
            $parsedResult = $this.ParseSfcOutput($output)
            $parsedResult.ExitCode = $this.LastExitCode
            $parsedResult.ErrorOutput = $errorOutput

            # Cleanup temp files
            Remove-Item "$env:TEMP\sfc_output.txt" -Force -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\sfc_error.txt" -Force -ErrorAction SilentlyContinue

            return $parsedResult

        }
        catch {
            Write-Error "Failed to run SFC command: $($_.Exception.Message)"
            return [PSCustomObject]@{
                Success             = $false
                ExitCode            = -1
                ErrorMessage        = $_.Exception.Message
                IntegrityViolations = $false
                CorruptedFiles      = @()
                RepairedFiles       = @()
                CouldNotRepairFiles = @()
                RawOutput           = ""
                ErrorOutput         = $_.Exception.Message
                ScanDuration        = $null
            }
        }
    }

    # Parse SFC output
    hidden [PSCustomObject] ParseSfcOutput([string]$Output) {
        $result = [PSCustomObject]@{
            Success             = $false
            ExitCode            = $null
            ErrorMessage        = $null
            IntegrityViolations = $false
            CorruptedFiles      = @()
            RepairedFiles       = @()
            CouldNotRepairFiles = @()
            RawOutput           = $Output
            ErrorOutput         = ""
            ScanDuration        = $null
        }

        if ([string]::IsNullOrWhiteSpace($Output)) {
            $result.ErrorMessage = "No output received from SFC"
            return $result
        }

        # Parse scan duration
        $durationMatch = [regex]::Match($Output, 'Duration:\s*([^\r\n]+)')
        if ($durationMatch.Success) {
            $result.ScanDuration = $durationMatch.Groups[1].Value.Trim()
        }

        # Check for integrity violations
        if ($Output -match "Windows Resource Protection did not find any integrity violations") {
            $result.Success = $true
            $result.IntegrityViolations = $false
            return $result
        }

        if ($Output -match "Windows Resource Protection found corrupt files") {
            $result.IntegrityViolations = $true
        }

        # Parse corrupted files
        $corruptPattern = '\[l\s*=\s*\d+\s*\]\s*([^\[]+?)\s*\[l\s*=\s*\d+\s*\]'
        $corruptMatches = [regex]::Matches($Output, $corruptPattern)
        foreach ($match in $corruptMatches) {
            $filePath = $match.Groups[1].Value.Trim()
            if ($filePath -and $result.CorruptedFiles -notcontains $filePath) {
                $result.CorruptedFiles += $filePath
            }
        }

        # Alternative pattern for corrupted files
        if ($result.CorruptedFiles.Count -eq 0) {
            $altPattern = 'Cannot repair member file \[l.*?\]\s*"([^"]+)"'
            $altMatches = [regex]::Matches($Output, $altPattern)
            foreach ($match in $altMatches) {
                $filePath = $match.Groups[1].Value.Trim()
                if ($filePath) {
                    $result.CorruptedFiles += $filePath
                }
            }
        }

        # Check for successful repairs
        if ($Output -match "Windows Resource Protection found corrupt files and successfully repaired them") {
            $result.Success = $true
        }
        elseif ($Output -match "Windows Resource Protection found corrupt files but was unable to fix some of them") {
            $result.Success = $false
            $result.ErrorMessage = "Some corrupt files could not be repaired"
        }
        elseif ($Output -match "Windows Resource Protection could not perform the requested operation") {
            $result.Success = $false
            $result.ErrorMessage = "SFC could not perform the operation. Try running PowerShell as Administrator"
        }

        # Parse repaired files
        $repairedPattern = 'Repaired file\s*"([^"]+)"'
        $repairedMatches = [regex]::Matches($Output, $repairedPattern)
        foreach ($match in $repairedMatches) {
            $result.RepairedFiles += $match.Groups[1].Value
        }

        # Parse files that could not be repaired
        $failedPattern = 'Cannot repair member file.*?"([^"]+)"'
        $failedMatches = [regex]::Matches($Output, $failedPattern)
        foreach ($match in $failedMatches) {
            $result.CouldNotRepairFiles += $match.Groups[1].Value
        }

        # Determine final success based on exit code
        if ($this.LastExitCode -eq 0) {
            $result.Success = $true
        }
        elseif ($this.LastExitCode -eq 1) {
            $result.Success = $false
            if ([string]::IsNullOrEmpty($result.ErrorMessage)) {
                $result.ErrorMessage = "SFC operation completed with warnings or errors"
            }
        }

         return $result
    }

    # Log output to file
    hidden [void] LogOutput([string]$Output, [string]$ErrorOutput) {
        try {
            $logEntry = @"
===========================================
SFC Scan Log - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Exit Code: $($this.LastExitCode)
===========================================
STDOUT:
$Output
STDERR:
$ErrorOutput
===========================================

"@
            Add-Content -Path $this.LogPath -Value $logEntry -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Failed to write to log file: $($_.Exception.Message)"
        }
    }

    # Get summary of last scan
    [string] GetSummary() {
        if ($this.LastScanTime -eq $null) {
            return "No scan has been performed yet."
        }

        $summary = @"
SFC Scan Summary
================
Scan Time: $($this.LastScanTime)
Exit Code: $($this.LastExitCode)
Log File: $($this.LogPath)

"@

        # If we have parsed output from last scan, show details
        if ($this.LastOutput) {
            $parsed = $this.ParseSfcOutput($this.LastOutput)

            $summary += @"
Integrity Violations: $(if($parsed.IntegrityViolations){"Yes"}else{"No"})
Corrupted Files Found: $($parsed.CorruptedFiles.Count)
Files Repaired: $($parsed.RepairedFiles.Count)
Files Not Repaired: $($parsed.CouldNotRepairFiles.Count)

"@

            if ($parsed.CorruptedFiles.Count -gt 0) {
                $summary += "Corrupted Files:`n"
                $parsed.CorruptedFiles | ForEach-Object { $summary += "  - $_`n" }
            }

            if ($parsed.RepairedFiles.Count -gt 0) {
                $summary += "`nRepaired Files:`n"
                $parsed.RepairedFiles | ForEach-Object { $summary += "  - $_`n" }
            }

            if ($parsed.CouldNotRepairFiles.Count -gt 0) {
                $summary += "`nFiles That Could Not Be Repaired:`n"
                $parsed.CouldNotRepairFiles | ForEach-Object { $summary += "  - $_`n" }
            }
        }

        return $summary
    }

    # Export results to CSV
    [void] ExportToCsv([string]$CsvPath) {
        if ($this.LastOutput) {
            $parsed = $this.ParseSfcOutput($this.LastOutput)

            $exportData = [PSCustomObject]@{
                ScanTime            = $this.LastScanTime
                ExitCode            = $this.LastExitCode
                Success             = $parsed.Success
                IntegrityViolations = $parsed.IntegrityViolations
                CorruptedFilesCount = $parsed.CorruptedFiles.Count
                RepairedFilesCount  = $parsed.RepairedFiles.Count
                CouldNotRepairCount = $parsed.CouldNotRepairFiles.Count
                CorruptedFiles      = ($parsed.CorruptedFiles -join "; ")
                RepairedFiles       = ($parsed.RepairedFiles -join "; ")
                CouldNotRepairFiles = ($parsed.CouldNotRepairFiles -join "; ")
                ScanDuration        = $parsed.ScanDuration
                ErrorMessage        = $parsed.ErrorMessage
            }

            $exportData | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Results exported to: $CsvPath" -ForegroundColor Green
        }
        else {
            Write-Warning "No scan data available to export"
        }
    }
}

function New-SfcScannerObject {
    $obj = [SfcScanner]::new()
    return $obj
}

function Show-SfcScannerDemo {
    Write-Host "SFC Scanner Class Demo" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan

    # Create scanner instance
    $scanner = [SfcScanner]::new()

    # Run a verification only scan (no repairs)
    Write-Host "`n1. Running verification scan..." -ForegroundColor Yellow
    $result = $scanner.ScanOnly()

    # Display results
    Write-Host "`n2. Scan Results:" -ForegroundColor Yellow
    Write-Host "  Success: $($result.Success)"
    Write-Host "  Exit Code: $($result.ExitCode)"
    Write-Host "  Integrity Violations: $($result.IntegrityViolations)"
    Write-Host "  Corrupted Files Found: $($result.CorruptedFiles.Count)"
    Write-Host "  Scan Duration: $($result.ScanDuration)"

    if ($result.CorruptedFiles.Count -gt 0) {
        Write-Host "  Corrupted Files:" -ForegroundColor Red
        $result.CorruptedFiles | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    }

    # Get summary
    Write-Host "`n3. Scan Summary:" -ForegroundColor Yellow
    Write-Host ($scanner.GetSummary())

    # Export results
    $csvPath = "$env:TEMP\sfc_scan_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $scanner.ExportToCsv($csvPath)

    # Run repair scan (uncomment if needed - requires admin privileges)
    <#
    Write-Host "`n4. Running repair scan..." -ForegroundColor Yellow
    $repairResult = $scanner.ScanAndRepair()
    Write-Host "Repair Results:"
    Write-Host "  Repaired Files: $($repairResult.RepairedFiles.Count)"
    Write-Host "  Could Not Repair: $($repairResult.CouldNotRepairFiles.Count)"
    #>
}
