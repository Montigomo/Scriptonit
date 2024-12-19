## Small PowerShell scripts that help to solve some small computer management tasks

| Folder   | Info   |
| :--------| :------|
| *root*     | top level scrips                                           |
| *.config*  | config files with data that scripts used                   |
| *Modules*  | reusable code used in other scripts                        |
| *Software* | scripts that solve tasks of specific programs              |
| *Windows*  | specific windows scripts, reg files and other resources    |

### Top level scripts

All scripts that can work on remote machine, uses PSSession (ssh)

- **ConfigureWakeOnLan.ps1** - tune computer for wake on lan ready.
  - disable fast startup
  - set some parameter of the active ethernet adapter
    - "Wake on Magic Packet"      = "Enabled|On"
    - "Shutdown Wake-On-Lan"      = "Enabled"
    - "Shutdown Wake Up"          = "Enabled"
    - "Energy Efficient Ethernet" = "Disabled|Off"
    - "Green Ethernet"            = "Disabled"
  
- **DownloadItems.ps1** - downloads software releases. Data for work is taken from config file Software.json.
  - *Name* - just iten name
  - *type* - *github*, *direct*
  - *Url* - project url, if *type* = *github* just url of the github project, if *type* = *direct* will invoked function with prefix *"Download"* and Url, for example if *"Url": "VirtualHere"* invoked function name will be *DownloadVirtualHere*
  - *Destination* - destination folder
  - *Deep* - how many versions (releases) will be downloaded, from latest. Only for items *type = github*.
  - *UsePreview* - download previews or only releses.  Only for items *type = github*.
  - *Force* - Rewrite files in the destiantion foder.
  - *Prepare* - *$true* - download, *$false* - not
```json
{
  "SoftwareSet001": [
    {
      "Name": "Win32-OpenSSH",
      "Type": "github",
      "Url": "https://github.com/PowerShell/Win32-OpenSSH",
      "Destination": "D:\\path\\Open SSH",
      "Deep": 7,
      "UsePreview": false,
      "Force": false,
      "Prepare": true
    },
    {
      "Name": "easyrsa",
      "Type": "github",
      "Url": "https://github.com/OpenVPN/easy-rsa",
      "Destination": "D:\\path\\easyrsa",
      "UsePreview": false,
      "Force": false,
      "Prepare": true
    },
    {
      "Name": "hiddify",
      "Type": "github",
      "Url": "https://github.com/hiddify/hiddify-next/",
      "Destination": "D:\\path\\hiddify",
      "UsePreview": false,
      "Force": false,
      "Prepare": true
    },
    {
      "Name": "hiddify",
      "Type": "github",
      "Url": "https://github.com/hiddify/hiddify-next/",
      "Destination": "D:\\path\\hiddify",
      "UsePreview": true,
      "Force": false,
      "Prepare": true
    },
    {
      "Name": "VirtualHere",
      "Type": "direct",
      "Url": "VirtualHere",
      "Destination": "D:\\path\\VirtualHere",
      "UsePreview": true,
      "Force": false,
      "Prepare": true
    }
  ]
}
```

- **InstallMSUpdates.ps1** -  checks and runs windows update on a remote computer. Used ssh session. Data for work is taken from Network.json file.

```json
  "NetworkA": {
    "Default": true,
    "Hosts": {
      "UserDesktop": {
        "ip": "192.168.1.100",
        "username": "usera@outlook.com",
        "WUFlag": true,
        "MAC": "ff:ff:ff:ff:ff:ff",
        "wolFlag": true,
        "wolPort": 9
      },
      "UserLaptop": {
        "ip": "192.168.1.105",
        "username": "userb@outlook.com",
        "WUFlag": true,
        "MAC": "ff:ff:ff:ff:ff:ff",
        "wolFlag": true,
        "wolPort": 9
      },
      "UserLenovo": {
        "ip": "192.168.1.110",
        "username": "userb@outlook.com",
        "WUFlag": true,
        "MAC": "ff:ff:ff:ff:ff:ff",
        "wolFlag": true,
        "wolPort": 9
      },
      "UserBeelink": {
        "ip": "192.168.1.102",
        "username": "userc@outlook.com",
        "WUFlag": true,
        "MAC": "ff:ff:ff:ff:ff:ff",
        "wolFlag": true,
        "wolPort": 9
      }
    }
  }
```

- **InvokeWakeOnLan.ps1**

send magic packet to multiple remote machines. Remote machines list took from *.config/Networks.json* section Hosts, Host parameter "wolFlag" must be $true - *"wolFlag": true*.

| Parameter  | ParameterSet | Type | Info   |
| :--------| :------| :------| :------|
| *NetworkName*  | Include, Exclude | [string] | PC list from *Networks.json*  |
| *IncludeNames* | Include | [string] | Wol packet sends only to specified remote pc from pc list (NetworkName) |
| *ExcludeNames* | Exclude | [string] | Wol packet sends to pc list NetworkName) exclude specified  |

- **ScanNetwork.ps1**

- **SetStartupItems.ps1**

- **SetUserSettings.ps1**  
 How many times after a new installation (reinstallation) of Windows do you configure it to its usual state (install applications, change various settings, etc.)  
 This script automate many of this tasks after fresh windows install.
 Actions and data  for work is taken from Users.json file.  
 Below list of actions:
  - *InstallMsvcrt* - Install all Microsoft C and C++ (MSVC) runtime libraries. No parameters.
  - *SetRdpConnections* - Config RDP connections to this PC.  No parameters.
  - *GitConfig* - Config git settings (safe folders = *).  No parameters.
  - *SetUserFolders* - Set user folders location (Documents, Pictures, Desktop, Videos, Music).  Parameters:
    - *Folders*, type - *hashtable* - Each item *Key* - UserFolderName, *Value* - desirable location.  Example:
    ```json
      "SetUserFolders": {
        "order": "005",
        "params": {
          "Folders": {
            "Desktop": "D:\\_users\\<?UserName?>\\Desktop",
            "Documents": "D:\\_users\\<?UserName?>\\Documents",
            "Pictures": "D:\\_users\\<?UserName?>\\Pictures",
            "Video": "D:\\_users\\<?UserName?>\\Videos",
            "Music": "E:\\Music"
          }
        }
      }  
    ```
  - *InstallApplications*  - Install aplications by winget. Parameters:
    - *Applications* - Array of applications ids, type - *string[]*. Example:
    ```json
      "InstallApplications": {
        "order": "002",
        "params": {
          "Applications": [
            "RARLab.WinRAR",
            "--Notepad++.Notepad++",
            "Telegram.TelegramDesktop",
            "Logitech.GHUB",
            "DeepL.DeepL",
            "OpenVPNTechnologies.OpenVPN",
            "VideoLAN.VLC",
            "Git.Git",
            "TortoiseGit.TortoiseGit",
            "Microsoft.DotNet.DesktopRuntime.7",
            "Microsoft.DotNet.AspNetCore.7",
            "Microsoft.DotNet.Runtime.7"
          ]
        }
      }   
    ```
  - *SetMpPreference* - add exclusion folders to Windows Defender.  Parameters:
    - Items - Array of folder paths, type - *string[]*. Example:
    ```json
      "SetMpPreference": {
        "order": "006",
        "params": {
          "Items": [
            "D:\\_software",
            "D:\\work",
            "C:\\Users\\agite\\YandexDisk",
            "D:\\work\\reverse"
          ]
        }
      }
      ```
  - *MakeSimLinks*
  - *AddRegFiles*
  - *PrepareHosts*
  *Substitutions* that used in Users,json:
  ```
    "UserName" = [Environment]::UserName
    "UserProfile" = "$([System.Environment]::GetFolderPath("UserProfile"))"  
  ```
      
