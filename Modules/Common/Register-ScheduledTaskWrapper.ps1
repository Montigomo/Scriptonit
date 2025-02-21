Set-StrictMode -Version 3.0

# https://learn.microsoft.com/en-us/windows/win32/secauthz/well-known-sids
# https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers



. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null

# .SYNOPSIS
#     add task to taskmanager for run an item on startup
# .PARAMETER Name
#     [Parameter(Mandatory = $true)] [string] Task name
# .PARAMETER Path
#     [Parameter(Mandatory = $false)] [string] Task path
# .PARAMETER $Actions
#     [Parameter(Mandatory = $false)] [array] Task actions
# .PARAMETER $Triggers
#     [Parameter(Mandatory = $false)] [array] Task triggers
# .PARAMETER $Settings
#     [Parameter(Mandatory = $false)] [hashtable] Task settings
# .PARAMETER $Principal
#     [Parameter(Mandatory = $false)] [hashtable] Task principal
# .NOTES
#     Author : Agitech
#     Version : 0.0.0.1
function Register-ScheduledTaskWrapper {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $false)]
        [array]$Actions,
        [Parameter(Mandatory = $false)]
        [array]$Triggers,
        [Parameter(Mandatory = $false)]
        [hashtable]$Settings,
        [Parameter(Mandatory = $false)]
        [hashtable]$Principal
    )


    #region Triggers

    $TaskTrigers = @()

    foreach ($trigger in $Triggers) {
        $trigger = LmParamsRemoveComments -Params $trigger
        $TaskTrigers += New-ScheduledTaskTrigger @trigger
    }

    #endregion

    #region Settings

    $TaskSettings = New-ScheduledTaskSettingsSet

    $innerSettings = @{
        "ExecutionTimeLimit"         = "PT0S"
        "DisallowStartIfOnBatteries" = $false
        "StopIfGoingOnBatteries"     = $false
    }

    foreach ($key in $innerSettings.Keys) {
        $TaskSettings.CimInstanceProperties[$key].Value = $innerSettings[$key]
    }

    if ($Settings) {
        $Settings = LmParamsRemoveComments -Params $Settings
        foreach ($key in $Settings.Keys) {
            $TaskSettings.CimInstanceProperties[$key].Value = $Settings[$key]
        }
    }

    #endregion

    #region Actions

    $TaskActions = @()

    foreach ($action in $Actions) {
        $action = LmParamsRemoveComments -Params $action
        $TaskActions += New-ScheduledTaskAction @action
    }

    #endregion

    #region Check task exist

    #$existTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    # if ($existTask) {
    #     Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    # }

    #endregion

    #region create Principal

    Write-Host "Trying to register task $Name ..." -ForegroundColor DarkYellow

    $TaskPrincipal = @{ }

    $TaskParams = @{
        TaskPath = $Path
        TaskName = $Name
        Action  = $TaskActions
        Trigger = $TaskTrigers
        Settings = $TaskSettings
        Force    = $true
    }

    if ($Principal.ContainsKey("CurrentUser") ) {
        $username = "$($env:USERDOMAIN)\$($env:USERNAME)"
        $credentials = Get-Credential -Credential $username
        $password = $credentials.GetNetworkCredential().Password

        $TaskParams.Add("User", $username)
        $TaskParams.Add("Password", $password)

    }
    else {
        if ($Principal.ContainsKey("UserId")) {
            $TaskPrincipal = New-ScheduledTaskPrincipal -UserId "$($Principal.UserId)" -RunLevel Highest
        }
        elseif ($Principal.ContainsKey("GroupId")) {
            $TaskPrincipal = New-ScheduledTaskPrincipal -GroupId "$($Principal.$GroupId)" -RunLevel Highest
        }
        else {
            #$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            # BUILTIN\Administrators
            $TaskPrincipal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-544" -RunLevel Highest
        }

        $TaskParams.Add("Principal", $TaskPrincipal)

    }
    #endregion

    #region RegisterTask

    #Register-ScheduledTask  -TaskPath $taskPath -TaskName $taskName -Action $Action -Trigger $Trigers -Settings $TaskSettings -Principal $Principal -Force | Out-Null
    #Register-ScheduledTask -TaskPath $taskPath -InputObject $Task -TaskName $taskName | Out-Null

    Register-ScheduledTask @TaskParams | Out-Null

    Write-Host "Task $Name registered successefully." -ForegroundColor DarkYellow

    #endregion
}