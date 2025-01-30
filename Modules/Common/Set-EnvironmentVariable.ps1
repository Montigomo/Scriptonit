Set-StrictMode -Version 3.0


# .SYNOPSIS
#     Set environment variable 
# .DESCRIPTION
# .PARAMETER Value
#     [string] Environment variable value
# .PARAMETER Name
#     [string] Environment variable name [ValidateSet('Path', 'PSModulePath')]
# .PARAMETER Scope
#     [string] Scope  [ValidateSet('User', 'Process', 'Machine')]
# .PARAMETER Action
#     [string] Action [ValidateSet('Add', 'Remove')]
# .INPUTS
# .OUTPUTS
# .EXAMPLE
#     Set-EnvironmentVariable -Name 'Path' -Value "C:\Program Files\Git\usr\bin" -Action Add -Scope Machine
#     Set-EnvironmentVariable -Name 'Path' -Scope 'Machine' -Value "C:\Program Files\Far Manager" -Action "Remove"
# .LINK
# .NOTES
#     Author: Agitech; Version: 0.0.0.1
function Set-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Value,
        [Parameter(Mandatory = $false)][ValidateSet('Path', 'PSModulePath')][string] $Name = "Path",
        [Parameter(Mandatory = $false)][ValidateSet('User', 'Process', 'Machine')][string] $Scope = "User",
        [Parameter(Mandatory = $false)][ValidateSet('Add', 'Remove')][string] $Action = "Add"
    )
  
    switch ($Action) {        
        "Add" {
            $items = [Environment]::GetEnvironmentVariable($Name, $Scope).Split(";")
            if (!($items.Contains($Value))) {
                $items = $items + "$Value"
                $NewItem = $items -join ";"
                [Environment]::SetEnvironmentVariable($Name, $NewItem, $Scope)
            }
        }
        "Remove" {
            $items = [Environment]::GetEnvironmentVariable($Name, $Scope).Split(";")
            $oevNew = ($items -notlike $Value -notlike "" -join ";")
            [Environment]::SetEnvironmentVariable($Name, $oevNew, $Scope) 
        }     
    }
}