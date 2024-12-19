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
example github item:

 "Url" - real github project url or name of existing function that will invoked,  invoked function name is Download prefix and Url, for example if *"Url": "VirtualHere"* invoked function name will be *DownloadVirtualHere*

```json
    {
      "Name": "Win32-OpenSSH",
      "Type": "github",
      "Url": "https://github.com/PowerShell/Win32-OpenSSH",
      "Destination": "D:\\path\\Open SSH",
      "Deep": 7,
      "UsePreview": false,
      "Force": false,
      "Prepare": true
    }
```

```json
    {
      "Name": "VirtualHere",
      "Type": "direct",
      "Url": "VirtualHere",
      "Destination": "D:\\path\\VirtualHere",
      "UsePreview": true,
      "Force": false,
      "Prepare": true
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
 Actions and data  for work is taken from Users.json file. Below list of actions:
  - *InstallMsvcrt* - Install all Microsoft C and C++ (MSVC) runtime libraries. No parameters
  - *SetRdpConnections* - Config RDP connections to this PC |
  - *GitConfig* - Config git settings (safe folders = *)
  - *SetUserFolders* - Set location users folder (Documents, Pictures, Desktop, Videos, Music) to new location |
  - *InstallApplications*  - Install aplications by winget. Parameters
    - *Applications* - Array of applications ids, type - *string[]*. Example:
    ```json
      "InstallApplications": {
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
  - SetMpPreference
 |                      | Items     | string[] | Array of folders path. Example: </br>```      "SetMpPreference": {
        "order": "006",
        "params": {
          "Items": [
            "D:\\_software",
            "D:\\work",
            "D:\\work\\reverse"
          ]
        }
      }``` </br>|
 | MakeSimLinks         | | | |
 |                      | SimLinks  | hashtable | "\\.ssh\\config": "D:\\path\\.ssh\\config"          "\\.ssh\\id_rsa": "D:\\path\\.ssh\\id_rsa"         "\\.ssh\\id_rsa.pub": "D:\\path\\id_rsa.pub"
 | AddRegFiles          | | | |
 |                      | Items     | string[] |  "\\Explorer_Expand to current folder_ON.reg", "\\Context Menu\\WIndows 11 classic context menu\\win11_classic_context_menu.reg", "\\Explorer_Show_SuperHidden.reg" |
 | PrepareHosts         | | | |
 |                      | Hosts | hashtable|  |
 | | | | '''"Common": [
              "127.0.0.1|compute-1.amazonaws.com",
              "0.0.0.0|license.sublimehq.com",
              "83.243.40.67|wiki.bash-hackers.org"
            ],
            "Corel": [
              "127.0.0.1|iws.corel.com",
              "127.0.0.1|apps.corel.com",
              "127.0.0.1|mc.corel.com",
              "127.0.0.1|origin-mc.corel.com",
              "127.0.0.1|iws.corel.com",
              "127.0.0.1|deploy.akamaitechnologies.com"
            ]''' |
            
    "StartupItems": {
      "UniversalMediaServer": {
        "Path": "C:\\Program Files (x86)\\Universal Media Server\\UMS.exe",
        "prepare": true
      },
      "VirtalHere": {
        "Path": "D:\\tools\\network\\VirtualHere\\vhui64.exe",
        "prepare": true
      },
      "SimpleDLNA": {
        "Path": "D:\\software\\simpledlna\\SimpleDLNA.exe",
        "prepare": true
      },
      "OpenVPN": {
        "Path": "C:\\Program Files\\OpenVPN\\bin\\openvpn-gui.exe",
        "Argument": "--connect 'sean_agitech.ovpn'",
        "prepare": true
      }
    }
