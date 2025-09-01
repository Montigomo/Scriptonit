Set-StrictMode -Version 3.0

# .SYNOPSIS
#     Run msi package
# .PARAMETER MsiPackagePath
#     [string] path to msi package
# .PARAMETER PackageOptions
#     [string] specific msi package options
# .PARAMETER IsWait
#     [switch] wait untill msi executed
# .NOTES
#     Author : Agitech  Version : 0.0.0.1
# https://learn.microsoft.com/en-us/windows/win32/msi/command-line-options
function Install-MsiPackage {
    param
    (
        [Parameter(Mandatory = $true)]  [string]$MsiPackagePath,
        [Parameter(Mandatory = $false)] [string]$PackageOptions = "",
        [Parameter(Mandatory = $false)] [switch]$IsWait
    )

    #region msi variant 1
    # $msiPath = $tmp.FullName
    # $logFile = '{0}-{1}.log' -f $msiPath, (get-date -Format yyyyMMddTHHmmss)
    # $packageOptions = "ADDLOCAL=ALL"
    # $arguments = "/i {0} {1} /quiet /norestart /L*v {2}" -f $msiPath, $packageOptions, $logFile
    # Start-Process "msiexec.exe" -ArgumentList $arguments -NoNewWindow -Wait:$IsWait
    #endregion

    $msiPath = $MsiPackagePath
    $logFile = '{0}-{1}.log' -f $msiPath, (get-date -Format yyyyMMddTHHmmss)
    $packageOptions = $PackageOptions
    $arguments = "/i {0} {1} /quiet /norestart /L*v {2}" -f $msiPath, $packageOptions, $logFile
    Start-Process "msiexec.exe" -ArgumentList $arguments -NoNewWindow -Wait:$IsWait
}