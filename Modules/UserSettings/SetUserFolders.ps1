Set-StrictMode -Version 3.0

#. "$PSScriptRoot\Modules\LoadModule.ps1" -ModuleNames @("UserFolders") | Out-Null

function SetUserFolders {
    param (
        [Parameter(Mandatory = $true)][hashtable]$Folders
    )

    # help
    # https://stackoverflow.com/questions/25049875/getting-any-special-folder-path-in-powershell-using-folder-guid/25094236#25094236
    # https://renenyffenegger.ch/notes/Windows/dirs/_known-folders
  
    Write-Host "[SetUserFolders] started ..." -ForegroundColor DarkYellow

    #$userName = [Environment]::UserName

    if (-not ([System.Management.Automation.PSTypeName]'KnownFolder').Type) {
        Write-Host "Type [KnownFolder] doesn't exsist." -ForegroundColor Red
        return
    }

    $KnownFolders = @{
        "Documents" = @{
            FolderName  = "Personal"
            GUID        = [KnownFolder]::Documents
            ComfortName = "Documents"
        };
        "Pictures"  = @{
            FolderName  = "My Pictures"
            GUID        = [KnownFolder]::Pictures
            ComfortName = "Pictures"
        };
        "Desktop"   = @{
            FolderName  = "Desktop"
            GUID        = [KnownFolder]::Desktop
            ComfortName = "Desktop"
        };
        "Video"     = @{
            FolderName  = "My Video"
            GUID        = [KnownFolder]::Videos
            ComfortName = "Videos"
        };
        "Music"     = @{
            FolderName  = "My Music"
            GUID        = [KnownFolder]::Music
            ComfortName = "Music"
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
    
    foreach ($key in $Folders.Keys) {
        if ($KnownFolders.ContainsKey($key)) {

            $item = $KnownFolders[$key]
            $FolderName = $item.FolderName
            $GUID = $item.GUID
            $Destination = $Folders[$key]
            $ComfortName = $item.ComfortName

            $Destination = MakeSubstitutions -SubsString $Destination

            $Location = [KnownFolder]::GetKnownFolderPath($GUID)

            Write-Host "User Forder " -NoNewline -ForegroundColor DarkYellow
            Write-Host """$ComfortName"" " -NoNewline -ForegroundColor DarkGreen
            Write-Host "preparing. Location - " -NoNewline -ForegroundColor DarkYellow
            Write-Host "$Location. " -NoNewline -ForegroundColor DarkGreen 
            Write-Host "Destination - " -NoNewline -ForegroundColor DarkYellow
            Write-Host "$Destination. "  -NoNewline -ForegroundColor DarkGreen
            if ($Destination -ine $Location) {
                Write-Host "Location changes to " -NoNewline -ForegroundColor DarkYellow
                Write-Host "$Destination." -ForegroundColor DarkGreen
                New-Item -ItemType Directory -Force -Path $Destination -ErrorAction SilentlyContinue | Out-Null
                #$Error.ForEach('ToString')
                if(-not (Test-Path $Destination)){
                    Write-Host "Path $Destination doesn't exisit." -ForegroundColor Red
                    #Write-Host "$Destination." -ForegroundColor DarkGreen
                    continue
                }
                [KnownFolder]::SetKnownFolderPath($GUID, $Destination) | Out-Null
                $Location = [KnownFolder]::GetKnownFolderPath($GUID)
                if ($Location -ieq $Destination) {
                    Write-Host "Folder $FolderName location changed to " -NoNewline -ForegroundColor DarkYellow
                    Write-Host "$Destination." -ForegroundColor DarkGreen
                }
                else {
                    Write-Host "Can't change folder $FolderName location to $Destination" -ForegroundColor Red
                }

            }
            else {
                Write-Host "Location does not need to change." -ForegroundColor DarkYellow
            }
        }
        else {
            Write-Host "[SetUserFolders] UserFoder $key unsupported." -ForegroundColor DarkYellow
        }
    }

}