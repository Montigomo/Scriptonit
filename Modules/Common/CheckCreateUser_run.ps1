#Requires -RunAsAdministrator

Set-StrictMode -Version 3.0

function CheckCreateUser {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        [Parameter(Mandatory = $true)]
        [string]$UserPsw,
        [Parameter(Mandatory = $false)]
        [string]$Description
    )

    $SecurePassword = ConvertTo-SecureString $UserPsw -AsPlainText -Force

    if (!(Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $UserName -Description $Description -Password $SecurePassword | Out-Null
        Write-Host "Succesefully created user $UserName" -ForegroundColor DarkGreen
    }
    else {
        Set-LocalUser -Name $UserName -Password $SecurePassword | Out-Null
        Write-Host "User $UserName exist. Set credential for this." -ForegroundColor DarkGreen
    }
}