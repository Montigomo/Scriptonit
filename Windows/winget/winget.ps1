
# https://github.com/microsoft/winget-cli/issues/3525#issuecomment-1736846054
# Download this file: https://cdn.winget.microsoft.com/cache/source.msix (e.g. with Edge)
# Open the Downloads folder
# Right-click, choose install, follow the wizard to install the package.


# run under powershell.exe !!!
$smpath = "$env:TEMP\source.msix"
Invoke-WebRequest -Uri https://cdn.winget.microsoft.com/cache/source.msix -OutFile $smpath
Add-AppxPackage -Path $smpath 


#sfc /scannow
#dism /Online /Cleanup-Image /ScanHealth
# repair

# reset
winget source reset --force

$packages = Get-AppxPackage | Where-Object { $_.Name -ilike "*WinGet*" }
foreach($package in $packages) {
    $name = $package.PackageFullName
    Reset-AppxPackage $name
}


# install winget
# Install VCLibs
Add-AppxPackage 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
# Install Microsoft.UI.Xaml.2.7.3
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3 -OutFile .\microsoft.ui.xaml.2.7.3.zip
Expand-Archive .\microsoft.ui.xaml.2.7.3.zip
Add-AppxPackage .\microsoft.ui.xaml.2.7.3\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx
# Install Microsoft.DesktopInstaller (winget)
Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
Add-AppxPackage .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle