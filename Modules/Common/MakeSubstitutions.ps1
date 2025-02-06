Set-StrictMode -Version 3.0

function MakeSubstitutions {
    param (
        [Parameter(Mandatory = $true)][string]$SubsString
    )

    $Substitutions = @{
        "UserName" = [Environment]::UserName
        "UserProfile" = "$([System.Environment]::GetFolderPath("UserProfile"))"
        "DateTimeStamp" = [System.String]::Format("{0:yyyy_MM_dd_HH_mm_ss}", [System.DateTime]::Now)
    }

    foreach ($subs_key in $Substitutions.Keys) {
        $subs_value = $Substitutions[$subs_key]
        $SubsString = $SubsString.Replace("<?$($subs_key)?>", $subs_value)
    }
    return $SubsString
}