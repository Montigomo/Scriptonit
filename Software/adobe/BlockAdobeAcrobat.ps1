#Requires -RunAsAdministrator

. "D:\software\scripts\FirewallRuleset.ps1"

. "D:\software\scripts\SetHosts.ps1"

#ImportFirewallRuleset -ConfigPath "firewall", "AdobeAcrobat" -Force

DeleteFirewallRuleset -ConfigPath "firewall", "AdobeAcrobat" -Force

PrepareHosts -ConfigPath "hosts", "Adobe"