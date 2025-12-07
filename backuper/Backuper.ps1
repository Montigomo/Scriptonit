#--Requires -Version 6.0
#--Requires -PSEdition Core
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Work')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Work')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListServers')]
    [string]$NetworkName,
    [Parameter(Mandatory = $false, ParameterSetName = 'ListServers')]
    [switch]$ListServers
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network") -Force | Out-Null


#region CheckRemoteFileExists

function CheckRemoteFileExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$HostIp,
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    #$sshCommand = "ssh -o BatchMode=yes -o ConnectTimeout=5 $UserName@$HostIp 'test -e `"$FilePath`" && echo exists || echo notexists'"

    $sshCommand = "ssh -o BatchMode=yes -o ConnectTimeout=5 $UserName@$HostIp 'if ls $FilePath 1> /dev/null 2>&1; then echo exists; else echo notexist; fi'"

    $result = Invoke-Expression -Command $sshCommand 2>$null

    if ($result -eq "exists") {
        return $true
    }
    else {
        return $false
    }
}

#endregion

#region ListUsers BackuperListServers
function BackuperListServers {
    param (
        [Parameter(Mandatory = $true)]
        [string]$NetworkName
    )
    LmListObjects -ConfigPath "networks", "$NetworkName", "backuper", "*" -PropertyName "servername"

}
#endregion

function BackuperMakeBackup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$NetworkName,
        [Parameter(Mandatory = $false)]
        [string]$ServerName        
    )
   
    $_objects = LmGetObjects "networks", "$NetworkName", "backuper", "*"

    if ($_objects -and $ServerName) {
        $_objects = $_objects | Where-Object { $_.servername -eq $ServerName }
    }

    if (-not $_objects) {
        Write-Host "Not any objects to process." -ForegroundColor DarkYellow
        return
    }

    foreach ($_object in $_objects) {
        $_servername = $_object["servername"]
        $_hostIp = $_object["ip"]
        $_userName = $_object["username"]
        $_outputFolder = $_object["output_folder"]
        $_outputFolder = MakeSubstitutions -SubsString $_outputFolder
        Write-Host "Starting backup. " -ForegroundColor DarkBlue -NoNewline
        Write-Host "ServerName: " -ForegroundColor DarkGreen -NoNewline
        Write-Host "$_servername, " -ForegroundColor DarkYellow -NoNewline
        Write-Host "IP: " -ForegroundColor DarkGreen -NoNewline
        Write-Host "$_hostIp, " -ForegroundColor DarkYellow -NoNewline
        Write-Host "UserName: " -ForegroundColor DarkGreen -NoNewline
        Write-Host "$_userName, " -ForegroundColor DarkYellow -NoNewline
        Write-Host "OutputFolder: " -ForegroundColor DarkGreen -NoNewline
        Write-Host "$_outputFolder, " -ForegroundColor DarkYellow

        $result = Test-RemotePort -IPAddress $_hostIp -Port 22 -TimeoutMilliSec 3000

        if ($result.Response) {
            $_files = $_object["files"]
            foreach ($_file in $_files) {
                if ($_file.StartsWith("###")) {
                    continue
                }
                if (-not (CheckRemoteFileExists -HostIp $_hostIp -UserName $_userName -FilePath $_file)) {
                    #Write-Host "Remote file $_file does not exist on $_hostIp. Skipping backup." -ForegroundColor DarkYellow
                    continue
                }
                #$host_str = "$_userName@$($_hostIp)"
                $source_str = "$_userName@$($_hostIp):$_file"
                $dest_str = Join-Path "$_outputFolder" $_file
                $dest_str = [System.IO.Path]::GetDirectoryName($dest_str)
                New-Item -ItemType Directory -Force -Path $dest_str -ErrorAction SilentlyContinue | Out-Null
                scp -rp "$source_str" "$dest_str"
            }
        }
        else {
            Write-Host "Can't connect to $key." -ForegroundColor DarkYellow
        }
    }

}

if ($PSBoundParameters.Count -gt 0) {
    $params = $PSBoundParameters
    switch ($PSCmdlet.ParameterSetName) {
        'Work' {
            BackuperMakeBackup @params
            break
        }
        'ListServers' {
            BackuperListServers
            break
        }
    }
}