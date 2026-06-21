#Requires -Version 5.1
<#
.SYNOPSIS
    A PowerShell 5.1-compatible class wrapper around dism.exe.

.DESCRIPTION
    DismManager provides a structured, object-oriented interface to DISM operations,
    supporting both online (running OS) and offline (mounted/WIM) image targets.

    PowerShell 5.1 constraints observed:
      - No method overloads: each method has a single signature; optional parameters
        are expressed with sentinel default values ($null / $false / "").
      - No Generic.List in class scope: all collections are plain arrays (@()).
      - No ::new() shorthand for ProcessStartInfo/Process (uses New-Object instead).
      - No ternary operator (?:).

.NOTES
    Requires elevation (Run as Administrator).
    Tested against dism.exe shipping with Windows 10/11 and Windows ADK.
#>

enum DismHealthStatus {
    Healthy
    Repairable
    Error
}


class DismManager {

    #region Properties

    [string] $ImagePath
    [string] $MountDir
    [bool]   $IsOnline
    [bool]   $ThrowOnError

    #endregion

    #region Constructors

    # Default constructor — targets the currently running Windows installation (online mode).
    # For offline or mount-dir modes use the New-DismManager factory function.
    DismManager() {
        $this.IsOnline = $true
        $this.ThrowOnError = $true
        $this.ImagePath = $null
        $this.MountDir = $null
    }

    #endregion

    #region Private Helpers

    <#
    .SYNOPSIS
        Builds the dism.exe argument list for a given command.

    .PARAMETER Command
        DISM command verb, e.g. "Enable-Feature" or "cleanup-image".

    .PARAMETER Parameters
        Hashtable of key/value pairs emitted as /Key:"Value".

    .PARAMETER Flags
        Array of switch-style arguments emitted as /Flag (no value attached).

    .PARAMETER SkipTargetArg
        When $true the automatic /Online or /Image: prefix is suppressed.
        Required for standalone WIM-file operations (Mount-Image, Get-WimInfo, etc.)
        that supply their own /ImageFile: parameter.
    #>
    hidden [string[]] BuildDismArgs(
        [string]    $Command,
        [hashtable] $Parameters,
        [string[]]  $Flags,
        [bool]      $SkipTargetArg
    ) {
        $argList = @()

        if (-not $SkipTargetArg) {
            if ($this.IsOnline) {
                $argList += "/Online"
            }
            elseif ($this.MountDir -and (Test-Path -LiteralPath $this.MountDir)) {
                $argList += "/Image:`"$($this.MountDir)`""
            }
            elseif ($this.ImagePath) {
                $argList += "/Image:`"$($this.ImagePath)`""
            }
            else {
                throw "No valid image target. Set ImagePath or MountDir, or use online mode."
            }
        }

        $argList += "/$Command"

        foreach ($key in $Parameters.Keys) {
            $value = $Parameters[$key]
            if ($null -ne $value -and "$value" -ne "") {
                $argList += "/${key}:`"$value`""
            }
        }

        foreach ($flag in $Flags) {
            if ($flag -and $flag -ne "") {
                $argList += "/$flag"
            }
        }

        return $argList
    }

    hidden [DismHealthStatus] ParseHealthResult([string]$InputString) {
        $_result = [DismHealthStatus]::Healthy
        $corruptionIndicators = @(
            'хранилище компонентов подлежит восстановлению'
            'component store is repairable'
            'corruption was detected'
            'found corruption'
        )

        foreach ($indicator in $corruptionIndicators) {
            if ($InputString -like "*$indicator*") {
                $_result = [DismHealthStatus]::Repairable
                break
            }
        }
        return $_result
    }

    <#
    .SYNOPSIS
        Launches dism.exe, captures stdout/stderr, and returns a structured result object.
    #>
    hidden [pscustomobject] ExecuteDism(
        [string]    $Command,
        [hashtable] $Parameters,
        [string[]]  $Flags,
        [bool]      $SkipTargetArg
    ) {
        $dismArgs = $this.BuildDismArgs($Command, $Parameters, $Flags, $SkipTargetArg)

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "dism.exe"
        $psi.Arguments = $dismArgs -join " "
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $proc.Start() | Out-Null

        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        $result = [pscustomobject]@{
            Command      = $Command
            Arguments    = $psi.Arguments
            ExitCode     = $proc.ExitCode
            Success      = ($proc.ExitCode -eq 0)
            Output       = $stdout
            Error        = $stderr
            ParsedOutput = $this.ParseDismOutput($stdout, $Command)
            Health       = $this.ParseHealthResult($($stdout | Out-String))
        }

        if ($this.ThrowOnError -and -not $result.Success) {
            $msg = "DISM /$Command failed (exit code $($proc.ExitCode))."
            if ($stderr) { $msg += "`nStderr: $stderr" }
            throw $msg
        }

        return $result
    }

    <#
    .SYNOPSIS
        Parses dism.exe stdout into typed objects based on the command issued.
    #>
    hidden [pscustomobject] ParseDismOutput([string]$Output, [string]$Command) {
        $parsed = [pscustomobject]@{
            RawOutput = $Output
            Command   = $Command
            Success   = ($Output -match "The operation completed successfully")
            Features  = @()
            Packages  = @()
            Drivers   = @()
            ImageInfo = [ordered]@{}
            WimImages = @()
        }

        switch -Regex ($Command.ToLower()) {

            "get-features" {
                $rx = [regex]"Feature Name : (?<name>.+?)\r?\nState : (?<state>.+?)(\r?\n|$)"
                foreach ($m in $rx.Matches($Output)) {
                    $parsed.Features += [pscustomobject]@{
                        Name  = $m.Groups['name'].Value.Trim()
                        State = $m.Groups['state'].Value.Trim()
                    }
                }
            }

            "get-packages" {
                $rx = [regex]"Package Identity : (?<id>.+?)\r?\nState : (?<state>.+?)(\r?\n|$)"
                foreach ($m in $rx.Matches($Output)) {
                    $parsed.Packages += [pscustomobject]@{
                        Identity = $m.Groups['id'].Value.Trim()
                        State    = $m.Groups['state'].Value.Trim()
                    }
                }
            }

            "get-drivers" {
                $rx = [regex]"Published Name\s+: (?<pub>.+?)\r?\nOriginal File Name\s+: (?<orig>.+?)(\r?\n|$)"
                foreach ($m in $rx.Matches($Output)) {
                    $parsed.Drivers += [pscustomobject]@{
                        PublishedName    = $m.Groups['pub'].Value.Trim()
                        OriginalFileName = $m.Groups['orig'].Value.Trim()
                    }
                }
            }

            "get-imageinfo" {
                # Named captures avoid collision with PowerShell's automatic $Matches variable
                $fields = [ordered]@{
                    Version     = "Image Version\s*:\s*(?<val>.+)"
                    Index       = "Image Index\s*:\s*(?<val>\d+)"
                    Name        = "Image Name\s*:\s*(?<val>.+)"
                    Description = "Image Description\s*:\s*(?<val>.+)"
                    Size        = "Image Size\s*:\s*(?<val>[\d,]+ bytes)"
                }
                foreach ($field in $fields.GetEnumerator()) {
                    if ($Output -match $field.Value) {
                        $parsed.ImageInfo[$field.Key] = $Matches['val'].Trim()
                    }
                }
            }

            "get-wiminfo" {
                # Build the pattern as a plain string — PS5 does not support
                # the multi-line [regex](...) constructor syntax used in PS7.
                $pattern = "Index\s*:\s*(?<index>\d+)\s*\r?\nName\s*:\s*(?<name>.+?)\s*\r?\nDescription\s*:\s*(?<desc>.*?)\s*\r?\n(?:.*?\r?\n)*?Size\s*:\s*(?<size>[\d,]+ bytes)"
                $rx = New-Object System.Text.RegularExpressions.Regex(
                    $pattern,
                    [System.Text.RegularExpressions.RegexOptions]::Singleline
                )
                foreach ($m in $rx.Matches($Output)) {
                    $parsed.WimImages += [pscustomobject]@{
                        Index       = $m.Groups['index'].Value.Trim()
                        Name        = $m.Groups['name'].Value.Trim()
                        Description = $m.Groups['desc'].Value.Trim()
                        Size        = $m.Groups['size'].Value.Trim()
                    }
                }
            }
        }

        return $parsed
    }

    #endregion

    #region Feature Management

    <#
    .SYNOPSIS
        Returns all Windows optional features and their current states.
    #>
    [pscustomobject] GetFeatures() {
        return $this.ExecuteDism("Get-Features", @{}, @(), $false)
    }

    <#
    .SYNOPSIS
        Enables a Windows optional feature.

    .PARAMETER FeatureName
        The feature to enable, e.g. "NetFx3".

    .PARAMETER LimitAccess
        When $true, prevents DISM from contacting Windows Update.
        Requires Source to be set when enabling features that need files.

    .PARAMETER Source
        Path to a side-by-side store or WIM that supplies the feature files
        (e.g. "D:\sources\sxs"). Pass "" to omit.
    #>
    [pscustomobject] EnableFeature([string]$FeatureName, [bool]$LimitAccess, [string]$Source) {
        $params = @{ FeatureName = $FeatureName }
        $flags = @()

        if ($LimitAccess) { $flags += "LimitAccess" }
        if ($Source) { $params.Source = $Source }

        return $this.ExecuteDism("Enable-Feature", $params, $flags, $false)
    }

    <#
    .SYNOPSIS
        Disables a Windows optional feature.

    .PARAMETER FeatureName
        The feature to disable, e.g. "TelnetClient".
    #>
    [pscustomobject] DisableFeature([string]$FeatureName) {
        return $this.ExecuteDism("Disable-Feature", @{ FeatureName = $FeatureName }, @(), $false)
    }

    #endregion

    #region Package Management

    <#
    .SYNOPSIS
        Returns all packages currently installed in the image.
    #>
    [pscustomobject] GetPackages() {
        return $this.ExecuteDism("Get-Packages", @{}, @(), $false)
    }

    <#
    .SYNOPSIS
        Adds a .cab or .msu package to the image.

    .PARAMETER PackagePath
        Full path to the .cab or .msu file.

    .PARAMETER IgnoreCheck
        When $true, skips applicability checks. Use with caution.
    #>
    [pscustomobject] AddPackage([string]$PackagePath, [bool]$IgnoreCheck) {
        if (-not (Test-Path -LiteralPath $PackagePath)) {
            throw "Package file '$PackagePath' not found."
        }
        $params = @{ PackagePath = $PackagePath }
        $flags = @()
        if ($IgnoreCheck) { $flags += "IgnoreCheck" }
        return $this.ExecuteDism("Add-Package", $params, $flags, $false)
    }

    <#
    .SYNOPSIS
        Removes an installed package by its identity name.

    .PARAMETER PackageName
        The package identity string as shown by GetPackages().
    #>
    [pscustomobject] RemovePackage([string]$PackageName) {
        return $this.ExecuteDism("Remove-Package", @{ PackageName = $PackageName }, @(), $false)
    }

    #endregion

    #region Driver Management

    <#
    .SYNOPSIS
        Returns all third-party drivers present in the image.
    #>
    [pscustomobject] GetDrivers() {
        return $this.ExecuteDism("Get-Drivers", @{}, @(), $false)
    }

    <#
    .SYNOPSIS
        Adds a driver (.inf) or a directory of drivers to the image.

    .PARAMETER DriverPath
        Path to a .inf file or a directory containing .inf files.

    .PARAMETER Recurse
        When $true, searches DriverPath recursively for .inf files.
    #>
    [pscustomobject] AddDriver([string]$DriverPath, [bool]$Recurse) {
        if (-not (Test-Path -LiteralPath $DriverPath)) {
            throw "Driver path '$DriverPath' not found."
        }
        $params = @{ Driver = $DriverPath }
        $flags = @()
        if ($Recurse) { $flags += "Recurse" }
        return $this.ExecuteDism("Add-Driver", $params, $flags, $false)
    }

    <#
    .SYNOPSIS
        Removes a third-party driver by its published name.

    .PARAMETER PublishedName
        The OEM-assigned name shown by GetDrivers(), e.g. "oem3.inf".
    #>
    [pscustomobject] RemoveDriver([string]$PublishedName) {
        return $this.ExecuteDism("Remove-Driver", @{ Driver = $PublishedName }, @(), $false)
    }

    #endregion

    #region Image Health

    <#
    .SYNOPSIS
        Quickly checks whether the component store carries any corruption flags.
        Does not scan — reads cached state only. Fast.
    #>
    [pscustomobject] CheckHealth() {
        return $this.ExecuteDism("cleanup-image", @{}, @("CheckHealth"), $false)
    }

    <#
    .SYNOPSIS
        Scans the component store for corruption. Slower than CheckHealth.
    #>
    [pscustomobject] ScanHealth() {
        return $this.ExecuteDism("cleanup-image", @{}, @("ScanHealth"), $false)
    }

    <#
    .SYNOPSIS
        Repairs a corrupted component store.

    .PARAMETER Source
        Optional path to a known-good WIM/ESD or SxS store used as the repair
        source instead of Windows Update. Pass "" to omit.

    .PARAMETER LimitAccess
        When $true (and Source is provided), prevents DISM from contacting
        Windows Update even as a fallback.
    #>
    [pscustomobject] RestoreHealth([string]$Source, [bool]$LimitAccess) {
        $params = @{}
        $flags = @("RestoreHealth")

        if ($Source) { $params.Source = $Source }
        if ($LimitAccess) { $flags += "LimitAccess" }

        return $this.ExecuteDism("cleanup-image", $params, $flags, $false)
    }

    #endregion

    #region Image Information

    <#
    .SYNOPSIS
        Retrieves metadata for the currently targeted offline image.
        Issues a warning when called on an online instance.
    #>
    [pscustomobject] GetImageInfo() {
        if ($this.IsOnline) {
            Write-Warning "Get-ImageInfo is intended for offline images."
        }
        return $this.ExecuteDism("Get-ImageInfo", @{}, @(), $false)
    }

    <#
    .SYNOPSIS
        Lists all image indexes stored inside a WIM or ESD file.
        Does not require the image to be mounted.

    .PARAMETER WimPath
        Full path to the .wim or .esd file to inspect.
    #>
    [pscustomobject] GetWimInfo([string]$WimPath) {
        if (-not (Test-Path -LiteralPath $WimPath)) {
            throw "WIM file '$WimPath' not found."
        }
        # SkipTargetArg = $true: this command takes its own /ImageFile: and must
        # not receive the instance-level /Online or /Image: prefix.
        return $this.ExecuteDism("Get-WimInfo", @{ ImageFile = $WimPath }, @(), $true)
    }

    #endregion

    #region Mount / Dismount

    <#
    .SYNOPSIS
        Mounts a WIM or ESD image index to a local directory.

    .PARAMETER WimPath
        Path to the .wim or .esd file.

    .PARAMETER Index
        Image index within the file to mount (1-based).

    .PARAMETER MountDir
        Directory to mount into. Created automatically if absent.

    .PARAMETER ReadOnly
        When $true, mounts the image read-only. No changes can be committed.
    #>
    [pscustomobject] MountImage([string]$WimPath, [int]$Index, [string]$MountDir, [bool]$ReadOnly) {
        if (-not (Test-Path -LiteralPath $WimPath)) {
            throw "WIM file '$WimPath' not found."
        }
        if (-not (Test-Path -LiteralPath $MountDir)) {
            New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
        }

        $params = @{
            MountDir  = $MountDir
            ImageFile = $WimPath
            Index     = $Index.ToString()
        }
        $flags = @()
        if ($ReadOnly) { $flags += "ReadOnly" }

        $result = $this.ExecuteDism("Mount-Image", $params, $flags, $true)

        if ($result.Success) {
            $this.MountDir = $MountDir
            $this.IsOnline = $false
        }

        return $result
    }

    <#
    .SYNOPSIS
        Dismounts the image that was mounted by this instance.

    .PARAMETER Commit
        $true  — writes all changes back to the WIM before unmounting.
        $false — discards all changes (default, non-destructive).
    #>
    [pscustomobject] DismountImage([bool]$Commit) {
        if (-not $this.MountDir) {
            throw "No MountDir is set on this instance. Cannot dismount."
        }

        $params = @{ MountDir = $this.MountDir }
        $flags = @()
        if ($Commit) { $flags += "Commit" } else { $flags += "Discard" }

        $result = $this.ExecuteDism("Dismount-Image", $params, $flags, $true)

        if ($result.Success) {
            $this.MountDir = $null
        }

        return $result
    }

    <#
    .SYNOPSIS
        Removes all orphaned or incomplete mount points left by failed operations.
    #>
    [pscustomobject] CleanupMountPoints() {
        return $this.ExecuteDism("Cleanup-MountPoints", @{}, @(), $true)
    }

    #endregion

    #region Image Capture / Apply / Export / Split

    <#
    .SYNOPSIS
        Captures a directory tree into a new WIM file.

    .PARAMETER CaptureDir
        Root directory to capture (e.g. "C:\").

    .PARAMETER WimPath
        Destination .wim file path. File is created; use Export-Image to append.

    .PARAMETER Name
        Short name stored as image metadata inside the WIM.

    .PARAMETER Description
        Optional longer description stored inside the WIM. Pass "" to omit.
    #>
    [pscustomobject] CaptureImage([string]$CaptureDir, [string]$WimPath, [string]$Name, [string]$Description) {
        if (-not (Test-Path -LiteralPath $CaptureDir)) {
            throw "Capture directory '$CaptureDir' not found."
        }
        $params = @{
            CaptureDir = $CaptureDir
            ImageFile  = $WimPath
            Name       = $Name
        }
        if ($Description) { $params.Description = $Description }

        return $this.ExecuteDism("Capture-Image", $params, @(), $true)
    }

    <#
    .SYNOPSIS
        Applies (expands) a WIM image index to a target directory.

    .PARAMETER WimPath
        Source .wim or .esd file.

    .PARAMETER Index
        Index of the image to apply (1-based).

    .PARAMETER ApplyDir
        Destination directory (e.g. "D:\").
    #>
    [pscustomobject] ApplyImage([string]$WimPath, [int]$Index, [string]$ApplyDir) {
        if (-not (Test-Path -LiteralPath $WimPath)) {
            throw "WIM file '$WimPath' not found."
        }
        $params = @{
            ImageFile = $WimPath
            Index     = $Index.ToString()
            ApplyDir  = $ApplyDir
        }
        return $this.ExecuteDism("Apply-Image", $params, @(), $true)
    }

    <#
    .SYNOPSIS
        Exports a single image index from one WIM into another WIM.

    .PARAMETER SourceWim
        Path to the source .wim file.

    .PARAMETER SourceIndex
        Index to export from the source (1-based).

    .PARAMETER DestWim
        Path to the destination .wim file (created if absent; appended if present).

    .PARAMETER DestName
        Name to assign to the exported image inside the destination WIM.
    #>
    [pscustomobject] ExportImage([string]$SourceWim, [int]$SourceIndex, [string]$DestWim, [string]$DestName) {
        if (-not (Test-Path -LiteralPath $SourceWim)) {
            throw "Source WIM '$SourceWim' not found."
        }
        $params = @{
            SourceImageFile      = $SourceWim
            SourceIndex          = $SourceIndex.ToString()
            DestinationImageFile = $DestWim
            DestinationName      = $DestName
        }
        return $this.ExecuteDism("Export-Image", $params, @(), $true)
    }

    <#
    .SYNOPSIS
        Splits a large WIM into multiple smaller .swm files for media that
        cannot hold a single large file (e.g. FAT32 volumes).

    .PARAMETER WimPath
        Source .wim file to split.

    .PARAMETER DestDir
        Output directory. Split files are named split.swm, split2.swm, etc.

    .PARAMETER FileSizeMB
        Maximum size in megabytes for each split file.
    #>
    [pscustomobject] SplitImage([string]$WimPath, [string]$DestDir, [int]$FileSizeMB) {
        if (-not (Test-Path -LiteralPath $WimPath)) {
            throw "WIM file '$WimPath' not found."
        }
        $params = @{
            ImageFile = $WimPath
            SWMFile   = (Join-Path $DestDir "split.swm")
            FileSize  = $FileSizeMB.ToString()
        }
        return $this.ExecuteDism("Split-Image", $params, @(), $true)
    }

    #endregion
}

#region Factory Function

<#
.SYNOPSIS
    Creates a DismManager instance — the recommended way to instantiate the class.

.DESCRIPTION
    Handles all three modes in a single function:
      - No parameters        : online mode (current running OS)
      - ImagePath only       : offline image directory
      - ImagePath + MountDir : offline image with explicit mount directory

    Also exposes the ThrowOnError switch that the class constructors cannot set
    directly (PS5 constructors cannot have optional parameters).

.PARAMETER ImagePath
    Path to the offline Windows image directory or WIM file.
    Omit for online mode.

.PARAMETER MountDir
    Explicit mount directory. Only meaningful when ImagePath is also provided.

.PARAMETER ThrowOnError
    When $true (default), any non-zero DISM exit code throws a terminating error.
    Set to $false to inspect ExitCode / Success manually.

.EXAMPLE
    # Online mode
    $dism = New-DismManager
    $dism.CheckHealth() | Show-DismResult

.EXAMPLE
    # Offline image directory
    $dism = New-DismManager -ImagePath "C:\mount\windows"
    $dism.GetPackages().ParsedOutput.Packages

.EXAMPLE
    # Non-throwing mode — check results manually
    $dism = New-DismManager -ThrowOnError $false
    $result = $dism.ScanHealth()
    if (-not $result.Success) { Write-Warning "Issues found." }
#>
function New-DismManager {
    [CmdletBinding()]
    [OutputType([DismManager])]
    param(
        [Parameter(Position = 0)]
        [string] $ImagePath = "",

        [Parameter(Position = 1)]
        [string] $MountDir = "",

        [Parameter()]
        [bool] $ThrowOnError = $true
    )

    # Validate paths before handing off to the constructor
    if ($ImagePath -and -not (Test-Path -LiteralPath $ImagePath)) {
        throw "ImagePath '$ImagePath' does not exist."
    }

    $obj = New-Object DismManager

    if ($ImagePath -and $MountDir) {
        $obj.ImagePath = $ImagePath
        $obj.MountDir = $MountDir
        $obj.IsOnline = $false
    }
    elseif ($ImagePath) {
        $obj.ImagePath = $ImagePath
        $obj.IsOnline = $false
    }
    # else: leave IsOnline = $true (set by the default constructor)

    $obj.ThrowOnError = $ThrowOnError
    return $obj
}

#endregion

#region Display Helper

function GetFormatedLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputLine,
        [Parameter(Mandatory = $false)]
        [string]$FormatChar = "-",
        [Parameter(Mandatory = $false)]
        [int]$StringLength = 64,
        [Parameter(Mandatory = $false)]
        [switch]$ReplaceMultiNewLine = $false
    )
    if ([string]::IsNullOrWhiteSpace($InputLine)) {
        $_inputLine = ""
    }
    else {
        $_inputLine = " $InputLine "
    }

    $_inputLine = $_inputLine + " " * ($_inputLine.length % 2)
    $_inputLine_side = ""
    if (($StringLength - $_inputLine.Length) -ge 0) {
        $_inputLine_side = $FormatChar * (($StringLength - $_inputLine.Length) / 2)
    }
    $_result = @("$_inputLine_side$_inputLine$_inputLine_side")
    return $_result
}

<#
.SYNOPSIS
    Pretty-prints a DismManager result object to the host.

.DESCRIPTION
    Accepts pipeline input so results can be piped directly:
        $dism.CheckHealth() | Show-DismResult

.PARAMETER Result
    The [pscustomobject] returned by any DismManager method.
#>
function Show-DismResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [pscustomobject] $Result,
        [Parameter(Mandatory = $false)]
        [switch] $HideOutput
    )

    process {
        $exitColor = if ($Result.Success) { "Green" } else { "Red" }

        Write-Host $(GetFormatedLine -InputLine "DISM Result: $($Result.Command)") -ForegroundColor Cyan
        Write-Host "Arguments : $($Result.Arguments)"          -ForegroundColor DarkGray
        Write-Host "Exit Code : $($Result.ExitCode)"           -ForegroundColor $exitColor
        Write-Host "Success   : $($Result.Success)"            -ForegroundColor $exitColor

        $po = $Result.ParsedOutput

        if ($po.Features.Count -gt 0) {
            Write-Host "`nFeatures:" -ForegroundColor Green
            $po.Features | Format-Table -AutoSize
        }

        if ($po.Packages.Count -gt 0) {
            Write-Host "`nPackages:" -ForegroundColor Green
            $po.Packages | Format-Table -AutoSize
        }

        if ($po.Drivers.Count -gt 0) {
            Write-Host "`nDrivers:" -ForegroundColor Green
            $po.Drivers | Format-Table -AutoSize
        }

        if ($po.WimImages.Count -gt 0) {
            Write-Host "`nWIM Images:" -ForegroundColor Green
            $po.WimImages | Format-Table -AutoSize
        }

        if ($po.ImageInfo.Count -gt 0) {
            Write-Host "`nImage Info:" -ForegroundColor Green
            foreach ($entry in $po.ImageInfo.GetEnumerator()) {
                Write-Host "  $($entry.Key) : $($entry.Value)"
            }
        }

        if ($Result.Error) {
            Write-Host "`nStderr:" -ForegroundColor Red
            Write-Host $Result.Error
        }

        if (-not $HideOutput) {
            Write-Host "`nStdout:" -ForegroundColor Green
            Write-Host $Result.Output -ForegroundColor DarkYellow
        }

        Write-Host $(GetFormatedLine -InputLine "DISM Result end ") -ForegroundColor Cyan
    }
}

#endregion

<#
===============================================================================
USAGE EXAMPLES
===============================================================================

--- Online mode (running OS) ---

$dism = New-DismManager
$dism.CheckHealth() | Show-DismResult
$dism.ScanHealth()  | Show-DismResult

# List only enabled features
$dism.GetFeatures().ParsedOutput.Features | Where-Object { $_.State -eq "Enabled" }

# Enable .NET 3.5 from a local source, blocking Windows Update
$dism.EnableFeature("NetFx3", $true, "D:\sources\sxs") | Show-DismResult

# Repair the component store using a local WIM
$dism.RestoreHealth("D:\sources\install.wim", $true) | Show-DismResult


--- Offline image directory ---

$offline = New-DismManager -ImagePath "C:\mount\windows"
$offline.GetPackages().ParsedOutput.Packages
$offline.AddDriver("C:\Drivers", $true)   # recursive driver injection


--- Mount → modify → commit workflow ---

$wim = New-DismManager
$wim.MountImage("C:\sources\install.wim", 1, "C:\mount", $false)

$wim.EnableFeature("NetFx3", $false, "")
$wim.AddPackage("C:\Updates\KB1234567.msu", $false)

$wim.DismountImage($true)    # $true = commit; $false = discard


--- Inspect a WIM file without mounting ---

$dism    = New-DismManager
$wimInfo = $dism.GetWimInfo("C:\sources\install.wim")
$wimInfo.ParsedOutput.WimImages | Format-Table


--- Capture a custom image ---

$dism = New-DismManager
$dism.CaptureImage("C:\Sysprep", "C:\output\custom.wim", "My Image", "Post-sysprep build")


--- Non-throwing mode: inspect results manually ---

$dism = New-DismManager -ThrowOnError $false
$result = $dism.ScanHealth()
if (-not $result.Success) {
    Write-Warning "ScanHealth reported issues (exit $($result.ExitCode))."
}

===============================================================================
#>