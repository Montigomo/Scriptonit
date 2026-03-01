
Set-StrictMode -Version 3.0

function BackuperMakeBackup {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ConfigPath,
		[Parameter(Mandatory = $false)]
		[string]$ServerName,
		[Parameter(Mandatory = $false)]
		[switch]$Auto,
		[Parameter(Mandatory = $false)]
		[switch]$SimpleOutput
	)

	$_objects = LmGetObjects -ConfigPath @($ConfigPath, "*")

	if ($_objects -and $ServerName) {
		$_objects = $_objects | Where-Object { $_.servername -eq $ServerName }
	}

	if (-not $_objects) {
		Write-Host "Not any objects to process." -ForegroundColor DarkYellow
		return
	}

	foreach ($_object in $_objects) {
		$_servername = $_object["servername"]
		$_hostIp = $_object["ip"]
		$_userName = $_object["username"]
		$_output_folder = BackuperGetObjectPropertyValue -Object $_object -Property "output_folder"
		$_token = BackuperGetObjectPropertyValue -Object $_object -Property "output_folder_token"
		$_outputFolder = BackuperGetBackupFolder -Folder $_output_folder -Token $_token -Auto:$Auto
		Write-Host "Starting backup. " -ForegroundColor DarkBlue -NoNewline
		Write-Host "ServerName: " -ForegroundColor DarkGreen -NoNewline
		Write-Host "$_servername, " -ForegroundColor DarkYellow -NoNewline
		Write-Host "IP: " -ForegroundColor DarkGreen -NoNewline
		Write-Host "$_hostIp, " -ForegroundColor DarkYellow -NoNewline
		Write-Host "UserName: " -ForegroundColor DarkGreen -NoNewline
		Write-Host "$_userName, " -ForegroundColor DarkYellow -NoNewline
		Write-Host "OutputFolder: " -ForegroundColor DarkGreen -NoNewline
		Write-Host "$_outputFolder, " -ForegroundColor DarkYellow

		$result = Test-RemotePort -IPAddress $_hostIp -Port 22 -TimeoutMilliSec 3000

		if ($result.Response) {
			$_files = $_object["files"]
			foreach ($_file in $_files) {
				if ($_file.StartsWith("###")) {
					continue
				}
				if (-not (CheckRemoteFileExist -HostIp $_hostIp -UserName $_userName -FilePath $_file)) {
					#Write-Host "Remote file $_file does not exist on $_hostIp. Skipping backup." -ForegroundColor DarkYellow
					continue
				}
				#$host_str = "$_userName@$($_hostIp)"
				$source_str = "$_userName@$($_hostIp):$_file"
				$dest_str = Join-Path "$_outputFolder" $_file
				$dest_str = [System.IO.Path]::GetDirectoryName($dest_str)
				New-Item -ItemType Directory -Force -Path $dest_str -ErrorAction SilentlyContinue | Out-Null
				scp -rp "$source_str" "$dest_str"
			}
		}
		else {
			Write-Host "Can't connect to $_servername." -ForegroundColor DarkRed
		}
	}

}
