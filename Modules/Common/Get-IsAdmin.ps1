Set-StrictMode -Version 3.0


# .SYNOPSIS
#     is script runned under admin or not
# .DESCRIPTION
#     return $true if script runned under admin or $false if not
# .OUTPUTS
#     Author : Agitech   Version : 0.0.0.1
function Get-IsAdmin {
    $Principal = new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    [bool]$Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}