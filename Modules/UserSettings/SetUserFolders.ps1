Set-StrictMode -Version 3.0

function SetUserFolders {

    # https://stackoverflow.com/questions/25049875/getting-any-special-folder-path-in-powershell-using-folder-guid/25094236#25094236
    # https://renenyffenegger.ch/notes/Windows/dirs/_known-folders
  
    Write-Host "[SetUserFolders] started ..." -ForegroundColor Green

    $userName = [Environment]::UserName

    $baseUserFolders = "D:\_users\{0}" -f $userName

    if (-not ([System.Management.Automation.PSTypeName]'KnownFolder').Type) {
        Write-Host -ForegroundColor DarkYellow "Type [KnownFolder] doesn't exsist."
        return
    }


    $KnownFolders = @{
        "Documents" = @{
            Handle      = $true
            FolderName  = "Personal"
            GUID        = [KnownFolder]::Documents
            ComfortName = "Documents"
            Destination = "$baseUserFolders\Documents"
        };
        "Pictures"  = @{
            Handle      = $true
            FolderName  = "My Pictures"
            GUID        = [KnownFolder]::Pictures
            ComfortName = "Pictures"
            Destination = "$baseUserFolders\Pictures"
        };
        "Desktop"   = @{
            Handle      = $false
            FolderName  = "Desktop"
            GUID        = [KnownFolder]::Desktop
            ComfortName = "Desktop"
            Destination = "$baseUserFolders\Desktop"
        };
        "Video"     = @{
            Handle      = $false
            FolderName  = "My Video"
            GUID        = [KnownFolder]::Videos
            ComfortName = "Videos"
            Destination = "$baseUserFolders\Videos"
        };
        "Music"     = @{
            Handle      = $false
            FolderName  = "My Music"
            GUID        = [KnownFolder]::Music
            ComfortName = "Music"
            Destination = "$baseUserFolders\Music"
        };
    }
    
    function UpdateUserFoldersByReg {
        [CmdletBinding()]
        param (
            [Parameter()][string]$UserProfilesFolder = $env:USERPROFILE
        )
        
        Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" `
            -Name $UserFolderName -Value $UserFolderPath -Type String -Force
        Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" `
            -Name $UserFolderClass -Value $UserFolderPath -Type ExpandString
        Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" `
            -Name $UserFolderName -Value $UserFolderPath -Type ExpandString
    }
    
    foreach ($key in $KnownFolders.Keys) {
        $item = $KnownFolders[$key]
        $handle = $item.Handle
        $FolderName = $item.FolderName
        $GUID = $item.GUID
        $ComfortName = $item.ComfortName
        $Destination = $item.Destination
        $Location = [KnownFolder]::GetKnownFolderPath($GUID)
        Write-Host "Forder " -NoNewline -ForegroundColor DarkYellow
        Write-Host "$FolderName " -NoNewline -ForegroundColor DarkGreen
        Write-Host "preparing. Location - " -NoNewline -ForegroundColor DarkYellow
        Write-Host "$Location. " -NoNewline -ForegroundColor DarkGreen 
        Write-Host "Destination - " -NoNewline -ForegroundColor DarkYellow
        Write-Host "$Destination." -ForegroundColor DarkGreen
        if ($Destination -ine $Location) {
            New-Item -ItemType Directory -Force -Path $Destination | Out-Null
            [KnownFolder]::SetKnownFolderPath($GUID, $Destination)
            $Location = [KnownFolder]::GetKnownFolderPath($GUID)
            if ($Location -ieq $Destination) {
                Write-Host "Folder $FolderName location changed to $Destination" -ForegroundColor DarkGreen
            }
            else {
                Write-Host "Can't change folder $FolderName location to $Destination" -ForegroundColor Red
            }

        }

    }

}