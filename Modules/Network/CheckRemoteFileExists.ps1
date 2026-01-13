Set-StrictMode -Version 3.0

function CheckRemoteFileExist {
	param (
		[Parameter(Mandatory = $true)]
		[string]$HostIp,
		[Parameter(Mandatory = $true)]
		[string]$UserName,
		[Parameter(Mandatory = $true)]
		[string]$FilePath
	)

	#$sshCommand = "ssh -o BatchMode=yes -o ConnectTimeout=5 $UserName@$HostIp 'test -e `"$FilePath`" && echo exists || echo notexists'"

	$sshCommand = "ssh -o BatchMode=yes -o ConnectTimeout=5 $UserName@$HostIp 'if ls $FilePath 1> /dev/null 2>&1; then echo exists; else echo notexist; fi'"

	$result = Invoke-Expression -Command $sshCommand 2>$null

	if ($result -eq "exists") {
		return $true
	}
	else {
		return $false
	}
}