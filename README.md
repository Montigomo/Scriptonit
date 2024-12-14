
### Small PowerShell scripts that help to solve small computer management tasks.

1. .config - folder with config files that data scripts used
2. Modules - folder with reusable code used in other scripts
3. Software -
4. Windows -
5. top level scrips
  - ConfigureWakeOnLan.ps1 - tune computer for wake on lan ready.
    - disable fast startup
    - set some parameter of the active ethernet adapter
      - "Wake on Magic Packet"      = "Enabled|On"
      - "Shutdown Wake-On-Lan"      = "Enabled"
      - "Shutdown Wake Up"          = "Enabled"
      - "Energy Efficient Ethernet" = "Disabled|Off"
      - "Green Ethernet"            = "Disabled"
  - DownloadItems.ps1 - download software releases. Data for work peeked up from config file Software.json (.config folder).  
example github item:
```
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

```
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
  - InstallMSUpdates.ps1 -  checks and runs windows update on a remote computer. Useed ssh session. Data for work is taken from Network.json file.
```
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
