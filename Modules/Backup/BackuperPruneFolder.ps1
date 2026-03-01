
Set-StrictMode -Version 3.0

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