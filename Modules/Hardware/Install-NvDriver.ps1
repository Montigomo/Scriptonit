Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\LoadModule.ps1" -ModuleNames @("Common", "Hardware", "Network") | Out-Null

enum NvDriverType{
    Standart = 0
    DCH = 1
}

# .SYNOPSIS
#     Install latest Nvidia driver
# .DESCRIPTION
#     Install latest Nvidia driver
# .PARAMETER Language
#     [string] Language [ValidateSet("en-us","en-uk","en-in","cn","tw","jp","kr","de","es","la","fr","it","pl","br","ru","tr","int")]
# .PARAMETER DCH
#     [NvDriverType] DriverType - values (Standart, DCH)
#     refers to drivers developed according to Microsoft's DCH driver design principles;
#     DCH drivers are built with requisite Declarative, Componentized, Hardware Support App elements. DCH drivers are installed on most new desktop and mobile workstation systems.
#     "Standard" refers to driver packages that predate the DCH driver design paradigm. Standard drivers are for those who have not yet transitioned to contemporary DCH drivers, or require these drivers to support older products.
#     DCH drivers can be installed over a system that presently has a Standard driver, and vice versa.
#     To confirm the type of driver that is presently installed on a system, locate Driver Type under the System Information menu in the NVIDIA Control Panel.
# .PARAMETER Force
#     [switch] Force - install(reinstall) the driver even if remote version is the same
# .NOTES
#     Author: Agitech; Version : 1.0.22
function Install-NvDriver {
    [CmdletBinding(DefaultParameterSetName = 'Install')]
    param (
        [ValidateSet("en-us", "en-uk", "en-in", "cn", "tw", "jp", "kr", "de", "es", "la", "fr", "it", "pl", "br", "ru", "tr", "int")]
        [Parameter(Mandatory = $false, ParameterSetName = 'Install')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Check')]
        [string]$Language = "en-us",
        [Parameter(Mandatory = $false, ParameterSetName = 'Install')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Check')]
        [NvDriverType]$DriverType = [NvDriverType]::DCH,
        [Parameter(Mandatory = $false, ParameterSetName = 'Install')]
        [switch]$Force,
        [Parameter(Mandatory = $false, ParameterSetName = 'Check')]
        [switch]$OnlyCheck
    )

    # https://www.nvidia.com/download/find.aspx

    #region DriverData

    class DriverData {
        [int]$productTypeId = 0
        [int]$productSeriesId = 0
        [int]$productId = 0
        [int]$operationSystemId = 0
        [int]$languageId = 1
        [string]$whql = ""
        [string]$language = "en-us"
        [int]$ctk = 0
        [int]$isQNF = 0
        [int]$isSLB = 0
        [int]$dtcid = 0

        #constructors
        DriverData([bool]$DCH) {
            $this.Init($DCH)
        }
        hidden Init([bool]$DCH) {
            # 1 - Product type ID
            $this.productTypeId = 0
            # 2 - Product series ID
            $this.productSeriesId = 0
            # 3 - Product ID
            $this.productId = 0
            # 4 - Operation system ID
            $this.operationSystemId = 0
            # 5 - Language  ID
            $this.languageId = 1
            # 6 - whql
            $this.whql = ""
            # lang for site
            $this.language = "en-us"
            # var ctk = (selCudaToolkitVersionObj.value == "0" || selProductSeriesType.value != "7") ? "0" : selCudaToolkitVersionObj.value;
            $this.ctk = 0
            # ???
            $this.isQNF = 0
            # ???
            $this.isSLB = 0
            # Windows Driver Type: 0 - Standard, 1 - DCH
            if ($DCH) {
                $this.dtcid = 1
            }
            else {
                $this.dtcid = 0
            }
        }
        # Get uri foe search
        [string]GetSearchUrl() {
            $qnfslb = "$($this.isQNF)$($this.isSLB)"
            if ($this.dtcid) {
                $dtcid_str = "&dtcid=$($this.dtcid)"
            }
            else {
                $dtcid_str = ""
            }
            # samples
            # https://www.nvidia.com/download/processFind.aspx?psid=101&pfid=825&osid=135&lid=1&whql=&lang=en-us&ctk=0&qnfslb=00&dtcid=1
            # https://www.nvidia.com/Download/processFind.aspx?psid=101&pfid=825&osid=27&lid=7&whql=&lang=en-us&ctk=0&qnfslb=00
            $uri = "https://www.nvidia.com/Download/processFind.aspx?psid={0}&pfid={1}&osid={2}&lid={3}&whql={4}&lang={5}&ctk={6}&qnfslb={7}{8}" `
                -f $($this.productSeriesId), $($this.productId), $($this.operationSystemId), $($this.languageId), $($this.whql), $($this.language), $($this.ctk), $qnfslb, $dtcid_str
            return $uri
        }
    }

    #endregion

    #region WriteLog

    if (-not (Get-Variable -Name "LogFile" -Scope Global -ErrorAction SilentlyContinue)) {
        $Logfile = "$PSScriptRoot\$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)).log"
    }

    if (-not (Get-Command "WriteLog" -ErrorAction SilentlyContinue)) {
        function WriteLog {
            Param (
                [Parameter()][string]$LogString,
                [Parameter()][switch]$WithoutFunctionName
            )
            $Stamp = Get-Date -Format "yyyy.MM.dd HH:mm:ss"
            if (-not $WithoutFunctionName) {
                $LogString = "[$((Get-PSCallStack)[1].Command)]: $LogString"
            }
            Write-Host $LogString -ForegroundColor DarkYellow
            $LogString = "$Stamp $LogString"
            Add-content $LogFile -value $LogString
        }
    }

    #endregion

    #region Get-ModuleAdvanced
    if (-not (Get-Command "Get-ModuleAdvanced" -ErrorAction SilentlyContinue)) {
        Write-Host "Can't find function with name 'Get-ModuleAdvanced'" -ForegroundColor DarkYellow
        return
    }
    #endregion

    #region http functions
    function fnGetLookupRequestBase {
        param (
            [Parameter(Position = 0)] [string]$typeId,
            [Parameter()] [string]$parentId
        )
        $parentId = if ( $parentId ) { "&ParentID=$parentId" } else { "" }
        $uri = "https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID={0}{1}" -f $typeId, $parentId
        $_data = Invoke-RestMethod -Method Get -Uri $uri
        return $_data.OuterXml
    }

    function fnGetProductsAll {
        param (
            [Parameter()] [string]$productSeriesTypeId
        )
        fnGetLookupRequestBase -typeId 3
    }

    function fnGetProductSeries {
        param (
            [Parameter()] [string]$productSeriesTypeId
        )
        fnGetLookupRequestBase -typeId 2 -parentId $productSeriesTypeId
    }

    function fnGetLanguages {
        param (
            [Parameter()] [string]$productSeriesTypeId
        )
        fnGetLookupRequestBase -typeId 5 -parentId $productSeriesTypeId
    }

    function fnGetOS {
        param (
            [Parameter()] [string]$productSeriesTypeId
        )
        fnGetLookupRequestBase -typeId 4 -parentId $productSeriesTypeId
    }
    #endregion

    #region DownloadAndInstall

    function DownloadAndInstall {
        param (
            [Parameter(Mandatory = $false)][string]$DriverUrl
        )

        $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'exe' } -PassThru
        Invoke-WebRequest -Uri $DriverUrl -OutFile $tmp

        $fileName = $tmp.FullName
        $fileFolder = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($fileName), [System.IO.Path]::GetFileNameWithoutExtension($fileName));

        $filesToExtract = "Display.Driver HDAudio NVI2 PhysX EULA.txt ListDevices.txt setup.cfg setup.exe"

        if ($archiver) {
            Start-Process -FilePath $archiver -NoNewWindow -ArgumentList "x -bso0 -bsp1 -bse1 -aoa $fileName $filesToExtract -o""$fileFolder""" -wait
        }
        #elseif ($archiverProgram -eq $winrarpath) {
        #    Start-Process -FilePath $archiverProgram -NoNewWindow -ArgumentList 'x $dlFile $extractFolder -IBCK $filesToExtract' -wait
        #}

        # Get-Content in brackets for file handler release!!!
        (Get-Content -LiteralPath "$fileFolder\setup.cfg") | Where-Object { $_ -notmatch 'name="\${{(EulaHtmlFile|FunctionalConsentFile|PrivacyPolicyFile)}}' } | Set-Content "$fileFolder\setup.cfg" -Encoding UTF8 -Force

        $iargs = "-passive -noreboot -noeula -nofinish -s"

        if ($Force) {
            $iargs += " -clean"
        }

        Start-Process -FilePath "$($fileFolder)\setup.exe" -ArgumentList $iargs -wait

        WriteLog "Installation successfully completed. Computer must be restarted for fihish up."
    }

    #endregion

    #region variables and init
    [System.Uri]$_driverUrl = $null
    $_driverData = [DriverData]::new($DriverType -eq [NvDriverType]::DCH)

    # Windows Driver Type used only
    # if (getSelectedOSName() in { 'Windows 10 64-bit': '', 'Windows Server 2022': '', 'Windows Server 2019': '', 'Windows Server 2016': '', 'Windows 11': ''} && selProductSeriesType.value in { '1': '', '3': '', '7': '', '11': '' })
    # url += (getSelectedOSName() in { 'Windows 10 64-bit': '', 'Windows Server 2022': '', 'Windows Server 2019': '', 'Windows Server 2016': '', 'Windows 11': '' }) ? "&dtcid=" + selDownloadTypeDchObj.value : "&dtcid=0"; // Only Win-10-64

    $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.VideoProcessor -match "(NVIDIA )?GeForce" }

    if ($null -eq $gpu) {
        return $true
    }
    [System.Version]$drvCurrentVersion = ($gpu.DriverVersion -replace '\.' -replace '^.*(?=.{5}$)').Insert(3, '.')
    $gpu = $gpu.VideoProcessor
    $gpu = $gpu -replace "NVIDIA ", ""
    WriteLog "GPU $gpu found."

    $is64bit = [Environment]::Is64BitOperatingSystem

    Get-ModuleAdvanced -ModuleName "PowerHTML"

    #endregion

    #region Check archiver
    $filePath = "C:\Program Files\7-Zip\7z.exe"

    if (Test-path "HKLM:\SOFTWARE\7-Zip") {
        $value = Get-ItemProperty "HKLM:\SOFTWARE\7-Zip\" -Name "Path" -ErrorAction SilentlyContinue
        if ($value) {
            $filePath = "{0}7z.exe" -f $value.Path
        }
    }

    if (-not (Test-Path $filePath)) {
        if (Test-Path -Path "$PSScriptRoot\install-7zip.ps1") {
            Import-Module -Name "$PSScriptRoot\install-7zip.ps1"
            Install-7Zip
            if (Test-path "HKLM:\SOFTWARE\7-Zip") {
                $value = Get-ItemProperty "HKLM:\SOFTWARE\7-Zip\" -Name "Path" -ErrorAction SilentlyContinue
                if ($value) {
                    $filePath = "{0}7z.exe" -f $value.Path
                }
            }
        }
        else {
            $filePath = $null
        }
    }
    if (-not $filePath) {
        Write-Host "Can't find 7zip archiver." -ForegroundColor "DarkYellow"
        return $false
    }
    $archiver = $filePath

    #endregion

    #region ProductID and Series ID search
    $xml = [xml](fnGetProductsAll)
    $searchSuccess = $false

    if ($xml["LookupValueSearch"] -and $xml["LookupValueSearch"].LookupValues) {
        foreach ($item in $xml["LookupValueSearch"].LookupValues.ChildNodes) {
            if ($item -and ($item.Name -ilike "*$gpu")) {
                $_driverData.productId = $item.Value
                $_driverData.productSeriesId = $item.Attributes["ParentID"].Value
                $searchSuccess = $true
                break
            }

        }
    }

    if (-not $searchSuccess) {
        Write-Output -InputObject "Product id search unsuccesseful for $gpu" -Verbose
        return $false
    }

    $oses = @{
        "win11"    = "Windows 11";
        "win10"    = "Windows 10 {0}" -f $(if ($is64bit) { "64-bit" } else { "32-bit" } );
        "win8"     = "Windows 8 {0}" -f $(if ($is64bit) { "64-bit" } else { "32-bit" } );
        "win8.1"   = "Windows 8.1 {0}" -f $(if ($is64bit) { "64-bit" } else { "32-bit" } );
        "win7"     = "Windows 7 {0}" -f $(if ($is64bit) { "64-bit" } else { "32-bit" } );
        "winVista" = "Windows Vista {0}" -f $(if ($is64bit) { "64-bit" } else { "32-bit" } );
        "winXp"    = "Windows XP{0}" -f $(if ($is64bit) { " 64-bit" } else { "" } );
    }

    $step = 0;

    while ($true) {

        #region Os search
        $os = Get-CimInstance -ClassName "Win32_OperatingSystem"
        $osName = $os.Caption
        $osVersion = [System.Version]$os.Version

        # windows 11
        if ($osVersion -ge ([System.Version]"10.0.22000")) {
            switch ($step) {
                2 { $osName = $oses["win7"] }
                1 { $osName = $oses["win10"] }
                0 { $osName = $oses["win11"] }
            }
        }# window 10
        elseif ($osVersion -ge ([System.Version]"10.0.10240")) {
            switch ($step) {
                2 { $osName = $oses["winXp"] }
                1 { $osName = $oses["win7"] }
                0 { $osName = $oses["win10"] }
            }
        }# windows 8.1
        elseif ($osVersion -ge ([System.Version]"6.3.9600")) {
        }# windows 8
        elseif ($osVersion -ge ([System.Version]"6.2.9200")) {
        }# windows 7
        elseif ($osVersion -ge ([System.Version]"6.1.7600")) {
        }# windows vista
        elseif ($osVersion -ge ([System.Version]"6.0.6000")) {
        }# windows xp
        elseif ($osVersion -ge ([System.Version]"5.1.2600")) {
        }

        $xml = [xml](fnGetOS $_driverData.productSeriesId)
        $searchSuccess = $false
        if ($xml["LookupValueSearch"] -and $xml["LookupValueSearch"].LookupValues) {
            foreach ($item in $xml["LookupValueSearch"].LookupValues.ChildNodes) {
                if ($item -and ($osName -eq $item.Name)) {
                    $_driverData.operationSystemId = $item.Value
                    #$_driverData.productSeriesId = $item.Attributes["ParentID"].Value
                    $searchSuccess = $true
                    break
                }

            }
        }
        #endregion

        $url = $_driverData.GetSearchUrl()
        $response = Invoke-RestMethod -Method Get -Uri $url

        $htmlDoc = ConvertFrom-Html -Content $response
        $nodes = $htmlDoc.SelectNodes('//tr[@id="driverList"]')
        [System.Collections.ArrayList]$drivers = @()

        foreach ($item in $nodes) {
            $url = ""
            $version = ""
            $name = ""
            $node = $item.SelectSingleNode('td[@class="gridItem driverName"]//a')
            if ($node) {
                $url = $node.Attributes["href"].Value
                $name = $node.InnerText
            }
            $node = $item.SelectSingleNode('td[3]')
            if ($node) {
                $version = [System.Version]$node.InnerText
            }
            $drivers.Add(@{"version" = $version; "url" = $url; "name" = $name }) | Out-Null
        }
        if (($drivers -and $drivers.Count -gt 0) -or $step -ge 2) {
            break
        }
        if (-not $drivers -or $drivers.Count -eq 0) {
            if ($_driverData.dtcid -eq 1) {
                $_driverData.dtcid = 0
            }
            else {
                $step++
                $_driverData.dtcid = 1
            }
        }
    }
    if ( -not $drivers -or $drivers.Count -eq 0 ) {
        WriteLog "Can't find any driver for this video adapter." -Verbose
        return $true
    }
    $lastDriver = $drivers | Sort-Object { $_.version } -Descending | Select-Object -First 1
    $drvLastVersion = $lastDriver["version"]

    Write-Host $_driverData.productSeriesId | Select-Object *

    WriteLog "Installed driver version: $drvCurrentVersion, found $drvLastVersion version."

    if ($drvCurrentVersion -ge $drvLastVersion) {
        WriteLog "The installed version is the latest."
        $_driverUrl = $null
    }
    else {

        $_driverUrl = "https:{0}" -f $lastDriver["url"]

        [System.Uri]$url = "https:{0}" -f $lastDriver["url"]
        $_someSeed = $url.Segments[3] -replace "/", ""

        $_url01 = 'https://www.nvidia.com:/services/com.nvidia.services/AEMDriversContent/getDownloadDetails?{"ddID":"' + $_someSeed + '"}'

        $response = Invoke-RestMethod -Method Get -Uri $_url01
        $_downloadInfo = $response.driverDetails.IDS[0].downloadInfo
        $_driverUrl = $_downloadInfo.DownloadURL

        WriteLog "Last driver url $_driverUrl"
    }

    #endregion

    #region Download and install

    switch ($PSCmdlet.ParameterSetName) {
        'Check' {

            break
        }
        'Install' {
            if ($_driverUrl) {
                DownloadAndInstall -DriverUrl  $_driverUrl
            }
            break
        }
    }


    #return $true

    #endregion
}