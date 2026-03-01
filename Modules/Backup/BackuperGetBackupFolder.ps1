
Set-StrictMode -Version 3.0

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