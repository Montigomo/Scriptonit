Set-StrictMode -Version 3.0


# .SYNOPSIS
#   sshd library
# .DESCRIPTION
# .PARAMETER IsWait
# .PARAMETER UsePreview
# .NOTES
#   Author: Agitech; Version: 00.00.05

#region SshLibrary

#region Data

$stringJson = @"
{
  "AuthorizedKeysFile": {
    "order": "00",
    "type": "leaf",
    "value": ".ssh/authorized_keys"},
  "PasswordAuthentication": {
    "order": "00",
    "type": "leaf",
    "value": "no"},
  "PubkeyAuthentication": {
    "order": "00",
    "type": "leaf",
    "value": "yes"},
  "StrictModes": {
    "order": "00",
    "type": "leaf",
    "value": "no"},
  "Subsystem powershell": {
    "order": "00",
    "type": "leaf",
    "value": "pwsh.exe -sshs -NoLogo -NoProfile"},
  "Subsystem sftp": {
    "order": "00",
    "type": "leaf",
    "value": "sftp-server.exe"}
}
"@

#endregion

#region DoActionServices ConvertPSObjectToHashtable SortHashtableSshd SortHashtable JsonStringToHashtable

function DoActionServices {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Services,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Restart', 'Stop', 'Start')]
        [string]$Action
    )

    foreach ($serviceName in $Services) {
        switch ($Action) {
            'Restart' {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    $service | Restart-Service
                }
                break
            }
            'Stop' {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    $service | Stop-Service -ErrorAction SilentlyContinue
                }
                break
            }
            'Start' {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    $service | Set-Service -StartupType 'Automatic' | Start-Service
                }
            }
        }
    }
}

function ConvertPSObjectToHashtable ([object]$InputObject) {
    if ($null -eq $InputObject) {
        return $null
    }
    if ($InputObject -is [Hashtable] -or $InputObject.GetType().Name -eq 'OrderedDictionary') {
        return $InputObject
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $collection = @(
            foreach ($object in $InputObject) { ConvertPSObjectToHashtable($object) }
        )
        return $collection
    }
    elseif ($InputObject -is [psobject]) {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $_ht = ConvertPSObjectToHashtable($property.Value)
            if ($_ht -is [hashtable]) {
                #$_ht = SortHashtableSshd -InputHashtable $_ht
            }
            $hash[$property.Name] = $_ht
        }
        return $hash
    }
    else {
        return $InputObject
    }
}

function SortHashtableSshd {
    param (
        [Parameter()][hashtable]$InputHashtable
    )
    $_shash = [System.Collections.Specialized.OrderedDictionary]@{}
    $_obj = @($InputHashtable.GetEnumerator() |  Sort-Object {
            #Write-Host "$_.Key  $_.Value.gettype()"
            if (($_.Value -is [hashtable]) -and $_.Value.ContainsKey("order")) {
                $_.Value.order
            }
            elseif (($_.Value -is [System.Collections.Specialized.OrderedDictionary]) -and $_.Value.Keys.Contains("order")) {
                $_.Value.order
            }
            else {
                "00"
            } , $_.Key
        })

    for ($i = 0; $i -lt $_obj.length; $i++) {
        $key = ($_obj[$i]).Key
        $value = ($_obj[$i]).Value
        if ($value -is [hashtable]) {
            $value = SortHashtableSshd -InputHashtable $value
        }
        $_shash[$key] = $value
    }

    return $_shash
}

function SortHashtable {
    param (
        [Parameter()][hashtable]$InputHashtable
    )
    $_shash = [System.Collections.Specialized.OrderedDictionary]@{}

    foreach ($key in $InputHashtable.Keys | Sort-Object) {
        $_object = $InputHashtable[$key]
        if ($_object -is [hashtable]) {
            $_object = SortHashtable -InputHashtable $_object
        }
        $_shash[$key] = $_object
    }
    return $_shash
}

function JsonStringToHashtable {
    param (
        [Parameter()][string]$JsonString
    )
    $hashtable = [hashtable]::new()
    $jsonObject = ConvertFrom-Json $JsonString
    $hashtable = ConvertPSObjectToHashtable -InputObject $jsonObject
    return $hashtable
}

#endregion

#region SshlibTuneServices SshlibRemoveOldCapabilities SshlibSetDefaultShell

function Sshlib_TuneServices {
    #setup service startup type and start it
    $services = @("sshd", "ssh-agent")
    foreach ($serviceName in $services) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $service | Set-Service -StartupType 'Automatic'
            Start-Service -Name $serviceName
        }
    }
    # if (Get-Service  ssh-agent -ErrorAction SilentlyContinue) {
    #     if ((get-service sshd).StartType -ne [System.ServiceProcess.ServiceStartMode]::Manual) {
    #         Get-Service -Name ssh-agent | Set-Service -StartupType 'Automatic'
    #     }
    #     Start-Service ssh-agent
    # }
}

function Sshlib_RemoveOldCapabilities {
    # remove old capabilities
    $windowsCapabilities = @("OpenSSH.Server*", "OpenSSH.Client*")
    foreach ($item  in $windowsCapabilities) {
        $caps = Get-WindowsCapability -Online | Where-Object Name -like $item
        foreach ($cap in $caps) {
            if ($cap.State -eq "Installed") {
                Remove-WindowsCapability -Online  -Name  $cap.Name
            }
        }
    }
}

function Sshlib_SetDefaultShell {

    $_pathes = @(
        "C:\Program Files\PowerShell\7\pwsh.exe"
        "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    )

    if (!(Test-Path "HKLM:\SOFTWARE\OpenSSH")) {
        New-Item 'HKLM:\Software\OpenSSH' -Force
    }

    if (Test-Path $_pathes[0] -PathType Leaf) {
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -Value $_pathes[0] -PropertyType String -Force | Out-Null
    }
    elseif (Test-Path $_pathes[1] -PathType Leaf) {
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -Value $_pathes[1] -PropertyType String -Force | Out-Null
    }
    else {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell"
    }
}


function Sshlib_SetPubKeys {
    param(
        [Parameter(Mandatory = $true)]
        [System.Array]$PublicKeys
    )

    $_userProfileFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "..\..\"))
    #$_userProfileFolder = ""$env:USERPROFILE"
    $_userProfileSshFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($_userProfileFolder, ".ssh"))

    $sshAuKeyPathItems = @{
        #[System.IO.Path]::GetFullPath((Join-Path "$PSScriptRoot" "..\.ssh"))
        local = "$_userProfileSshFolder\authorized_keys"
        #globalAdmin = "$env:ProgramData\ssh\administrators_authorized_keys"
    }

    foreach ($key in $sshAuKeyPathItems.Keys) {
        $item = $sshAuKeyPathItems[$key]
        if (-not (Test-Path $item)) {
            new-item -Path $item  -itemtype File -Force
        }
        if ($sshPublicKeys -is [System.Array]) {
            foreach ($key in $PublicKeys) {
                If (!(Select-String -Path $item -pattern $key -SimpleMatch)) {
                    Add-Content $item $key
                }
            }
        }
    }
}

function Sshlib_ConfigFirewall {
    $ruleName = "OpenSSH-Server-In-TCP"

    $rule = Get-NetFirewallRule -Name "$ruleName" -ErrorAction SilentlyContinue

    $portFilter = $rule | Get-NetFirewallPortFilter

    if ($rule) {
        if (($rule.Enabled -ne "True") -or ($rule.Direction -ne "Inbound") -or ($portFilter.Protocol -ne "TCP") -or ($portFilter.LocalPort -ne 22)) {
            Remove-NetFirewallRule -Name "$ruleName" | Out-Null
        }
    }

    if (-not (Get-NetFirewallRule -Name "$ruleName" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name "$ruleName" -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    }

}

#endregion

#region HashToSshdConfig ConvertJsonToSshdConfig ConvertSshdConfigToJson

function Sshlib_HashToSshdConfig {
    param (
        [Parameter()][hashtable]$InputHashtable,
        [Parameter()][string]$Indent = ""
    )
    $hash = SortHashtableSshd -InputHashtable $InputHashtable
    $outputString = ""
    foreach ($key in $hash.Keys) {
        $value = $hash.$key.value
        if (($value -is [hashtable]) -or ($value -is [System.Collections.Specialized.OrderedDictionary])) {
            $outputString = $outputString + "$key$([System.Environment]::NewLine)"
            $value = Sshlib_HashToSshdConfig -InputHashtable $value -Indent "  "
            $outputString = $outputString + "$value$([System.Environment]::NewLine)"
        }
        else {
            $outputString = $outputString + "$Indent$key $value$([System.Environment]::NewLine)"
        }
    }
    $outputString = $outputString.TrimEnd([System.Environment]::NewLine)
    return $outputString
}

function Sshlib_ConvertJsonToSshdConfig {
    param (
        [Parameter()][string]$JsonString
    )
    $hash = JsonStringToHashtable $JsonString
    #$hash = SortHashtableSshd -InputHashtable $hash
    $outputString = Sshlib_HashToSshdConfig -InputHashtable $hash
    return $outputString
}

function ConvertSshdConfigToJson {
    param (
        [Parameter()][string]$FilePath
    )
    $items = Get-Content -Path $FilePath
    $_hash = [hashtable]::new()
    $currentNode = $_hash
    #$parsing_error = $false
    foreach ($item in $items) {
        if (-not ($item -match "^\s*#")) {
            $re = "^\s*(?<param>\S+)\s+(?<value>[^\n]*)"
            if ($item -match $re) {
                $param = $Matches["param"]
                $value = $Matches["value"]

                switch ($param) {
                    "subsystem" {
                        $ress = "^(?<value01>\S+)\s+(?<value02>[^\n]+)"
                        if ($value -match $ress) {
                            $value01 = $Matches["value01"]
                            $value02 = $Matches["value02"]
                            #Write-Host "value01: $value01; value02: $value02"
                            $param = "$param $value01"
                            $value = $value02
                        }
                        else {
                            throw "ssh config parsing error"
                        }
                        $_htv = @{
                            "value" = $value
                            "order" = "00"
                            "type"  = "leaf"
                        }
                        $currentNode.Add($param, $_htv)
                        break;
                    }
                    "match" {
                        $currentNode = $_hash
                        $ress = "^(?<value01>\S+)\s+(?<value02>[^\n]+)"
                        if ($value -match $ress) {
                            $value01 = $Matches["value01"]
                            $value02 = $Matches["value02"]
                            #Write-Host "value01: $value01; value02: $value02"
                            $param = "$param $value01 $value02"
                            $value = ""
                            $_htv = @{
                                "value" = $value
                                "order" = "90"
                                "type"  = "branch"
                            }
                            $currentNode.Add($param, $_htv)
                            $currentNode[$param]["value"] = [hashtable]::new()
                            $currentNode = $currentNode[$param]["value"]
                        }
                        else {
                            throw "ssh config parsing error"
                        }
                        break;
                    }
                    default {
                        $_htv = @{
                            "value" = $value
                            "order" = "00"
                            "type"  = "leaf"
                        }
                        $currentNode.Add($param, $_htv)
                        break;
                    }
                }

            }
        }
    }
    $_hash = SortHashtableSshd -InputHashtable $_hash
    return ($_hash | ConvertTo-Json -Depth 10)
}

#endregion

#region CompareSshdConfig WriteSshdConfig CheckSshdConfig

function Sshlib_CompareSshdConfig {
    param (
        [Parameter()][string]$FilePath,
        [Parameter()][string]$JsonString
    )

    $result = $false

    $_fileJson = ConvertSshdConfigToJson -FilePath $FilePath

    $hash = JsonStringToHashtable -JsonString $JsonString
    $hash = SortHashtableSshd -InputHashtable $hash
    $_stringJson = $hash | ConvertTo-Json -Depth 10

    # method 1
    # $json01 = $hash | ConvertTo-Json -Depth 10 -Compress
    # $json02 = ($_stringJson | ConvertFrom-Json | ConvertTo-Json -Depth 10 -Compress)
    # $result = ($json01 -ieq $json02)

    # method 2
    $obj01 = ($_fileJson -split '\r?\n')
    $obj02 = ($_stringJson -split '\r?\n')
    $result = Compare-Object $obj01 $obj02
    $result = -not $result

    return $result
}

function Sshlib_WriteSshdConfig {
    param (
        [Parameter()][string]$FilePath,
        [Parameter()][string]$JsonString
    )
    $string = Sshlib_ConvertJsonToSshdConfig -JsonString $JsonString
    $string | Out-File -FilePath $FilePath  -Encoding utf8
}

function Sshlib_CheckSshdConfig {
    param (
        [Parameter()][string]$SshdConfigPath,
        [Parameter()][string]$OutFile,
        [Parameter()][string]$JsonString
    )

    $result = Sshlib_CompareSshdConfig -FilePath $SshdConfigPath -JsonString $JsonString

    if (-not $result) {
        Sshlib_WriteSshdConfig -FilePath $OutFile -JsonString $JsonString
        Sshlib_RestartSshdServices
        return $false
    }
    return $true
}

#endregion

#region CheckSshdService CheckSshd RestartSshdServices

function Sshlib_CheckSshdService {

    $result = $true

    for ($i = 0; $i -lt 5; $i++) {
        if ((Get-Service sshd).Status -ine "running") {
            $result = $false
            break
        }
        Start-Sleep -Milliseconds 250
    }
    return $result
}

function Sshlib_CheckSshd {
    param (
        [Parameter()][string]$SshdConfigPath,
        [Parameter()][string]$JsonString
    )
    if (-not (Sshlib_CheckSshdService)) {
        Sshlib_WriteSshdConfig -FilePath $SshdConfigPath -JsonString $JsonString
        Sshlib_RestartSshdServices
        return $false
    }
    return $true
}

function Sshlib_RestartSshdServices {
    $services = @("sshd", "ssh-agent")
    DoActionServices -Services $services -Action Restart
}

#endregion

#endregion