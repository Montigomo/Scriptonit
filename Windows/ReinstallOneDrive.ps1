# OneDrive Complete Reinstall Script
# Run this script as Administrator

Write-Host "=== OneDrive Clean Reinstall Script ===" -ForegroundColor Cyan

# 1. Stop OneDrive processes
Write-Host "Stopping OneDrive processes..." -ForegroundColor Yellow
taskkill.exe /F /IM "OneDrive.exe" 2>$null
taskkill.exe /F /IM "explorer.exe" 2>$null

# 2. Uninstall OneDrive
Write-Host "Uninstalling OneDrive..." -ForegroundColor Yellow
if (Test-Path "$env:systemroot\System32\OneDriveSetup.exe") {
    & "$env:systemroot\System32\OneDriveSetup.exe" /uninstall
}
if (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
    & "$env:systemroot\SysWOW64\OneDriveSetup.exe" /uninstall
}

# 3. Remove OneDrive folders and leftovers
Write-Host "Removing OneDrive leftovers..." -ForegroundColor Yellow
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:programdata\Microsoft OneDrive"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "C:\OneDriveTemp"
Remove-Item -Force -ErrorAction SilentlyContinue "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"

# 4. Remove OneDrive from registry
Write-Host "Cleaning registry entries..." -ForegroundColor Yellow
# Remove from Explorer sidebar
New-PSDrive -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -Name "HKCR" -ErrorAction SilentlyContinue
$regPath = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path $regPath) {
    Set-ItemProperty -Path $regPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Force
}
$regPathWow = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path $regPathWow) {
    Set-ItemProperty -Path $regPathWow -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Force
}
Remove-PSDrive "HKCR" -ErrorAction SilentlyContinue

# Remove scheduled tasks
Write-Host "Removing scheduled tasks..." -ForegroundColor Yellow
Get-ScheduledTask -TaskName "*OneDrive*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

# 5. Wait and restart explorer
Write-Host "Restarting Windows Explorer..." -ForegroundColor Yellow
Start-Process "explorer.exe"

Write-Host "Waiting 5 seconds before installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 6. Download and install latest OneDrive
Write-Host "Downloading latest OneDrive installer..." -ForegroundColor Yellow
$onedriveUrl = "https://go.microsoft.com/fwlink/p/?LinkId=248256"
$installerPath = "$env:TEMP\OneDriveSetup.exe"

Invoke-WebRequest -Uri $onedriveUrl -OutFile $installerPath

Write-Host "Installing OneDrive..." -ForegroundColor Green
Start-Process -FilePath $installerPath -Wait

Write-Host "=== OneDrive reinstallation complete! ===" -ForegroundColor Green
Write-Host "OneDrive should start automatically. If not, launch it from Start Menu." -ForegroundColor Cyan