Set-StrictMode -Version 3.0

function IsPwshInstalled {
    $pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (-not (Test-Path $pwshPath)) {
        if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions\31ab5147-9a97-4452-8443-d9709f0516e1") {
            $pwshPath = "{0}pwsh.exe" -f (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions\31ab5147-9a97-4452-8443-d9709f0516e1\" -Name "InstallLocation").InstallLocation
        }
    }
    return (Test-Path $pwshPath)
}