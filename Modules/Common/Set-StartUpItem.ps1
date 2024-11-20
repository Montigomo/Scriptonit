Set-StrictMode -Version 3.0

# .SYNOPSIS
#     add task to taskmanager for run an item on startup
# .PARAMETER Name
#     [Parameter(Mandatory = $true)] [string] log info string
# .PARAMETER Path
#     [Parameter(Mandatory = $true)] [string] write or not a calling function to log string
# .PARAMETER Argument
#     [Parameter(Mandatory = $false)] [string] write or not a calling function to log string        
# .NOTES
#     Author : Agitech
#     Version : 0.0.0.1
#     Purpose : Get world better        
function Set-StartUpItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $false)] [string] $Argument

    )
   
    $taskNamePattern = "AtStartup"
    $taskPath = "T1000"
    $taskName = "${taskNamePattern}_{0}" -f $Name

    $existTask = Get-ScheduledTask -TaskPath "\$taskPath\" -ErrorAction SilentlyContinue

    foreach ($task in $existTask) {
        if ($task.Actions -and $task.Actions[0].Execute -eq $Path) {
            Write-Output "Task with action $Path already exist."
            Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
            #return;
        }
    }

    $Trigers = New-ScheduledTaskTrigger -AtLogon
    $Principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-544" -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet
    $Action = if ($Argument) { New-ScheduledTaskAction -Execute $Path -Argument $Argument } else { New-ScheduledTaskAction -Execute $Path } 

    $Task = New-ScheduledTask -Action $Action -Principal $Principal -Trigger $Trigers -Settings $Settings


    $existTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    Write-Output "Trying to register task $Name ..."
    Register-ScheduledTask -TaskPath $taskPath -InputObject $Task -TaskName $taskName | Out-Null
    Write-Output "Task $Name registered successefully."

}