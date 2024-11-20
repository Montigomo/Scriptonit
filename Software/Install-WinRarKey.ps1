

#Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | % { Get-ItemProperty $_.PsPath } | Select DisplayName,InstallLocation | Sort-Object Displayname -Descending
$rarItem = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -like "WinRAR*" }

$license = @"
RAR registration data
EthanHunt
Single PC usage license
UID=3657406bf803634ece85
6412212250ce85a2caeca375c16325bb25829f078a5f2872e3ae03
c70b4efbec5ea7e3fe686035c6ab9048e2c5c62f0238f183d28519
aa87488bf38f5b634cf28190bdf438ac593b1857cdb55a7fcb0eb0
c3e4c2736090b3dfa45384e08e9de05c58607bab5efd52e03d2049
5ec158cd4b546bf9f93b36149ddd0a3ab2ffb00add9cdd1574a486
6dcbd8f6ea9d01f780e9d68be269d338990e58ab9587ec3460d2ad
983bb11c050a24c6ed255f2d9e935aeec33221526cee1997469833
"@

if (!$rarItem) {
    Write-Output "WinRar not installed on this machine."
    exit
}

$destinationPath = $rarItem.InstallLocation


if (!(Test-Path -Path $destinationPath)) {
    Write-Output "Destination path ${$destinationPath} don't exest."
    exit
}

$lisenseFilePath = "$destinationPath\rarreg.key"

Set-Content -Value $license -Path $lisenseFilePath -Force