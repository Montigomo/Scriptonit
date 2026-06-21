
function Download-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [int]$TimeoutSeconds = 300,
        [hashtable]$Headers = @{},
        [switch]$SkipCertificateCheck,
        [switch]$UseBasicParsing
    )

    # Create output directory if it doesn't exist
    $outputDir = Split-Path -Path $OutputPath -Parent
    if ($outputDir -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Configure Invoke-WebRequest parameters
    $iwrParams = @{
        Uri         = $Url
        OutFile     = $OutputPath
        TimeoutSec  = $TimeoutSeconds
        ErrorAction = 'Stop'
    }

    # Add headers if provided
    if ($Headers.Count -gt 0) {
        $iwrParams['Headers'] = $Headers
    }

    # Use basic parsing for better performance and compatibility
    if ($UseBasicParsing -or $PSVersionTable.PSVersion.Major -lt 6) {
        $iwrParams['UseBasicParsing'] = $true
    }

    # Skip certificate validation if requested (use with caution)
    if ($SkipCertificateCheck) {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $iwrParams['SkipCertificateCheck'] = $true
        }
        else {
            # For PowerShell 5.1 and below
            add-type @"
                    using System.Net;
                    using System.Security.Cryptography.X509Certificates;
                    public class TrustAllCertsPolicy : ICertificatePolicy {
                        public bool CheckValidationResult(
                            ServicePoint srvPoint, X509Certificate certificate,
                            WebRequest request, int certificateProblem) {
                            return true;
                        }
                    }
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
    }

    # Download the file
    Write-Host "Downloading from: $Url" -ForegroundColor Cyan
    Write-Host "Saving to: $OutputPath" -ForegroundColor Cyan

    $response = Invoke-WebRequest @iwrParams

    # Verify download was successful
    # if (Test-Path -Path $OutputPath) {
    #     $fileInfo = Get-Item -Path $OutputPath
    #     Write-Host "Download complete! Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Green
    #     return $true
    # }
    # else {
    #     throw "File was not created at output path"
    # }

}


# Usage examples:

# # Basic download
# Download-File -Url "https://example.com/file.zip" -OutputPath "C:\Downloads\file.zip"

# # Download with custom headers
# $headers = @{
#     'User-Agent' = 'MyScript/1.0'
#     'Accept' = 'application/octet-stream'
# }
# Download-File -Url "https://api.example.com/download" -OutputPath "data.bin" -Headers $headers -TimeoutSeconds 60

# # Download skipping certificate check (for testing only!)
# Download-File -Url "https://self-signed.badssl.com/file" -OutputPath "file.txt" -SkipCertificateCheck

# # Fast download with basic parsing (no DOM parsing overhead)
# Download-File -Url "https://example.com/largefile.iso" -OutputPath "largefile.iso" -UseBasicParsing