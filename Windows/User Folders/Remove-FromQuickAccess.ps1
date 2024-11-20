# shell:::([guid]])
# list of guids and objects
# 679f85cb-0220-4080-b29b-5540cc05aab6 - windows 10+ qiuck access folder

function Remove-FromQuickAccess {
    param (
        [Parameter(Mandatory = $false)][string[]]$Names,
        [Parameter()][switch]$Except
    )
    
    #$ObjShell | Get-Member
    #$ObjShell.ToggleDesktop()

    $ObjShell = New-Object -ComObject "Shell.Application"
    $items = $ObjShell.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items()


    foreach ($item in $items) {
        Write-Host "Preparing $($item.Name) from Quick access" -ForegroundColor DarkYellow
        if (-not($Except -xor ($item.Name -in $Names))) {
            continue
        }
        if ($item.IsFolder -ne $true) {
            continue
        }
        if (($null -ne $($item.Verbs() | Where-Object { $_.Name -in "Remo&ve from Quick access" }))) {
            Write-Host "Removing $($item.Name) from Quick Access Folder" -ForegroundColor DarkYellow
            $item.InvokeVerb("removefromhome")
        }
        if (($null -ne $($item.Verbs() | Where-Object { $_.Name -in "Unpin from &Quick access" }))) {
            Write-Host "Unpin $($item.Name) from Quick Access Folder" -ForegroundColor DarkYellow
            $item.InvokeVerb("unpinfromhome")
        }                
    }
}

function fn001 {
    $sh = New-Object -COM WScript.Shell
    $o = New-Object -COM shell.application

    #Define user profile Links directory
    $filedirectory = "$env:USERPROFILE\Links\*.lnk"

    ForEach ($file in Get-ChildItem $filedirectory) {
        #Extract link path from link file
        $targetPath = $sh.CreateShortcut($file).TargetPath
        #If links contain paths to mapped drives, replace drive letter to UNC path. S used as example.
        If ($targetPath -like 'S:\*') {
            $newPath = $targetPath.Replace("S:\", "\\Your UNC Path")
        }
        #Pin file path to Quick Access
        $o.Namespace($newPath).Self.InvokeVerb(“pintohome”)
    }
}
function fn002 {
    #Uncheck "Show recently used files in Quick access" & Uncheck "Show frequently used folders in Quick Access" for OS account currently logged in
    $FolderOptionsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
    Set-ItemProperty -Path $FolderOptionsPath -Name ShowFrequent -Value '0'
    Set-ItemProperty -Path $FolderOptionsPath -Name ShowRecent -Value '0'
}