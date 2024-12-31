## Small PowerShell scripts that help perform some small computer management tasks.

| Folder   | Info   |
| :--------| :------|
| *root*     | top level scrips                                           |
| *.config*  | config files with data that scripts used                   |
| *Modules*  | reusable code used in other scripts                        |
| *Software* | scripts that solve tasks of specific programs              |
| *Windows*  | specific windows scripts, reg files and other resources    |

### Top level scripts

All scripts that can work on remote machine, uses PSSession (ssh)

- **ConfigureWakeOnLan.ps1** - tune computer for wake on lan ready. No parameters.
  - disable fast startup
  - set some parameter of the active ethernet adapter
    - "Wake on Magic Packet"      = "Enabled|On"
    - "Shutdown Wake-On-Lan"      = "Enabled"
    - "Shutdown Wake Up"          = "Enabled"
    - "Energy Efficient Ethernet" = "Disabled|Off"
    - "Green Ethernet"            = "Disabled"
  
- **DownloadItems.ps1** - downloads software. The data for the job is taken from config file *Software.json*.  
  
  | Parameter  | Mandatory  |Type     | Info   |
  | :--------  | :------    | :------ | :------|
  | *SetName*  | *true* | *string* | Name of items set from *Software.json*  |
  | *IncludeNames* | *false* | *string[]* | Only the specified items from the set will be downloaded |
  | *ExcludeNames* | *false* | *string[]* | Exclude the specified items from the set will be downloaded  |
  
- **InstallMSUpdates.ps1** -  checks and runs windows update on a remote computer. Used ssh session.The data for the job is taken from config file *Network.json* file, section Hosts.  
  
  | Parameter  | Mandatory  |Type     | Info   |
  | :--------  | :------    | :------ | :------|
  | *NetworkName*  | *true* | *string* | Name of Network name from *Networks.json*  |
  | *IncludeNames* | *false* | *string[]* | Only the the specified hosts from the network will be updated |
  | *ExcludeNames* | *false* | *string[]* | Exclude the specified hosts from the network will be updated  |

- **InvokeWakeOnLan.ps1** - send magic packet to multiple remote machines. The data for the job is taken from config file *Network.json* file, section Hosts. Host parameter "wolFlag" must be set $true - *"wolFlag": true*.  
  
  | Parameter  | Mandatory  |Type     | Info   |
  | :--------  | :------    | :------ | :------|
  | *NetworkName*  | *true* | *string* | Name of Network name from *Networks.json*   |
  | *IncludeNames* | *false* | *string[]* | Wol packet is sent only to specified remote hosts from network (NetworkName). |
  | *ExcludeNames* | *false* | *string[]* | Wol packet is sent to hosts on network (NetworkName), excluding those specified. |

- **ScanNetwork.ps1** - scan ip range by ping or open port.
  | Parameter  | Mandatory  |Type     | Info   |
  | :--------  | :------    | :------ | :------|
  | *NetworkName*  | *true* | *string* | Name of Network name from *Networks.json* section scan. The IP address range is taken from the configuration file.|
  | *FromIp* | *true* | *ipaddress* | Start ip. |
  | *ToIp* | *true* | *ipaddress* | End ip. |
  | *Port* | *false* | *int* | Port number. |
  
  ```
  # examples:
  . '\ScanNetwork.ps1' "192.168.1.0" "192.168.1.255" 22 - scan ip range by checking open port 22
  . '\ScanNetwork.ps1' -NetworkName "NetworkA"  - scans all ranges defined in the configuration file in the "NetworkA" section.
  ```

- **SetStartupItems.ps1**

- **SetUserSettings.ps1**
  
  | Parameter  | Mandatory  |Type     | Info   |
  | :--------  | :------    | :------ | :------|
  | *UserName*  | *true* | *string* | Name of User from *Users.json*   |
  | *Operations* | *false* | *string[]* | If not specified, all operations will be performed; if specified, only these ones. |
  | *ListOperations* | *false* | *switch* | Write out list of operation allowed on specified user. |
  
  How many times after a new installation (reinstallation) of Windows did you set it up to its usual state (install applications, change various settings, etc.)
  This script automates some of these tasks after a new installation of Windows.
  The actions and data for the work are taken from the Users.json file.
  List of actions:
  - *InstallMsvcrt* - Install all Microsoft C and C++ (MSVC) runtime libraries. No parameters.
  - *SetRdpConnections* - Allow RDP connections to this PC.  No parameters.
  - *GitConfig* - Config git settings (safe folders = *).  No parameters.
  - *SetUserFolders* - Set user folders location (Documents, Pictures, Desktop, Videos, Music). Configured in *Users.json*
    ```json
    "params": {
      "Folders": {
        "Desktop": "D:\\_users\\<?UserName?>\\Desktop",
        "Documents": "D:\\_users\\<?UserName?>\\Documents",
        "Pictures": "D:\\_users\\<?UserName?>\\Pictures",
        "Video": "D:\\_users\\<?UserName?>\\Videos",
        "Music": "E:\\Music"
      }
    }  
    ```
  - *InstallApplications*  - Install aplications by winget. Array of software ids to install configured in *Users.json*
    ```json
    "params": {
      "Applications": [
        "RARLab.WinRAR",
        "Notepad++.Notepad++",
        "Telegram.TelegramDesktop",
        "Microsoft.DotNet.DesktopRuntime.7",
        "Microsoft.DotNet.AspNetCore.7",
        "Microsoft.DotNet.Runtime.7"
      ]
    }
    ```
  - *SetMpPreference* - add exclusion folders to Windows Defender.  Array of folders to exclude, configured in *Users.json*
    ```json
    "params": {
      "Items": ["D:\\_software", "D:\\work\\reverse"]
    }    
    ```
  - *MakeSimLinks* - make simlinks, if simlink exist and correct do nothing.  Configured in *Users.json*
    - *SimLinks*, type: *hashtable*. Each item *key* - source path, *value* - destination path. If the simlink exist and correct do nothing.
      ```json
      "SimLinks": {
        "<?UserProfile?>\\.ssh\\config": "D:\\work\\network\\users\\bob\\.ssh\\config",
        "<?UserProfile?>\\.ssh\\id_rsa": "D:\\work\\network\\users\\bob\\.ssh\\id_rsa",
        "<?UserProfile?>\\.ssh\\id_rsa.pub": "D:\\work\\network\\users\\bob\\.ssh\\id_rsa.pub"
      }
      ```
  - *AddRegFiles* - import reg files to registry.  Configured in *Users.json*
    - *Items* type: *string[]* - array of relative to *"root\Windows\Registry"* folder reg file paths.
    ```json
    "params": {
      "Items": [
        "\\Explorer_Expand to current folder_ON.reg",
        "\\Context Menu\\WIndows 11 classic context menu\\win11_classic_context_menu.reg",
        "\\Explorer_Activate Windows Photo Viewer on Windows 10.reg",
        "\\Explorer_Show_extensions_for_known_file_types.reg",
        "\\Change-KeyboardToggle.reg"
      ]
    }    
    ```
  - *PrepareHosts* - add records to *C:\Windows\System32\drivers\etc* file. If the record exists do nothing.  Configured in *Users.json*.
    ```json
    "params": {
      "Hosts": {
        "Common": [
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
        ]
      }    
    ``` 
### config files
  - *software.json*
    - *Name* - just item name
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
  - *Network.json*  
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
        },
        "Scan": [
        {
          "order": "01",
          "method": "ping",
          "ipfrom": "192.168.1.0",
          "ipto": "192.168.1.255"
        },
        {
          "order": "02",
          "method": "port",
          "ipfrom": "192.168.1.0",
          "ipto": "192.168.1.255",
          "port": "22"
        },
        {
          "order": "03",
          "method": "port",
          "ipfrom": "192.168.1.0",
          "ipto": "192.168.1.255",
          "port": "3389"
        },
        {
          "order": "03",
          "method": "port",
          "ipfrom": "192.168.1.0",
          "ipto": "192.168.1.255",
          "port": "9100"
        }
      ]
    }
    ```
    
  - *Users.json*
    ```json
    {
      "UncleBob": {
        "Default": true,
        "Operations": {
          "InstallMsvcrt": {
            "order": "001",
            "params": null
          },
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
          },
          "SetRdpConnections": {
            "order": "003",
            "params": null
          },
          "GitConfig": {
            "order": "004",
            "params": null
          },
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
          },
          "SetMpPreference": {
            "order": "006",
            "params": {
              "Items": ["D:\\_software", "D:\\work\\reverse"]
            }
          },
          "MakeSimLinks": {
            "order": "008",
            "params": {
              "SimLinks": {
                "<?UserProfile?>\\.ssh\\config": "D:\\work\\network\\users\\bob\\.ssh\\config",
                "<?UserProfile?>\\.ssh\\id_rsa": "D:\\work\\network\\users\\bob\\.ssh\\id_rsa",
                "<?UserProfile?>\\.ssh\\id_rsa.pub": "D:\\work\\network\\users\\bob\\.ssh\\id_rsa.pub"
              }
            }
          },
          "AddRegFiles": {
            "order": "009",
            "params": {
              "Items": [
                "\\Explorer_Expand to current folder_ON.reg",
                "\\Context Menu\\WIndows 11 classic context menu\\win11_classic_context_menu.reg",
                "\\Explorer_Activate Windows Photo Viewer on Windows 10.reg",
                "\\Explorer_Show_extensions_for_known_file_types.reg",
                "\\Explorer_Show_SuperHidden.reg",
                "\\Explorer_Open_to_PC.reg",
                "\\Change-KeyboardToggle.reg"
              ]
            }
          },
          "PrepareHosts": {
            "order": "007",
            "params": {
              "Hosts": {
                "Common": [
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
                ]
              }
            }
          }
        },
        "StartupItems": {
          "order": "010",
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
            "--Argument": "--connect 'sean_agitech.ovpn'",
            "prepare": true
          },
          "Hiddify": {
            "Path": "D:\\software\\network\\hiddify\\Hiddify.exe",
            "--Argument": "--connect 'sean_agitech.ovpn'",
            "prepare": true
          }
        }
      }
    }
    ```    


  *Substitutions* that used in Users.json:
  ```
    "UserName" = [Environment]::UserName
    "UserProfile" = "$([System.Environment]::GetFolderPath("UserProfile"))"  
  ```
