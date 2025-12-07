Set-StrictMode -Version 3.0


function SetContextMenu {

    $regString = @"
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1]

[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell]

[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit]
"NoSmartScreen"=""

[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\Edit\Command]
@="\"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell_ise.exe\" \"%1\""


[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunPowershell5]
@="Run with Powershell 5"

[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunPowershell5\Command]
@="\"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" \"-Command\" \"if((Get-ExecutionPolicy ) -ne 'AllSigned') { Set-ExecutionPolicy -Scope Process Bypass }; & '%1'\""


[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunPowershell5AsAdmin]
@="Run with Powershell 5 as admin"

[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunPowershell5AsAdmin\command]
@="\"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" \"-Command\" \"\"& {Start-Process PowerShell.exe -ArgumentList '-ExecutionPolicy RemoteSigned -File \\\"%1\\\"' -Verb RunAs}\""


[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunPowershell7]
@="Run with Powershell 7"

[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunPowershell7\Command]
@="C:\\Program Files\\PowerShell\\7\\pwsh.exe -Command \"if((Get-ExecutionPolicy ) -ne 'AllSigned') { Set-ExecutionPolicy -Scope Process Bypass }; & '%1'\""


[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunPowershell7AsAdmin]
@="Run with Powershell 7 as admin"

[HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunPowershell7AsAdmin\Command]
@="\"C:\\Program Files\\PowerShell\\7\\pwsh.exe\" \"-Command\" \"\"& {Start-Process pwsh.exe -ArgumentList '-ExecutionPolicy RemoteSigned -File \\\"%1\\\"' -Verb RunAs}\""
"@

    $tmp = New-TemporaryFile
    $regString | Out-File $tmp
    reg import $tmp.FullName
}