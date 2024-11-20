Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\..\LoadModule.ps1" -ModuleNames @("Network") -Verbose -Force | Out-Null

Add-Host -HostIp 127.0.0.1 -HostName "iws.corel.com"

#New-NetFirewallRule -DisplayName "Allow Deluge" -Direction Inbound -Program "C:\Program Files (x86)\Deluge\deluge.exe" -Action allow
#%ProgramFiles%\Corel\CorelDRAW Graphics Suite 2022\Programs64\CorelDRW.exe
New-NetFirewallRule -Program "C:\Program Files\Corel\CorelDRAW Graphics Suite 2022\Programs64\CorelDRW.exe" -Action Block -Profile Any -DisplayName “Block CorelDRW” -Description “Block CorelDRW” -Direction Outbound

# ccleaner app
Add-Host -HostIp 127.0.0.1 -HostName "license-api.ccleaner.com"