Set-StrictMode -Version 3.0

# .SYNOPSIS
#     Is powershell session runned in admin mode
# .DESCRIPTION
# .PARAMETER TaskData
#     [hashtable] data for task, key = value
#         "Name"   = task name
#         "Values" =  hashtable for the values to be substituted into the XmlDefinition of the task
#                     before the task is reregistered. Format [xpath to node] = [node value]. Examples:
#                     "/ns:Task/ns:Actions/ns:Exec/ns:Command"   = "D:\temp\funny.exe";
#                     "/ns:Task/ns:Actions/ns:Exec/ns:Argumetns" = "-set=12"
#                     The values for the nodes on the specified xpath will be replaced with the specified ones
#         "XmlDefinition" = xml task definition (can be obtained when exporting a task)
#                     task xml definition contains key <Version>xxx</Version> which can be used to check the task is registred in the Task Scheduller
#                     is actual, if task definition that send has a higher version number than registred in the Task Sheduller
#                     registred task will be unregistred and new will one
# .PARAMETER Principal
#     [string] one of the set values, which is used as the princiapl when registering the task (not used in the current edition)
# .PARAMETER OnlyCheck
#     [switch] Just check if task with specified name exist
# .PARAMETER Force
#     [switch] for future use
# .INPUTS
# .OUTPUTS
# .EXAMPLE
# .LINK
# .NOTES
#     Author: Agitech Version: 0.0.0.1
function Register-Task {
    param(
        [Parameter(Mandatory = $true)] [hashtable]$TaskData,
        [Parameter(Mandatory = $false)] [string[]]$ProcessNames,
        [Parameter(Mandatory = $false)] [switch]$AndExit,
        [Parameter(Mandatory = $false)] [switch]$AndRun,
        [Parameter(Mandatory = $false)] [switch]$Force
    )
    $TaskName = $TaskData["Name"];
    $xml = [xml]$TaskData["XmlDefinition"];
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace("ns", $xml.DocumentElement.NamespaceURI)
    if ($TaskData["Values"]) {
        foreach ($item in $TaskData["Values"].Keys) {
            $xmlNode = $xml.SelectSingleNode($item, $ns);
            if ($xmlNode) {
                $innerText = $TaskData["Values"][$item]
                $xmlNode.InnerText = $innerText
            }
        }
    }

    $registredTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $needRegister = (-not $registredTask) -or $Force;
    if ($registredTask -and (-not $needRegister)) {
        $registrationInfo = $xml.SelectSingleNode("/ns:Task/ns:RegistrationInfo/ns:Version", $ns);
        if ($registrationInfo) {
            $currentVersion = [System.Version]::Parse("0.0.0")
            $null = [System.Version]::TryParse($registrationInfo.InnerText, [ref]$currentVersion)
            $installedVersion = [System.Version]::Parse("0.0.0")
            $null = [System.Version]::TryParse($registredTask.Version, [ref]$installedVersion)
            $needRegister = ($currentVersion -gt $installedVersion)
        }
        $needRegister = $needRegister -or ($registredTask.State -eq "Disabled");
    }

    if ($needRegister) {
        KillProcesses -ProcessNames $ProcessNames
        if ($registredTask) {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        }
        Register-ScheduledTask -Xml $xml.OuterXml -TaskName $TaskName | Out-Null
        WriteLog "Task $TaskName successfully registered."

        if ($AndRun) {
            Start-Sleep -Seconds 3
            $registredTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            if ($registredTask -and ($registredTask.State -ne "Running")) {
                $registredTask | Start-ScheduledTask
                WriteLog "Task $TaskName started."
            }
        }
        if ($AndExit) {
            exit
        }
    }
    #return $needRegister
}