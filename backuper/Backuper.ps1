#--Requires -Version 6.0
#--Requires -PSEdition Core
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Work')]
param (
	[Parameter(Mandatory = $false, ParameterSetName = 'Work')]
	[Parameter(Mandatory = $false, ParameterSetName = 'ListServers')]
	[string]$NetworkName,
	[Parameter(Mandatory = $false, ParameterSetName = 'ListServers')]
	[switch]$ListServers
)

Set-StrictMode -Version 3.0

. "$PSScriptRoot\..\Modules\LoadModule.ps1" -ModuleNames @("Common", "Network") -Force | Out-Null


#region BackuperListServers BackuperGetBackupFolder
function BackuperListServers {
	param (
		[Parameter(Mandatory = $true)]
		[string]$NetworkName
	)
	LmListObjects -ConfigPath "networks", "$NetworkName", "backuper", "*" -PropertyName "servername"

}

function BackuperGetObjectPropertyValue {
	param(
		[Parameter(Mandatory = $true)]
		[hashtable]$Object,
		[Parameter(Mandatory = $true)]
		[string]$Property
	)
	$_ret_value = $null
	if ($Object.ContainsKey("$Property")) {
		$_ret_value = $_object["$Property"]
	}
	return $_ret_value
}

function BackuperGetBackupFolder {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Folder,
		[Parameter(Mandatory = $false)]
		[string]$Token,
		[Parameter(Mandatory = $false)]
		[switch]$Auto,
		[Parameter(Mandatory = $false)]
		[switch]$Parent
	)
	if ([System.String]::IsNullOrWhiteSpace($Folder)) {
		return $null
	}
	$_outputFolder = $Folder
	if ($Auto) {
		$_outputFolder = [System.IO.Path]::Combine($_outputFolder, "_auto")
	}
	if ($Parent -or [System.String]::IsNullOrWhiteSpace($Token)) {
		return $_outputFolder
	}
	$_token = MakeSubstitutions -SubsString $Token
	$_outputFolder = [System.IO.Path]::Combine($_outputFolder, $_token)
	return $_outputFolder
}

#endregion

#region BackuperPruneFolder
function BackuperPruneFolder {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Folder,
		[Parameter(Mandatory = $false)]
		[int]$Deep = 7,
		[Parameter(Mandatory = $false)]
		[switch]$Auto
	)
	#yyyy_MM_dd_HH_mm_ss
	$_items = Get-ChildItem -Path $Folder -Directory
	$objects = $_items | ForEach-Object {
		$dateTimeObject = $null

		if ($_.Name -match '^(?<date>\d{4}_\d{2}_\d{2}_\d\d_\d\d_\d\d)') {
			# $year = $Matches['date'].Substring(0,4)
			# $month = $Matches['date'].Substring(5,2)
			# $day = $Matches['date'].Substring(8,2)
			$dateTimeObject = [datetime]::parseexact($Matches['date'], 'yyyy_MM_dd_HH_mm_ss', [Globalization.CultureInfo]::InvariantCulture)
		}
		elseif ($_.Name -match '^(?<date>\d{4}-\d{2}-\d{2} \d\d_\d\d_\d\d)') {
			$dateTimeObject = [datetime]::parseexact($Matches['date'], 'yyyy-MM-dd HH_mm_ss', [Globalization.CultureInfo]::InvariantCulture)
		}
		elseif ($_.Name -match '^(?<date>\d{4}-\d{2}-\d{2}-\d\d_\d\d_\d\d)') {
			$dateTimeObject = [datetime]::parseexact($Matches['date'], 'yyyy-MM-dd-HH_mm_ss', [Globalization.CultureInfo]::InvariantCulture)
		}

		[PSCustomObject]@{
			Path = $_.FullName
			Name = $_.Name
			Date = $dateTimeObject
		}
	}
	if ($objects | Where-Object { $null -eq $_.Date }) {
		Write-Host "Not all folder date was parsed." -ForegroundColor DarkRed
		return
	}
	$objects = $objects | Sort-Object Date -Descending
	$objects = $objects | Group-Object -Property { $_.Date.ToString('yyyy-MM-dd') }
	$objects = $objects | ForEach-Object {
		$_.Group | Sort-Object Date -Descending | Select-Object -First 1
	}
	$objects = $objects | Sort-Object Date -Descending | Select-Object -First $Deep
	foreach ($_item in $_items) {
		if ($objects.Path -notcontains $_item.FullName) {
			Write-Host "Removing file: $($_item.FullName)"
			Remove-Item -Path $_item.FullName -Force -Recurse
		}
	}
}
#endregion


#region BackuperPruneNetwork

function BackuperPruneNetwork {
	param (
		[Parameter(Mandatory = $true)]
		[string]$NetworkName,
		[Parameter(Mandatory = $false)]
		[int]$Deep = 7,
		[Parameter(Mandatory = $false)]
		[switch]$Auto
	)

	$_objects = LmGetObjects "networks", "$NetworkName", "backuper", "*"

	if (-not $_objects) {
		Write-Host "Not any objects to process." -ForegroundColor DarkYellow
		return
	}

	foreach ($_object in $_objects) {
		$_servername = $_object["servername"]
		$_outputFolder = BackuperGetBackupFolder -Folder $_object["output_folder"] -Auto:$Auto -Parent
		if ( $null -eq $_outputFolder) {
			Write-Host "Output folder$_outputFolder is null. Skipping pruning." -ForegroundColor DarkYellow
			continue
		}
		if (-not (Test-Path $_outputFolder -PathType Container)) {
			Write-Host "Output $_outputFolder does not exist. Skipping pruning." -ForegroundColor DarkYellow
			continue
		}
		Write-Host "Pruning backup folder for server: " -ForegroundColor DarkBlue -NoNewline
		Write-Host "$_servername, " -ForegroundColor DarkYellow -NoNewline
		Write-Host "OutputFolder: " -ForegroundColor DarkGreen -NoNewline
		Write-Host "$_outputFolder" -ForegroundColor DarkYellow

		BackuperPruneFolder -Folder $_outputFolder -Deep $Deep
	}

}


#endregion


#region BackuperMakeBackup

function BackuperMakeBackup {
	param (
		[Parameter(Mandatory = $true)]
		[string]$NetworkName,
		[Parameter(Mandatory = $false)]
		[string]$ServerName,
		[Parameter(Mandatory = $false)]
		[switch]$Auto,
		[Parameter(Mandatory = $false)]
		[switch]$SimpleOutput
	)

	$_objects = LmGetObjects "networks", "$NetworkName", "backuper", "*"

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
			Write-Host "Can't connect to $key." -ForegroundColor DarkYellow
		}
	}

}

#endregion


if ($PSBoundParameters.Count -gt 0) {
	$params = $PSBoundParameters
	switch ($PSCmdlet.ParameterSetName) {
		'Work' {
			BackuperMakeBackup @params
			break
		}
		'ListServers' {
			BackuperListServers
			break
		}
	}
}
