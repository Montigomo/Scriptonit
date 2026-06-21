<#
.SYNOPSIS
    Configures Windows 11 to require password or PIN authentication after system idle.
    User Authentication after Idle Detection (UAID) script for enhanced security.
.DESCRIPTION
    This script sets up:
    1. Screen saver with "On resume, display logon screen"
    2. Dynamic lock timeout settings
    3. Optionally monitors idle time and forces lock
.NOTES
    Requires Administrator privileges for most settings.
    Author: PowerShell Assistant
#>
[CmdletBinding(DefaultParameterSetName = 'Set')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = "Set")]
    [int]$Minutes,

    [Parameter(Mandatory = $false, ParameterSetName = "Unset")]
    [switch]$Unset
)

#$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
$IsAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

if (-not $IsAdmin) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

$enableScreenSaver = $false

$enableDynamicLock = $false

$requirePasswordOnWake = $true

$idleTimeoutMinutes = $Minutes

$idleTimeoutSeconds = $idleTimeoutMinutes * 60

function SetScreenSaverPolicy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Set")]
        [int]$Seconds,

        [Parameter(Mandatory = $true, ParameterSetName = "Unset")]
        [switch]$Unset
    )

    $regPaths = @{
        CurrentUser = "HKCU:\Control Panel\Desktop"
        System      = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    }

    if ($PSCmdlet.ParameterSetName -eq "Set") {
        if ($enableScreenSaver) {
            # Set screen saver timeout
            Set-ItemProperty -Path $regPaths.CurrentUser -Name "ScreenSaveTimeOut" -Value $Seconds -Type String -Force
            Set-ItemProperty -Path $regPaths.CurrentUser -Name "ScreenSaveActive" -Value "1" -Type String -Force
            # Force screen saver to show lock screen
            Set-ItemProperty -Path $regPaths.CurrentUser -Name "ScreenSaverIsSecure" -Value "1" -Type String -Force
            # Use default screensaver (blank screen)
            Set-ItemProperty -Path $regPaths.CurrentUser -Name "SCRNSAVE.EXE" -Value "%SystemRoot%\System32\scrnsave.scr" -Type String -Force
        }
        # Require password/PIN on resume from screen saver
        Set-ItemProperty -Path $regPaths.System -Name "InactivityTimeoutSecs" -Value $Seconds -Type DWord -Force
    }
    else {
        Set-ItemProperty -Path $regPaths.CurrentUser -Name "ScreenSaveActive" -Value "0" -Type String -Force
    }

}

function SetGroupPolicySettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Set")]
        [int]$Seconds,
        [Parameter(Mandatory = $true, ParameterSetName = "Unset")]
        [switch]$Unset
    )

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $name = "InactivityTimeoutSecs"

    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    if ($PSCmdlet.ParameterSetName -eq "Set") {
        Set-ItemProperty -Path $path -Name $Name -Value $Seconds -Type DWord

    }
    else {
        if (Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue) {
            #Set-ItemProperty -Path $path -Name $name -Value 0 -Type DWord
            Remove-ItemProperty -Path $path -Name $name
        }
    }

    if (Get-ItemProperty -Path $path -Name "dontdisplaylastusername" -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $path -Name "dontdisplaylastusername"
    }

    #Set-ItemProperty -Path $path -Name "dontdisplaylastusername" -Value 1 -Type DWord -Force
    #Set-ItemProperty -Path $path -Name "dontdisplaylastusername" -Value 0 -Type DWord -Force
}

function SetPowerSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Unset = $false
    )
    if (-not $Unset) {
        if ($requirePasswordOnWake) {
            $powerScheme = powercfg /getactivescheme | Select-String -Pattern "GUID" | ForEach-Object { ($_ -split " ")[3] }
            if ($powerScheme) {
                # Require password on wake (Console lock display off timeout)
                powercfg /setacvalueindex $powerScheme SUB_VIDEO VIDEOCONLOCK 0
                powercfg /setdcvalueindex $powerScheme SUB_VIDEO VIDEOCONLOCK 0
            }
        }
    }
    else {

    }

}

function SetDynamicLock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Unset = $false
    )

    $dynamicLockPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Dynamic Lock"

    if (-not $Unset) {
        if ($enableDynamicLock) {
            if (-not (Test-Path $dynamicLockPath)) {
                New-Item -Path $dynamicLockPath -Force | Out-Null
            }
            Set-ItemProperty -Path $dynamicLockPath -Name "DynamicLock" -Value 1 -Type DWord -Force
        }
    }
    else {
        if (Test-Path $dynamicLockPath) {
            Remove-ItemProperty -Path $dynamicLockPath -Name "DynamicLock" -ErrorAction SilentlyContinue
        }
        Write-Host "Dynamic Lock settings reverted." -ForegroundColor Yellow
    }
}

function ShowCurrentStatus {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "CURRENT CONFIGURATION STATUS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # Check current settings
    $screenSaverActive = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveActive" -ErrorAction SilentlyContinue).ScreenSaveActive
    $screenSaverTimeout = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveTimeOut" -ErrorAction SilentlyContinue).ScreenSaveTimeOut
    $secure = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaverIsSecure" -ErrorAction SilentlyContinue).ScreenSaverIsSecure
    $inactivity = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "InactivityTimeoutSecs" -ErrorAction SilentlyContinue).InactivityTimeoutSecs

    if ($screenSaverActive -ne "0") {
        Write-Host "Screen Saver Active, timeout: $([math]::Round($screenSaverTimeout/60)) minutes" -ForegroundColor White
    }
    else {
        Write-Host "Screen Saver inactive." -ForegroundColor White
    }

    Write-Host "Screen Saver Secure: $($secure -eq 1)" -ForegroundColor White
    Write-Host "Machine Inactivity Limit: $([math]::Round($inactivity/60)) minutes" -ForegroundColor White
    Write-Host "Require Sign-in After Idle: $($inactivity -gt 0)" -ForegroundColor White
}

function SetUAID {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Set")]
        [int]$Seconds,

        [Parameter(Mandatory = $true, ParameterSetName = "Unset")]
        [switch]$Unset
    )

    $_params = $PSBoundParameters

    SetScreenSaverPolicy @_params
    SetGroupPolicySettings @_params
    $_params.Remove("Seconds") | Out-Null
    SetPowerSettings @_params
    SetDynamicLock @_params
    Start-Process -FilePath "rundll32.exe" -ArgumentList "user32.dll,UpdatePerUserSystemParameters" -NoNewWindow -Wait
    Write-Host "Settings reverted. Restart your computer." -ForegroundColor Yellow
}

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSBoundParameters
    switch ($PSCmdlet.ParameterSetName) {
        'Set' {
            $params.Remove('Minutes') | Out-Null
            $params.Add('Seconds', $idleTimeoutSeconds) | Out-Null
            break
        }
        'Unset' {
            $params.Remove('Seconds') | Out-Null
            break
        }
    }
    SetUAID @params
    ShowCurrentStatus
}
else {
    ShowCurrentStatus
}