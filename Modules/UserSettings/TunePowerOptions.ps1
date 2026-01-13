Set-StrictMode -Version 3.0
# HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Power\User\PowerSchemes

#region PredefinedPowerPlans
$_predefinedPowerPlans = @(
    @{
        guid  = "e9a42b02-d5df-448d-aa00-03f14749eb61"
        names = @{
            'en-US' = "Ultimate Performance"
            'ru-RU' = "Максимальная производительность"
        }
    },
    @{
        guid  = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        names = @{
            'en-US' = "High performance"
            'ru-RU' = "Максимальная производительность"
        }
    },
    @{
        guid  = "381b4222-f694-41f0-9685-ff5bb260df2e"
        names = @{
            'en-US' = "Balanced"
            'ru-RU' = "Сбалансированная"
        }
    },
    @{
        guid  = "a1841308-3541-4fab-bc81-f71556f20b4a"
        names = @{
            'en-US' = "Power saver"
            'ru-RU' = "Экономия энергии"
        }
    }
)

#endregion

#region functions

function DisableSleep {
    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0
    powercfg /h off
}

function SetMonitorTimeout {
    powercfg /change monitor-timeout-ac 10
    powercfg /change monitor-timeout-dc 10
}

function GetPowerInfo {
    $_powerPlan = powercfg /getactivescheme
    Write-Host "$_powerPlan" -ForegroundColor DarkBlue
    Write-Host "Display timeout - $(GetDisplayOffTimeout)" -ForegroundColor DarkYellow
    Write-Host "Sleep timeout - $(GetSleepTimeout)" -ForegroundColor DarkYellow
}

function GetDisplayOffTimeout {
    $_time = ((powercfg -query @(
                (powercfg -getactivescheme) -replace '^.+ \b([0-9a-f]+-[^ ]+).+', '$1'
                '7516b95f-f776-4464-8c53-06167f40cc99'
                '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e'
            ))[-3] -replace '^.+: ') / 60
    return $_time
}

function GetSleepTimeout {
    $_time = ((powercfg -query @(
                (powercfg -getactivescheme) -replace '^.+ \b([0-9a-f]+-[^ ]+).+', '$1'
                '238c9fa8-0aad-41ed-83f4-97be242c8f20'
                '29f6c1db-86da-48c5-9fdb-f2b67b1f44da'
            ))[-3] -replace '^.+: ') / 60
    return $_time
}

function GetPowerPlanGuid {
    param (
        [Parameter(Position = 0)]
        [string]$PowerPlanString
    )
    $planGuid = $null
    if (-not [string]::IsNullOrWhiteSpace($PowerPlanString)) {
        $planGuid = ($PowerPlanString -split ' ')[3].Trim('():')
    }
    return $planGuid
}

function TryGetExistPowerPlanString {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$PowerPlanName
    )
    $_powerPlanString = $null
    $_ui = (Get-UICulture).Name
    $_powerPlanObject = $_predefinedPowerPlans | Where-Object { $_.names['en-US'] -eq $PowerPlanName }
    if ($null -ne $_powerPlanObject) {
        if ($_powerPlanObject.names.ContainsKey($_ui)) {
            $_powerPlanNameUI = $_powerPlanObject.names[$_ui]
            $_powerPlanString = powercfg /l | Select-String $_powerPlanNameUI
        }
    }
    return $_powerPlanString
}
#endregion

#region SetPowerPlan
function SetPowerPlan {
    param (
        [Parameter()]
        [ValidateSet("Ultimate Performance", "High performance", "Balanced", "Power saver")]
        [string]$PowerPlanName,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $_desiredPowerPlanObject = $_predefinedPowerPlans | Where-Object { $_.names["en-US"] -eq $PowerPlanName }
    if ($null -eq $_desiredPowerPlanObject) {
        return
    }

    $_existPowerPlanGuid = GetPowerPlanGuid(powercfg /l | Select-String $_desiredPowerPlanObject.guid)

    if ($null -eq $_existPowerPlanGuid) {
        if ($Force) {
            # try find powerplan considerate ui lang
            $_powerPlanString = TryGetExistPowerPlanString -PowerPlanName $PowerPlanName
            # if powerplan don't found try to duplicate
            if ([string]::IsNullOrWhiteSpace($_powerPlanString)) {
                $_desiredPowerPlanGuid = $_desiredPowerPlanObject.guid
                powercfg -duplicatescheme $_desiredPowerPlanGuid | Out-Null
                $_powerPlanString = TryGetExistPowerPlanString -PowerPlanName $PowerPlanName
            }
            # after create try getting desired powerplan again
            if([string]::IsNullOrWhiteSpace($_powerPlanString)){
                $_powerPlanString = TryGetExistPowerPlanString -PowerPlanName $PowerPlanName
            }
            # if after all tries there is no desired powerpal exit with message
            if([string]::IsNullOrWhiteSpace($_powerPlanString)){
                Write-Host "Tring create $PowerPlanName power scheme was not succesefull." -ForegroundColor Red
                return
            }
            # if found desired powerplan set if active
            $_powerPlanGuid = GetPowerPlanGuid($_powerPlanString)
            $_powerPlanActiveGuid = GetPowerPlanGuid(powercfg /getactivescheme)
            if ($_powerPlanGuid -ne $_powerPlanActiveGuid) {
                powercfg /setactive $_powerPlanGuid
            }

        }

    }
}

#endregion
function TunePowerOptions {

    Write-Host "PowerInfo before:" -ForegroundColor DarkGreen
    GetPowerInfo
    SetPowerPlan -PowerPlanName "Ultimate Performance" -Force
    DisableSleep
    SetMonitorTimeout
    Write-Host "PowerInfo after:" -ForegroundColor DarkGreen
    GetPowerInfo
}

#TunePowerOptions