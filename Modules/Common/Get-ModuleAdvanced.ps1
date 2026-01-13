Set-StrictMode -Version 3.0

#.SYNOPSIS
#.DESCRIPTION
#.PARAMETER ModuleName
#     [string] module name to install
#.INPUTS
#.OUTPUTS
#.EXAMPLE
#.EXAMPLE
#.LINK
#.NOTES
#     Author : Agitech   Version : 0.0.0.1
function Get-ModuleAdvanced {
    param (
        [Parameter(Mandatory = $true)] [string]$ModuleName
    )

    function GMA_IsBuiltInModule {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ModuleName
        )

        $systemPaths = "$env:SystemRoot\system32\WindowsPowerShell\v1.0\Modules", "${env:SystemRoot}\System32\WindowsPowerShell\v1.0\Modules"
        if ($PSVersionTable.PSEdition -eq 'Core' -or $PSVersionTable.Version.Major -ge 6) {
            # Add PowerShell Core/7+ system path if applicable (adjust as needed for specific OS)
            $systemPaths += "${env:ProgramFiles}\PowerShell\Modules"
        }

        return ($_module = Get-Module -Name $ModuleName -ListAvailable) -and ($systemPaths | Where-Object { ForEach-Object { $_module.Path.StartsWith($_) } })
    }

    function Prepare {
        #[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        # check and install NuGet provider (what is NuGet - https://learn.microsoft.com/en-us/nuget/what-is-nuget)
        if (-not ($np = Get-PackageProvider | Where-Object { $_.Name -ieq "nuget" }) -or ($np.Version -lt "2.0.0")) {
            $PackageProvider = 'NuGet'
            $nugetPackage = Get-PackageProvider -ListAvailable | Where-Object { $_.Name -ieq $PackageProvider }
            if (-not $nugetPackage) {
                Install-PackageProvider -Name $PackageProvider -Confirm:$false -Force | Out-Null
            }
        }

        # register the PowerShell Gallery as a trusted repository
        $RepositorySource = 'PSGallery'
        if (($psr = Get-PSRepository -Name $RepositorySource) -and ($psr.InstallationPolicy -eq "Untrusted")) {
            Set-PSRepository -Name $RepositorySource -InstallationPolicy Trusted
        }

        # install PowerShellGet
        if (($pm = get-module PowerShellGet) -and ($pm.Version -lt "2.0.0")) {
            Install-Module PowerShellGet -Force -AllowClobber
        }

    }

    # $sourceArgs = @{
    #     Name         = 'nuget.org'
    #     Location     = 'https://api.nuget.org/v3/index.json'
    #     ProviderName = 'NuGet'
    # }

    Prepare

    if (-not (GMA_IsBuiltInModule -ModuleName $ModuleName)) {
        if ((-not (Get-Module $ModuleName))) {
            if ((Get-Module -ListAvailable -Name $ModuleName)) {
                $_localVersion = (Get-Module -ListAvailable -Name $ModuleName).Version
                $_findModule = (Find-Module -Name $ModuleName)
                if ($_findModule) {
                    $_remoteVersion = $_findModule.Version
                    if ($_localVersion -lt $_remoteVersion) {
                        Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
                        Uninstall-Module -Name $ModuleName -AllVersions -Force
                        Install-Module -Name $ModuleName -Force -Verbose
                    }
                    Import-Module $ModuleName
                }
            }
            else {
                if (Find-Module -Name $ModuleName) {
                    Install-Module -Name $ModuleName -Force -Verbose
                    Import-Module -Name $ModuleName
                }
                else {
                    Write-Host "Can't find reqired module $ModuleName" -ForegroundColor DarkYellow
                    return
                }
            }

        }
    }

    Write-Host "Get-ModuleAdvanced: Module $ModuleName founded." -ForegroundColor DarkGreen
}

function GMA_GetBuiltinModules {
    # Get all available modules
    $allModules = Get-Module -ListAvailable

    # Get system module paths (built-in modules are here)
    $systemPaths = "$env:SystemRoot\system32\WindowsPowerShell\v1.0\Modules", "${env:SystemRoot}\System32\WindowsPowerShell\v1.0\Modules"
    if ($PSVersionTable.PSEdition -eq 'Core' -or $PSVersionTable.Version.Major -ge 6) {
        # Add PowerShell Core/7+ system path if applicable (adjust as needed for specific OS)
        $systemPaths += "${env:ProgramFiles}\PowerShell\Modules"
    }

    # Filter for modules whose path starts with a system path
    $builtinModules = $allModules | Where-Object {
        $path = $_.Path -replace '\\\\', '\\' # Normalize path separators
        $systemPaths | ForEach-Object { $path.StartsWith($_) }
    }

    $builtinModules
}