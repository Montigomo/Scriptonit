Set-StrictMode -Version 3.0

enum GpuType{
    Unknown = 0
    Nvidia = 1
    AMD = 2
    Intel = 3
}

#.SYNOPSIS
#.DESCRIPTION
#.PARAMETER ModuleName
#   [string] module name to install
#.INPUTS
#.OUTPUTS
#.EXAMPLE
#.EXAMPLE
#.LINK
#.NOTES
#   Author : Agitech   Version : 0.0.0.1
class GpuInfo {
    
    [GpuType]$GpuType    
    [string]$DeviceName
    [string]$VendorID
    [string]$DeviceID
    [string]$SubsystemID
    [string]$SigID
    [string]$Revision
    [System.Version]$CudaSDK = $null #[System.Version]::Parse("0.0")

    GpuInfo() {
        $this.Init()
    }
    
    Init() {
        $this.GpuType = [GpuType]::Unknown
        $_gpu = $null
        $_gpus = Get-CimInstance Win32_VideoController | Where-Object { $_.Status -ieq "ok" }
        if ($_gpu = $_gpus | Where-Object { $_.AdapterCompatibility -ilike "nvidia*" }) {
            $this.GpuType = [GpuType]::Nvidia
            $this.DeviceName = $_gpu.VideoProcessor -replace "NVIDIA ", ""
            $this.GetCudaSDK()
        }
        elseif ($_gpu = $_gpus | Where-Object { $_.AdapterCompatibility -ilike "advanced micro devices*" }) {
            $this.GpuType = [GpuType]::AMD
            # AMD Radeon Graphics Processor (0x1681) 
            $this.DeviceName = $_gpu.VideoProcessor

        }
        elseif ($_gpu = $_gpus | Where-Object { $_.AdapterCompatibility -ilike "intel corporation*" }) {
            $this.GpuType = [GpuType]::Intel
            $this.DeviceName = $_gpu.VideoProcessor
        }

        if ($_gpu.PNPDeviceID -match "PCI\\VEN_(?<vid>[0-9ABCDEF]{4})&DEV_(?<did>[0-9ABCDEF]{4})(&SUBSYS_(?<subid>[0-9ABCDEF]{4})(?<sigid>[0-9ABCDEF]{4}))?(&REV_(?<rev>[0-9ABCDEF]{2}))?") {
            $this.VendorID = $Matches["vid"]
            $this.DeviceID = $Matches["did"]
            $this.SubsystemID = $Matches["subid"]
            $this.SigID = $Matches["sigid"]
            $this.Revision = $Matches["rev"]
        }
        if ((($this.GpuType -eq [GpuType]::Nvidia) -and ($this.VendorID -ne "10DE")) -or `
            (($this.GpuType -eq [GpuType]::AMD) -and ($this.VendorID -ne "1002")) -or `
            ($this.GpuType -eq [GpuType]::Intel) -and ($this.VendorID -ne "8086")) {
            Write-Host "Error: GPU detection problem $($this.DeviceName), GpuType =  $($this.GpuType), vid = $($)this.VendorID)" -ForegroundColor Red
        }
        if($this.GpuType -eq [GpuType]::Nvidia){
            $this.GetCudaSDK()
        }

    }

    hidden GetCudaSDK () {
        $sdks = [ordered]@{
            "8.0"         = @("0F02");
            "9.2"         = @("FFFF");
            "10.2"        = @("11A1");
            "11.8"        = @("FFFF");
            "12.4"        = @("1C82")
        }

        $sdk_version = "8.0";

        foreach($key in $sdks.Keys){
            if($sdks[$key] -icontains $this.DeviceID){
                $sdk_version = $key
            }
        }

        $sdk_version = [System.Version]::Parse($sdk_version);
        $this.CudaSDK = $sdk_version
    }
}