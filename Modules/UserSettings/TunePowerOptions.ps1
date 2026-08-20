Set-StrictMode -Version 3.0
# HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Power\User\PowerSchemes

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "Run as administrator to change power plans."
    return
}

$knownPlans = @{
    'Ultimate Performance' = @{
        TemplateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
        Aliases      = @(
            'Ultimate Performance',        # EN
            'Höchstleistung',              # DE
            'Максимальная производительность' # RU
        )
    }
    'High performance'     = @{
        TemplateGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
        Aliases      = @(
            'High performance',            # EN
            'Höchstleistung',              # DE
            'Высокая производительность'   # RU
        )
    }
    'Balanced'             = @{
        TemplateGuid = '381b4222-f694-41f0-9685-ff5bb260df2e'
        Aliases      = @(
            'Balanced',                    # EN
            'Ausbalanciert',               # DE
            'Сбалансированная'             # RU
        )
    }
    'Power saver'          = @{
        TemplateGuid = 'a1841308-3541-4fab-bc81-f71556f20b4a'
        Aliases      = @(
            'Power saver',                 # EN
            'Energiesparmodus',            # DE
            'Экономия энергии'             # RU
        )
    }
}


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

function GetPowerPlans {

    $output = powercfg /list 2>&1 | Out-String -Stream
    $PowerLines = $output | Where-Object { $_ -match "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" }

    $PowerPlans = foreach ($Line in $PowerLines) {
        $CleanLine = $Line.Trim()
        $IsActive = $CleanLine -match "\*$"
        if ($CleanLine -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
            $GUID = $Matches[1]
            if ($CleanLine -match "\(([^)]+)\)") {
                $PlanName = $Matches[1].Trim()
            }
            else {
                $PlanName = ($CleanLine -replace ".*$GUID\s*", "").Trim()
                $PlanName = $PlanName -replace "\s*\*$", ""
                $PlanName = $PlanName -replace "^[()]", ""
            }

            [PSCustomObject]@{
                IsActive = $IsActive
                Guid     = $GUID
                Name     = $PlanName
            }
        }
    }

    if ($PowerPlans.Count -eq 0) {
        Write-Host "No power plans found." -ForegroundColor Red
    }

    return $PowerPlans
}

function Set-PowerPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PlanName
    )

    if (-not $knownPlans.ContainsKey($PlanName)) {
        Write-Error "Unknown plan '$PlanName'. Available: $($knownPlans.Keys -join ', ')"
        return
    }

    $plan = $knownPlans[$PlanName]
    $templateGuid = $plan.TemplateGuid
    $aliases = $plan.Aliases

    $schemes = GetPowerPlans

    $target = $null

    $target = $schemes | Where-Object { $_.Guid -eq $templateGuid } | Select-Object -First 1
    if ($target) {
        Write-Verbose "Scheme found by GUID: $($target.Guid) ($($target.Name))"
    }

    # if (-not $target) {
    #     $target = $schemes | Where-Object {
    #         $name = $_.Name
    #         $aliases | Where-Object { $_ -eq $name }
    #     } | Select-Object -First 1

    #     if ($target) {
    #         Write-Verbose "Scheme found by name: '$($target.Name)' (GUID: $($target.Guid))"
    #     }
    # }


    if (-not $target) {
        $target = $schemes | Where-Object { $aliases -contains $_.Name } | Select-Object -First 1
        if ($target) {
            Write-Verbose "Scheme found by name: '$($target.Name)' (GUID: $($target.Guid))"
        }
    }

    if (-not $target) {
        Write-Verbose "Scheme not found. Creating from template $templateGuid..."

        $output = powercfg -duplicatescheme $templateGuid 2>&1
        $m = [regex]::Match($output, '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}')

        if (-not $m.Success) {
            Write-Error "Failed to create scheme '$PlanName'. Possibly the template is missing from the system.`n$output"
            return
        }

        $target = [PSCustomObject]@{
            Guid     = $m.Value.tolower()
            Name     = $PlanName
            IsActive = $false
        }
        Write-Verbose "Scheme created: $($target.Guid)"
    }

    if ($target.IsActive) {
        Write-Host "Scheme '$PlanName' already active (GUID: $($target.Guid))."
        return
    }

    powercfg /setactive $target.Guid
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Scheme '$PlanName' activated (GUID: $($target.Guid))."
    }
    else {
        Write-Error "Failed to activate scheme (GUID: $($target.Guid))."
    }
}


function TunePowerOptions {
    DisableSleep
    SetMonitorTimeout

    # 1. Capture the previous settings
    $prevOutputEncoding = $OutputEncoding
    $prevDefaultEncoding = $PSDefaultParameterValues['*:Encoding']
    $prevCodePage = [Console]::OutputEncoding

    # 2. Set to UTF-8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    $PSDefaultParameterValues['*:Encoding'] = 'utf8'


    Set-PowerPlan -PlanName 'Ultimate Performance' -Verbose


    # 3. Restore previous settings
    [Console]::OutputEncoding = $prevCodePage
    $OutputEncoding = $prevOutputEncoding
    $PSDefaultParameterValues['*:Encoding'] = $prevDefaultEncoding
}