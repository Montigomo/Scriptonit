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

    function Prepare {
        #[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor  [Net.SecurityProtocolType]::Tls12
        if (-not ($np = Get-PackageProvider | Where-Object { $_.Name -ieq "nuget" }) -or ($np.Version -lt "2.0.0")) {
            $PackageProvider = 'NuGet'
            $nugetPackage = Get-PackageProvider -ListAvailable | Where-Object { $_.Name -ieq $PackageProvider }
            if (-not $nugetPackage) {
                Install-PackageProvider -Name $PackageProvider -Confirm:$false -Force | Out-Null
            }
        }
        $RepositorySource = 'PSGallery'
        if (($psr = Get-PSRepository -Name $RepositorySource) -and ($psr.InstallationPolicy -eq "Untrusted")) {
            Set-PSRepository -Name $RepositorySource -InstallationPolicy Trusted
        }
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

    if ((-not (Get-Module $ModuleName))) {
        if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
            if (Find-Module -Name $ModuleName) {
                Install-Module -Name $ModuleName -Force -Verbose
            }
            else {
                Write-Host "Can't find reqired module $ModuleName" -ForegroundColor DarkYellow
                return
            }
        }
    }
    Import-Module -Name $ModuleName
    Write-Output "$ModuleName founded."
}