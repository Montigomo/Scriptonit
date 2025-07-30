Set-StrictMode -Version 3.0

<#
.SYNOPSIS
    A function that uses the utility regsvr32.exe utility to register a file
.PARAMETER Path
    The file path
.PARAMETER Unregister
    when specified, unregisters instead of registers
#>
function Register-Dll {
    [CmdletBinding()]
    param (
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipeLineByPropertyName = $true)]
        [Alias("FullName")]
        [string[]]$Path,
        [Alias("u")]
        [switch]$Unregister
    )
    begin {
        if ($Unregister) {
            $regflag = "-u "
        }
        else {
            $regflag = ""
        }
        [int]$NumFailed = 0
        $RegExitCodes = @{
            0 = "SUCCESS";
            1 = "FAIL_ARGS - Invalid Argument";
            2 = "FAIL_OLE - OleInitialize Failed";
            3 = "FAIL_LOAD - LoadLibrary Failed";
            4 = "FAIL_ENTRY - GetProcAddress failed";
            5 = "FAIL_REG - DllRegisterServer or DllUnregisterServer failed.";
        }
    }
    process {
        foreach ($p in $path) {
            try {
                $regsvrp = Start-Process regsvr32.exe -ArgumentList "/s $regflag ""$p""" -Wait -NoNewWindow -PassThru

                if ($regsvrp.ExitCode -ne 0) {
                    $NumFailed++
                    Write-Error "regsvr32 $regflag for $p exited with error $($regsvrp.ExitCode) - $($RegExitCodes[$regsvrp.ExitCode])"
                }else{
                    Write-Host "Successfully $($regflag -replace '-u ', 'un')registered $p" -ForegroundColor DarkGreen
                }
            }
            catch {
                $NumFailed++
                Write-Error $_.Exception.Message
            }
        }
    }
    end {
        if ($NumFailed -gt 0) {
            if ($Unregister) {
                $mode = "unregister"
            }
            else {
                $mode = "register"
            }
            Write-Error "Failed to $mode $NumFailed dll's, see previous errors for detail"
        }
    }
}