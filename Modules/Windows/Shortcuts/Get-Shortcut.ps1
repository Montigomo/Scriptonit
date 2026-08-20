function Get-Shortcut {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )
    if (-not (Test-Path $path)) {
        return
    }
    $obj = New-Object -ComObject WScript.Shell
    $link = $obj.CreateShortcut($path)
    $info = @{
        Hotkey       = $link.Hotkey
        TargetPath   = $link.TargetPath
        LinkPath     = $link.FullName
        Arguments    = $link.Arguments
        WindowStyle  = $link.WindowStyle
        IconLocation = $link.IconLocation
    }
    #$info.Target = try { Split-Path $info.TargetPath -Leaf } catch { 'n/a' }
    #$info.Link = try { Split-Path $info.LinkPath -Leaf } catch { 'n/a' }
    [pscustomobject]$info
}

#$r = Get-Shortcut -Path 'D:\_users\agite\Desktop\Network adapters.lnk'


#exit