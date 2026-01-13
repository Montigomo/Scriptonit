#Requires -RunAsAdministrator

Set-StrictMode -Version 3.0

function CreateLocalUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        [Parameter(Mandatory = $true)]
        [string]$Pwd
    )
    $Description = "WebDav user $UserName"
    $SecurePassword = ConvertTo-SecureString $Pwd -AsPlainText -Force
    # Проверка наличия учетной записи
    if (!(Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $UserName -Description $Description -Password $SecurePassword -AccountNeverExpires
    }
    else {
        Set-LocalUser -Name $UserName -Password $SecurePassword
    }
}