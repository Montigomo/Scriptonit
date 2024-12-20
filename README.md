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
  
  | Parameter  | ParameterSet | Type | Info   |
  | :--------| :------| :------| :------|
  | *SetName*  | Include, Exclude | *string* | Name of items set from *Software.json*  |
  | *IncludeNames* | Include | *string[]* | Only the specified items from the set will be downloaded |
  | *ExcludeNames* | Exclude | *string[]* | Exclude the specified items from the set will be downloaded  |
  
- **InstallMSUpdates.ps1** -  checks and runs windows update on a remote computer. Used ssh session.The data for the job is taken from config file *Network.json* file, section Hosts.  
  
  | Parameter  | ParameterSet | Type | Info   |
  | :--------| :------| :------| :------|
  | *NetworkName*  | Include, Exclude | *string* | Name of Network name from *Networks.json*  |
  | *IncludeNames* | Include | *string[]* | Only the the specified hosts from the network will be updated |
  | *ExcludeNames* | Exclude | *string[]* | Exclude the specified hosts from the network will be updated  |

- **InvokeWakeOnLan.ps1** - send magic packet to multiple remote machines. The data for the job is taken from config file *Network.json* file, section Hosts. Host parameter "wolFlag" must be set $true - *"wolFlag": true*.  
  
  | Parameter  | ParameterSet | Type | Info   |
  | :--------| :------| :------| :------|
  | *NetworkName*  | Include, Exclude | *string* | Name of Network name from *Networks.json*   |
  | *IncludeNames* | Include | *string[]* | Wol packet is sent only to specified remote hosts from network (NetworkName). |
  | *ExcludeNames* | Exclude | *string[]* | Wol packet is sent to hosts on network (NetworkName), excluding those specified. |

- **ScanNetwork.ps1**

- **SetStartupItems.ps1**

- **SetUserSettings.ps1**  
 How many times after a new installation (reinstallation) of Windows do you configure it to its usual state (install applications, change various settings, etc.)  
 This script automate many of this tasks after fresh windows install.
 Actions and data  for work is taken from Users.json file.  
      
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
        }
      }
    ```
    
  - *Users.json*
    
     List of actions:
    - *InstallMsvcrt* - Install all Microsoft C and C++ (MSVC) runtime libraries. No parameters.
    - *SetRdpConnections* - Config RDP connections to this PC.  No parameters.
    - *GitConfig* - Config git settings (safe folders = *).  No parameters.
    - *SetUserFolders* - Set user folders location (Documents, Pictures, Desktop, Videos, Music).  Parameters:
    - *Folders*, type: *hashtable* - Each item *Key* - UserFolderName, *Value* - desirable location.
    - *InstallApplications*  - Install aplications by winget. Parameters:
    - *Applications*, type: *string[]* - Array of applications ids. Example:
    - *SetMpPreference* - add exclusion folders to Windows Defender.  Parameters:
      - *Items*,type: *string[]*  - Array of folder paths. Example:
    - *MakeSimLinks* - make simlinks, if suimlink exist and correct do nothing.
      - *SimLinks*,type: *hashtable*. Each item *key* - source path, *value* - destination path. If the simlink exist and correct do nothing. Example:
    - *AddRegFiles* - import reg files to registry.
    - *Items* type: *string[]* - array of relative to *"root\Windows\Registry"* folder reg file paths.
    - *PrepareHosts* - add records to *C:\Windows\System32\drivers\etc* file. If the record exists do nothing.  

  *Substitutions* that used in Users.json:
  ```
    "UserName" = [Environment]::UserName
    "UserProfile" = "$([System.Environment]::GetFolderPath("UserProfile"))"  
  ```
