function Set-Shortcut {
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Arguments,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$LinkPath,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Description,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$IconLocation,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Hotkey
    )
    begin {
        $shell = New-Object -ComObject WScript.Shell
    }

    process {
        $link = $shell.CreateShortcut($LinkPath)
        $PSCmdlet.MyInvocation.BoundParameters.GetEnumerator() |
        Where-Object {
            $_.key -ne 'LinkPath' } |
        ForEach-Object {
            $link.$($_.key) = $_.value
        }
        $link.Save()
    }
}