
<#
.SYNOPSIS
    Prevents users from moving Windows known folders to OneDrive.
.DESCRIPTION
    Enables the 'BlockKnownFolderMove' policy by setting the
    KFMBlockOptIn registry key to 1. This blocks the KFM prompt
    and disables the 'Manage backup' setting in OneDrive.
#>
function Prevent-KnownFolderMove {
    [CmdletBinding()]
    param()

    process {
        $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
        $ValueName = "KFMBlockOptIn"
        $ValueData = 1

        # Check if the registry path exists, create it if missing
        if (-not (Test-Path $RegPath)) {
            Write-Verbose "Creating missing registry path: $RegPath"
            New-Item -Path $RegPath -Force | Out-Null
        }

        # Set or overwrite the policy registry key
        Write-Host "Configuring registry to block Known Folder Move..." -ForegroundColor Cyan
        New-ItemProperty -Path $RegPath -Name $ValueName -Value $ValueData -PropertyType DWord -Force | Out-Null

        # Verify the setting was applied
        $Result = Get-ItemProperty -Path $RegPath -Name $ValueName -ErrorAction SilentlyContinue
        if ($Result.$ValueName -eq 1) {
            Write-Host "Success: Known Folder Move is now prevented." -ForegroundColor Green
        }
        else {
            Write-Warning "Failed to set the registry key. Please ensure you ran PowerShell as Administrator."
        }
    }
}


<#
.SYNOPSIS
    Permanently disables OneDrive folder syncing and storage for all users.
.DESCRIPTION
    Enforces local machine policies to stop OneDrive from hijacking user folders.
    This setting will persist across Windows Updates and keeps OneDrive installed.
#>
function Disable-OneDriveFolderTakeover {

    [CmdletBinding()]
    param()

    process {
        # Path to the Windows Component Policy for OneDrive
        $RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"

        # Check if the registry path exists; if not, create it
        if (-not (Test-Path -Path $RegistryPath)) {
            Write-Verbose "Creating missing registry path: $RegistryPath"
            New-Item -Path $RegistryPath -Force | Out-Null
        }

        Write-Host "Enforcing OneDrive block for all users..." -ForegroundColor Cyan

        # Enforce the Next Generation Sync Client (NGSC) block policy
        Set-ItemProperty -Path $RegistryPath -Name "DisableFileSyncNGSC" -Value 1 -PropertyType DWORD -Force

        # Enforce the legacy sync block policy for maximum compatibility
        Set-ItemProperty -Path $RegistryPath -Name "DisableFileSync" -Value 1 -PropertyType DWORD -Force

        # Optional: Prevents users from getting folder backup prompts on personal accounts
        Set-ItemProperty -Path $RegistryPath -Name "DisablePersonalSync" -Value 1 -PropertyType DWORD -Force

        Write-Host "Policy successfully applied! Please restart the computer to apply changes." -ForegroundColor Green
    }
}

# Execute the function
Prevent-KnownFolderMove
#Disable-OneDriveFolderTakeover
