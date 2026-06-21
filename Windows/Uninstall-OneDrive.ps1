

# 1. Terminate OneDrive process
Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue

# 2. Uninstall OneDrive Application
$OneDriveSetup = if ([Environment]::Is64BitOperatingSystem) { "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" } else { "$env:SystemRoot\System32\OneDriveSetup.exe" }
if (Test-Path $OneDriveSetup) {
    Start-Process -FilePath $OneDriveSetup -ArgumentList "/uninstall" -NoNewWindow -Wait
}

# 3. Clean up folder leftovers
$PathsToRemove = @(
    "$env:UserProfile\OneDrive",
    "$env:LocalAppData\Microsoft\OneDrive",
    "$env:ProgramData\Microsoft OneDrive",
    "$env:SystemDrive\OneDriveTemp"
)
foreach ($Path in $PathsToRemove) {
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 4. Remove OneDrive from the File Explorer sidebar (Registry cleanup)
$CLSID = "HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path $CLSID) {
    Set-ItemProperty -Path $CLSID -Name "System.IsPinnedToNameSpaceTree" -Value 0
}

# 5. Prevent OneDrive from being automatically reinstalled (Registry block)
$PolicyPath = "HKLM:\Software\Policies\Microsoft\Windows\OneDrive"
if (!(Test-Path $PolicyPath)) {
    New-Item -Path $PolicyPath -Force
}
Set-ItemProperty -Path $PolicyPath -Name "DisableFileSyncNGSC" -Value 1

Write-Host "OneDrive has been successfully removed and blocked." -ForegroundColor Green
