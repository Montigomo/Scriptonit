
Set-StrictMode -Version 3.0

function BackuperPruneNetwork {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ConfigPath,
		[Parameter(Mandatory = $false)]
		[int]$Deep = 7,
		[Parameter(Mandatory = $false)]
		[switch]$Auto
	)

	$_objects = LmGetObjects -ConfigPath @($ConfigPath, "*")

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