### version=1.00.02

# https://winitpro.ru/index.php/2013/08/07/kak-umenshit-razmer-papki-winsxs-v-windows-8/
# https://superuser.com/questions/1611311/how-to-delete-the-folder-c-programdata-microsoft-diagnosis-etllogs-and-stop-w

function Clear-GlobalWindowsCache {
    Remove-Dir "C:\Windows\Temp"
    Remove-Dir "C:\Temp"
    Remove-Dir "C:\tmp"
    #Remove-Dir "C:\`$Recycle.Bin"
    Remove-Dir "C:\Windows\Prefetch"
    C:\Windows\System32\rundll32.exe InetCpl.cpl, ClearMyTracksByProcess 255
    C:\Windows\System32\rundll32.exe InetCpl.cpl, ClearMyTracksByProcess 4351

    # Remove printer queued files
    Stop-Service -Name "spooler"
    Remove-Dir "C:\Windows\System32\spool\PRINTERS\"
    Start-Service -Name "spooler"
}

function Clear-UserCacheFiles {
    # Stop-BrowserSessions
    ForEach ($localUser in (Get-ChildItem "C:\users").Name) {
        Clear-AcrobatCacheFiles $localUser
        Clear-AVGCacheFiles $localUser
        Clear-BattleNetCacheFiles $localUser
        Clear-ChromeCacheFiles $localUser
        Clear-DiscordCacheFiles $localUser
        Clear-EdgeCacheFiles $localUser
        Clear-EpicGamesCacheFiles $localUser
        Clear-FirefoxCacheFiles $localUser
        Clear-GoogleEarth $localUser
        Clear-iTunesCacheFiles $localUser
        Clear-LibreOfficeCacheFiles $localUser
        Clear-LolScreenSaverCacheFiles $localUser
        Clear-MicrosoftOfficeCacheFiles $localUser
        Clear-SteamCacheFiles $localUser
        Clear-TeamsCacheFiles $localUser
        Clear-ThunderbirdCacheFiles $localUser
        Clear-WindowsUserCacheFiles $localUser
    }
}

function Clear-WindowsUserCacheFiles {
    param([string]$user = $env:USERNAME)
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Internet Explorer\Cache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Internet Explorer\Recovery"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Internet Explorer\Tiles"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Terminal Server Client\Cache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\Caches"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\History\low"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\IECompatCache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\IECompatUaCache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\IEDownloadHistory"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\INetCache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\WebCache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\WER"
    Remove-Dir "C:\Users\$user\AppData\Local\Temp"
}

#region WindowsUpdate
function CheckWUS {
    $s = Get-Service wuauserv
    if ($s.Status -eq "Running") {
        return 0
    }
    else {
        return 1
    }
}

function StopWUS {
    Stop-Service wuauserv -Force
}

function StartWUS {
    Start-Service wuauserv
}

function WUSRunning {
    Write-Host "Windows Update Service is Running..." -ForegroundColor Red
    Write-Host " Stopping Windows Update Service..." -ForegroundColor Blue

    # Stopping Windows Update Service and check again if it is stopped
    StopWUS
    if (CheckWUS) {
        WUSStopped
    }
    else {
        Write-Host "Can't stop Windows Update Service..." -ForegroundColor Red
        exit 1
    }
    Write-Host "Starting Windows Update Service..." -ForegroundColor Blue

    # Starting the Windows Update Service again
    StartWUS
}

function WUSStopped {

    Write-Host "Windows Update Service is Stopped..." -ForegroundColor Green



    Write-Host " Cleaning Files..." -ForegroundColor Blue -NoNewline
    Get-ChildItem -LiteralPath $env:windir\SoftwareDistribution\Download\ -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "Done..." -ForegroundColor Green


}

#endregion

#Region Helper functions

function FreeDiskSpace {
    param(
        [string]$DiskLetter = 'C'
    )

    return ([math]::Round((Get-Volume -DriveLetter $DiskLetter | Select-Object @{ Name = "MB"; Expression = { $_.SizeRemaining / 1MB } }).MB, 2))
}

function Stop-BrowserSessions {
    $activeBrowsers = Get-Process Firefox*, Chrome*, Waterfox*, Edge*
    ForEach ($browserProcess in $activeBrowsers) {
        try {
            $browserProcess.CloseMainWindow() | Out-Null
        }
        catch {
        }
    }
}


function Get-StorageSize {
    Get-WmiObject Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq "3" } |
    Select-Object SystemName,
    @{ Name = "Drive"; Expression = { ( $_.DeviceID) } },
    @{ Name = "Size (GB)"; Expression = { "{0:N1}" -f ( $_.Size / 1gb) } },
    @{ Name = "FreeSpace (GB)"; Expression = { "{0:N1}" -f ( $_.Freespace / 1gb) } },
    @{ Name = "PercentFree"; Expression = { "{0:P1}" -f ( $_.FreeSpace / $_.Size) } } |
    Format-Table -AutoSize | Out-String
}

function Remove-Dir {
    param([Parameter(Mandatory = $true)][string]$path)

    if ((Test-Path "$path")) {
        Get-ChildItem -Path "$path" -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue #-Verbose
    }
}

#Endregion Helperfunctions

#Region Browsers

#Region ChromiumBrowsers

function Clear-ChromeTemplate {
    param(
        [Parameter(Mandatory = $true)][string]$path,
        [Parameter(Mandatory = $true)][string]$name
    )

    if ((Test-Path $path)) {
        Write-Output "Clear cache $name"
        $possibleCachePaths = @("Cache", "Cache2\entries\", "ChromeDWriteFontCache", "Code Cache", "GPUCache", "JumpListIcons", "JumpListIconsOld", "Media Cache", "Service Worker", "Top Sites", "VisitedLinks", "Web Data")
        ForEach ($cachePath in $possibleCachePaths) {
            Remove-Dir "$path\$cachePath"
        }
    }
}

function Clear-MozillaTemplate {
    param(
        [Parameter(Mandatory = $true)][string]$path,
        [Parameter(Mandatory = $true)][string]$name
    )

    if ((Test-Path $path)) {
        Write-Output "Clear cache $name"
        $AppDataPath = (Get-ChildItem "$path" | Where-Object { $_.Name -match "Default" }[0]).FullName
        $possibleCachePaths = @("cache", "cache2\entries", "thumbnails", "webappsstore.sqlite", "chromeappstore.sqlite")
        ForEach ($cachePath in $possibleCachePaths) {
            Remove-Dir "$AppDataPath\$cachePath"
        }
    }
}

function Clear-ChromeCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Google\Chrome\User Data\Default" "Browser Google Chrome"
    Remove-Dir "C:\users\$user\AppData\Local\Google\Chrome\User Data\SwReporter\"
}

function Clear-EdgeCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Microsoft\Edge\User Data\Default" "Browser Microsoft Edge"
    Remove-Dir "C:\users\$user\AppData\Local\Microsoft\Edge\User Data\Default\CacheStorage"
}

#Endregion ChromiumBrowsers

#Region FirefoxBrowsers

function Clear-FirefoxCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-MozillaTemplate "C:\users\$user\AppData\Local\Mozilla\Firefox\Profiles" "Browser Mozilla Firefox"
}

function Clear-WaterfoxCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-MozillaTemplate "C:\users\$user\AppData\Local\Waterfox\Profiles" "Browser Waterfox"
}

#Endregion FirefoxBrowsers

#Endregion Browsers

#Region CommunicationPlatforms

function Clear-TeamsCacheFiles {
    param([string]$user = $env:USERNAME)
    if ((Test-Path "C:\users\$user\AppData\Roaming\Microsoft\Teams")) {
        $possibleCachePaths = @("application cache\cache", "blob_storage", "Cache", "Code Cache", "GPUCache", "logs", "tmp", "Service Worker\CacheStorage", "Service Worker\ScriptCache")
        $teamsAppDataPath = "C:\users\$user\AppData\Roaming\Microsoft\Teams"
        ForEach ($cachePath in $possibleCachePaths) {
            Remove-Dir "$teamsAppDataPath\$cachePath"
        }
    }
}

#Endregion CommunicationPlatforms

#Region MiscApplications

function Clear-ThunderbirdCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-MozillaTemplate "C:\users\$user\AppData\Local\Thunderbird\Profiles" "Mozilla Thunderbird"
}

function Clear-EpicGamesCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\EpicGamesLauncher\Saved\webcache" "Epic Games Launcher"
}

function Clear-BattleNetCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Battle.net\BrowserCache" "BattleNet"
}

function Clear-SteamCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Steam\htmlcache" "Steam"
}

function Clear-LolScreenSaverCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\LolScreenSaver\cefCache" "Lol screen saver"
}

function Clear-DiscordCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Discord" "Discord"
}

function Clear-AVGCacheFiles {
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\AVG\User Data\Default" "Antivirus AVG"
}

function Clear-GoogleEarth {
    param([string]$user = $env:USERNAME)
    if (Test-Path C:\users\$user\AppData\LocalLow\Google\GoogleEarth) {
        Get-ChildItem "C:\users\$user\AppData\LocalLow\Google\GoogleEarth\unified_cache_leveldb_leveldb2\" -Recurse -Force -ErrorAction SilentlyContinue |
        remove-item -force -recurse -ErrorAction SilentlyContinue -Verbose
        Get-ChildItem "C:\users\$user\AppData\LocalLow\Google\GoogleEarth\webdata\" -Recurse -Force -ErrorAction SilentlyContinue |
        remove-item -force -recurse -ErrorAction SilentlyContinue -Verbose
    }
}

function Clear-iTunesCacheFiles {
    param([string]$user = $env:USERNAME)
    if ((Test-Path "C:\users\$user\AppData\Local\Apple Computer\iTunes")) {
        $iTunesAppDataPath = "C:\users\$user\AppData\Local\Apple Computer\iTunes"
        $possibleCachePaths = @("SubscriptionPlayCache")
        ForEach ($cachePath in $possibleCachePaths) {
            Remove-Dir "$iTunesAppDataPath\$cachePath"
        }
    }
}

function Clear-AcrobatCacheFiles {
    param([string]$user = $env:USERNAME)
    $DirName = "C:\users\$user\AppData\LocalLow\Adobe\Acrobat"
    if ((Test-Path "$DirName")) {
        $possibleCachePaths = @("Cache", "ConnectorIcons")
        ForEach ($AcrobatAppDataPath in (Get-ChildItem "$DirName").Name) {
            ForEach ($cachePath in $possibleCachePaths) {
                Remove-Dir "$DirName\$AcrobatAppDataPath\$cachePath"
            }
        }
    }
}

function Clear-MicrosoftOfficeCacheFiles {
    param([string]$user = $env:USERNAME)
    if ((Test-Path "C:\users\$user\AppData\Local\Microsoft\Outlook")) {
        Get-ChildItem "C:\users\$user\AppData\Local\Microsoft\Outlook\*.pst" -Recurse -Force -ErrorAction SilentlyContinue |
        remove-item -force -recurse -ErrorAction SilentlyContinue -Verbose
        Get-ChildItem "C:\users\$user\AppData\Local\Microsoft\Outlook\*.ost" -Recurse -Force -ErrorAction SilentlyContinue |
        remove-item -force -recurse -ErrorAction SilentlyContinue -Verbose
        Get-ChildItem "C:\users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.Outlook\*" -Recurse -Force -ErrorAction SilentlyContinue |
        remove-item -force -recurse -ErrorAction SilentlyContinue -Verbose
        Get-ChildItem "C:\users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.MSO\*" -Recurse -Force -ErrorAction SilentlyContinue |
        remove-item -force -recurse -ErrorAction SilentlyContinue -Verbose
        Get-ChildItem "C:\users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.Word\*" -Recurse -Force -ErrorAction SilentlyContinue |
        remove-item -force -recurse -ErrorAction SilentlyContinue -Verbose
    }
}

function Clear-LibreOfficeCacheFiles {
    param([string]$user = $env:USERNAME)
    $DirName = "C:\users\$user\AppData\Roaming\LibreOffice"
    if ((Test-Path "$DirName")) {
        $possibleCachePaths = @("cache", "crash", "user\backup", "user\temp")
        ForEach ($LibreOfficeAppDataPath in (Get-ChildItem "$DirName").Name) {
            ForEach ($cachePath in $possibleCachePaths) {
                Remove-Dir "$DirName\$LibreOfficeAppDataPath\$cachePath"
            }
        }
    }
}

#Endregion MiscApplications


function Clear-Space {


    # Getting free disk space before the cleaning actions
    Write-Host " Free Disk Space before: " -ForegroundColor Blue -NoNewline
    $Before = FreeDiskSpace
    Write-Host "$Before MB"


    if (CheckWUS) {
        WUSStopped
    }
    else {
        WUSRunning
    }

    if (-not (Get-Command "Get-WmiObject" -ErrorAction SilentlyContinue)) {
        New-Alias -Name "Get-WmiObject" -Value "Get-CimInstance"
    }

    $StartTime = (Get-Date)
    $stBefore = Get-StorageSize

    Clear-UserCacheFiles
    Clear-GlobalWindowsCache

    $EndTime = (Get-Date)
    $stAfter = Get-StorageSize

    Write-Host "Clean storage." -ForegroundColor DarkYellow
    Write-Host  "Storage before" -ForegroundColor DarkGreen
    Write-Host  $stBefore -ForegroundColor DarkYellow
    Write-Host  "Storage after" -ForegroundColor DarkGreen
    Write-Host  $stAfter -ForegroundColor DarkYellow
    Write-Host  "Elapsed Time: $( ($StartTime - $EndTime).totalseconds ) seconds" -ForegroundColor DarkYellow


    # Getting free disk space after the cleaning actions
    Write-Host " Free Disk Space after: " -ForegroundColor Blue -NoNewline
    $After = FreeDiskSpace
    Write-Host "$After MB"
    
    # Calculating the free disk space difference
    Write-Host " Cleaned: " -ForegroundColor Blue -NoNewline
    $Cleaned = $After - $Before
    Write-Host "$Cleaned MB"

}