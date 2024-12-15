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
      "Url": "VirtualHere", [name of existing function that will invoked, invoked function name is Download prefix and Url, in this example function name will be DownloadVirtualHere ]
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
