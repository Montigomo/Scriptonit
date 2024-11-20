

#winget remove --id MSIX\Microsoft.WindowsNotepad_11.2407.8.0_x64__8wekyb3d8bbwe

# reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" /v "Debugger" /t REG_SZ /d """D:\tools\software\notepad++\notepad++.exe"" -notepadStyleCmdline -z" /f
# reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\0" /v "FilterFullPath" /t REG_SZ /d "D:\tools\software\notepad++\notepad++.exe" /f
# reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\1" /v "FilterFullPath" /t REG_SZ /d "D:\tools\software\notepad++\notepad++.exe" /f
# reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\2" /v "FilterFullPath" /t REG_SZ /d "D:\tools\software\notepad++\notepad++.exe" /f


# reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" /v "Debugger" /t REG_SZ /d "\"%ProgramFiles%\Notepad++\notepad++.exe\" -notepadStyleCmdline -z" /f
# reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\0" /v "FilterFullPath" /t REG_SZ /d "%ProgramFiles%\Notepad++\notepad++.exe" /f
# reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\1" /v "FilterFullPath" /t REG_SZ /d "%ProgramFiles%\Notepad++\notepad++.exe" /f
# reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\2" /v "FilterFullPath" /t REG_SZ /d "%ProgramFiles%\Notepad++\notepad++.exe" /f

$path = "D:\\tools\\software"
$regString = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe]
"UseFilter"=dword:00000001
"Debugger"="\"${path}\\notepad++\\notepad++.exe\" -notepadStyleCmdline -z"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\0]
"AppExecutionAliasRedirect"=dword:00000001
"AppExecutionAliasRedirectPackages"="*"
"FilterFullPath"="${path}\\notepad++\\notepad++.exe"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\1]
"AppExecutionAliasRedirect"=dword:00000001
"AppExecutionAliasRedirectPackages"="*"
"FilterFullPath"="${path}\\notepad++\\notepad++.exe"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe\2]
"AppExecutionAliasRedirect"=dword:00000001
"AppExecutionAliasRedirectPackages"="*"
"FilterFullPath"="${path}\\notepad++\\notepad++.exe"
"@

$tmp = New-TemporaryFile
$regString | Out-File $tmp
reg import $tmp.FullName