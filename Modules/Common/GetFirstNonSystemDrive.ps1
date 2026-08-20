

function GetFirstNonSystemDrive {
    $sysDrive = (Get-WmiObject Win32_OperatingSystem).SystemDrive
    $drives = (Get-PSDrive -PSProvider FileSystem | Where-Object Name -ne 'Temp').Root | Sort-Object
    $drive = $drives | ForEach-Object { $_.Replace(":\", ":") } | Where-Object { $_ -ne "$sysDrive" } | Select-Object -First 1
    return $drive
}