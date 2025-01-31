#Requires -Version 6.0
#Requires -PSEdition Core
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Include')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string]$NetworkName,
    [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
    [string[]]$IncludeNames,
    [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
    [string[]]$ExcludeNames
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network") | Out-Null

function InstallMSUpdatesStub {

    Import-Module "PSWindowsUpdate"

    #$scriptBlock = "&{ Get-WindowsUpdate -Criteria 'isinstalled=0 and deploymentaction=*' -Install -Download  -AutoReboot -AcceptAll } 2>&1 > 'C:\Windows\PSWindowsUpdate.log'"
    
    $scriptBlock = "&{ Get-WindowsUpdate -Install -Download  -AutoReboot -AcceptAll } 2>&1 > 'C:\Windows\PSWindowsUpdate.log'"
    
    Get-WindowsUpdate -Criteria "isinstalled=0 and deploymentaction=*" -AcceptAll | Format-Table -Property Status, Size, KB, Title
    
    Invoke-WUJob -Script $scriptBlock -RunNow -Confirm:$false -Verbose

}

function InstallMSUpdates {
    [CmdletBinding(DefaultParameterSetName = 'Include')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Include')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Exclude')]
        [string]$NetworkName,
        [Parameter(Mandatory = $false, ParameterSetName = 'Include')]
        [string[]]$IncludeNames,
        [Parameter(Mandatory = $false, ParameterSetName = 'Exclude')]
        [string[]]$ExcludeNames
    )

    Write-Host "*** Updatting $NetworkName network." -ForegroundColor DarkGreen

    $objects = LmGetObjects -ConfigName "Networks.$NetworkName.Hosts"

    if(-not $objects){
        return
    }

    $objects = $objects.GetEnumerator()

    switch ($PSCmdlet.ParameterSetName) {
        'Include' {
            if ($IncludeNames) {
                $objects = $objects | Where-Object { $IncludeNames -icontains $_.Key}
            }
            break
        }
        'Exclude' {
            if ($ExcludeNames) {
                $objects = $objects | Where-Object { $ExcludeNames -inotcontains $_.Key }
            }
            break
        }
    }

    foreach ($object in $objects) {
        $_hostName = $object.Key
        $_ipAddress = $object.Value["ip"]
        $_userName = $object.Value["username"]
        $_prepare = $object.Value["WUFlag"]

        if (-not $_prepare) {
            continue
        }

        Write-Host "** Trying to connect to $_hostName..." -ForegroundColor DarkYellow
        $result = Test-RemotePort -IPAddress $_ipAddress -Port 22 -TimeoutMilliSec 3000
        if ($result.Response) {
            Write-Host "$_hostName is online." -ForegroundColor DarkGreen -NoNewline
            Write-Host " Attempting to create ssh session." -ForegroundColor Blue
            $Session = New-PSSession -HostName $_ipAddress -UserName $_userName -ConnectingTimeout 30000 -ErrorAction SilentlyContinue
            if ($Session) {
                Write-Host "Ssh session created successfully. " -ForegroundColor DarkGreen  -NoNewline
                Write-Host "$_hostName will be updated." -ForegroundColor Blue
                $sb = [ScriptBlock]::Create("powershell.exe -ExecutionPolicy Bypass -Command { function Get-ModuleAdvanced { ${function:Get-ModuleAdvanced} } ; Get-ModuleAdvanced -ModuleName PSWindowsUpdate}")
                Invoke-Command  -Session $Session  -ScriptBlock $sb
                Invoke-Command  -Session $Session  -ScriptBlock ${Function:InstallMSUpdatesStub}
                Remove-PSSession $Session
            }
            else {
                Write-Host "Can't establish ssh session to host: $_hostName ." -ForegroundColor Red
            }
        }
        else {
            Write-Host "$_hostName is offline" -ForegroundColor DarkRed
        }
    }
}

if ($PSBoundParameters.Count -gt 0) {
    #$params = LmGetParams -InvocationParams $MyInvocation.MyCommand.Parameters -PSBoundParams $PSBoundParameters
    $params = $PSCmdlet.MyInvocation.BoundParameters
    InstallMSUpdates @params
}