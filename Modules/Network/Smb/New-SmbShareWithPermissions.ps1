#Requires -RunAsAdministrator

Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\..\LoadModule.ps1" -ModuleNames @("Common") -Force | Out-Null


function New-SmbShareWithPermissions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShareName,
        [Parameter(Mandatory = $true)]
        [string]$SharePath,
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        [Parameter(Mandatory = $false)]        
        [string[]]$FullAccessUsers = @(),
        [Parameter(Mandatory = $false)]        
        [string[]]$ReadAccessUsers = @(),
        [Parameter(Mandatory = $false)]        
        [string[]]$ChangeAccessUsers = @()
    )
    
    if (-not (Test-Path $SharePath)) {
        Write-Warning "Path $SharePath does not exist. Creating directory..."
        New-Item -ItemType Directory -Path $SharePath -Force
    }
    
    try {
        if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {

            $shareParams = @{
                Name        = $ShareName
                Path        = $SharePath
                Description = $Description
            }
        
            if ($FullAccessUsers) { 
                $shareParams.FullAccess = $FullAccessUsers 
            }
            if ($ReadAccessUsers) { 
                $shareParams.ReadAccess = $ReadAccessUsers 
            }
            if ($ChangeAccessUsers) {
                $shareParams.ChangeAccess = $ChangeAccessUsers 
            }
        
            New-SmbShare @shareParams
        
            Write-Host "SMB share '$ShareName' created successfully!" -ForegroundColor Green
        }

        # check permissions
        $acim = Get-SmbShareAccess $ShareName
        $flag = $true
        foreach ($item in $acim) {
            $accounName = $item.CimInstanceProperties["AccountName"].Value
            # 
            # https://learn.microsoft.com/en-us/previous-versions/windows/desktop/smb/msft-smbshareaccesscontrolentry
            # Full (0)
            # Change (1)
            # Read (2)
            # Custom (3)
            $accessRights = $item.CimInstanceProperties["AccessRight"].Value
            foreach ($user in $FullAccessUsers) {
                if ($accounName.EndsWith($user) -and $accessRights -ne 0) {
                    Grant-SmbShareAccess -Name $RSFolderName -AccountName "RiconUser" -AccessRight Full -Force
                }
                $Acl = Get-Acl $SharePath 
                # FileSystemAccessRule(String, FileSystemRights, InheritanceFlags, PropagationFlags, AccessControlType)
                # https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemaccessrule.-ctor?view=net-9.0#system-security-accesscontrol-filesystemaccessrule-ctor(system-string-system-security-accesscontrol-filesystemrights-system-security-accesscontrol-inheritanceflags-system-security-accesscontrol-propagationflags-system-security-accesscontrol-accesscontroltype)
                #$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("$user", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
                $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("$user", [System.Security.AccessControl.FileSystemRights]::FullControl, "ContainerInherit,ObjectInherit", "None", "Allow")

                $Acl.SetAccessRule($Ar)
                Set-Acl $SharePath $Acl
            }
            foreach ($user in $ChangeAccessUsers) {
                if ($accounName.EndsWith($user) -and $accessRights -ne 1) {
                    Grant-SmbShareAccess -Name $RSFolderName -AccountName "RiconUser" -AccessRight Change -Force
                }
            }            
            foreach ($user in $ReadAccessUsers) {
                if ($accounName.EndsWith($user) -and $accessRights -ne 2) {
                    Grant-SmbShareAccess -Name $RSFolderName -AccountName "RiconUser" -AccessRight Read -Force
                }
            }
        }
        
    }
    catch {
        Write-Error "Failed to create SMB share: $($_.Exception.Message)"
    }
}