Set-StrictMode -Version 3.0

#.synopsis
#     Register Notepad++ as default for notepad.Execution
# .description
#     This script modifies the Windows registry to redirect notepad.exe to Notepad++.
# .parameter ProgramFolder
#   [string] The folder where Notepad++ is installed.
# .parameter Register
#   [switch] If specified, registers the NppShell.dll for context menu integration.
# .notes
#
function NppRegisterImageFileExecutionOptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProgramFolder
    )
    $path = "$ProgramFolder\notepad++.exe"
    $regString = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe]
"UseFilter"=dword:00000001
"Debugger"="\"${path}\" -notepadStyleCmdline -z"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\0]
"AppExecutionAliasRedirect"=dword:00000001
"AppExecutionAliasRedirectPackages"="*"
"FilterFullPath"="${path}"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\1]
"AppExecutionAliasRedirect"=dword:00000001
"AppExecutionAliasRedirectPackages"="*"
"FilterFullPath"="${path}"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\2]
"AppExecutionAliasRedirect"=dword:00000001
"AppExecutionAliasRedirectPackages"="*"
"FilterFullPath"="${path}"
"@

    $tmp = New-TemporaryFile
    $regString | Out-File $tmp
    reg import $tmp.FullName

}
