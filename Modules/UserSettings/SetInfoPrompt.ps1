
function SetInfoPrompt {
    function SetPropmt_inner {
        $_profilePath = $PROFILE.CurrentUserAllHosts

        Write-Host "Function SetPropmt started. Powershell version - $($PSVersionTable.PSVersion)." -ForegroundColor Green
        Write-Host "Profile path - $_profilePath" -ForegroundColor DarkYellow

        if (!$_profilePath) {
            Write-Host 'Error profile path $_profilePath value.' -ForegroundColor Red
            return
        }

        if (!(Test-Path -Path $_profilePath)) {
            New-Item -ItemType File -Path $_profilePath -Force  | Out-Null
        }

        $_string =
        @'
$_pcName = $env:COMPUTERNAME
$_userName = $env:USERNAME
$Host.UI.RawUI.WindowTitle = "$_pcName - $_userName"
'@
        Add-Content -Path $_profilePath -Value $_string | Out-Null
    }

    $FunctionDefinition = Get-Command -Name 'SetPropmt_inner' -CommandType Function

    if($FunctionDefinition){
        Write-Host "Can't find function definition." -ForegroundColor DarkYellow
        return
    }

    $ScriptBlock = $FunctionDefinition.ScriptBlock

    powershell.exe -command $ScriptBlock

    pwsh.exe  -command $ScriptBlock

}