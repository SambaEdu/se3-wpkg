:: WindowsXP-Windows2000-Script56-KB917344-x86-fra
:: ## $Id$ ##
@echo on

If Not Exist %WPKGROOT%\..\packages\windows\WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe Goto ErrNoFile

If Exist %WinDir%\Temp\WindowsXP-Windows2000-Script56-KB917344-x86-fra rmdir /S /Q %WinDir%\Temp\WindowsXP-Windows2000-Script56-KB917344-x86-fra
start /wait %WPKGROOT%\..\packages\windows\WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe /Q /T:%WinDir%\Temp\WindowsXP-Windows2000-Script56-KB917344-x86-fra /C
echo Decompression : CodeRetour=%ErrorLevel%
pushd %WinDir%\Temp\WindowsXP-Windows2000-Script56-KB917344-x86-fra

:: [Strings]
:: ; Unlocalizable strings
Set REG_WSH="Software\Microsoft\Windows Script Host"
Set REG_APPROVE="Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved"
Set REG_UNINSTALL="Software\Microsoft\Windows\CurrentVersion\Uninstall\WindowsScriptHost"
Set CLSID_WSHEXT="{60254CA5-953B-11CF-8C96-00AA00B8708C}"

Set ActiveSetupRegKey="SOFTWARE\Microsoft\Active Setup\Installed Components\{4f645220-306d-11d2-995d-00c04f98bbc9}"

:: ; Localizable strings
Set DISP_WSH="Microsoft Windows Script Host"

Set DESC_DOTWSH="Fichier des paramètres de Windows Script Host"
Set DESC_DOTVBS="Fichier script VBScript"
Set DESC_DOTJS="Fichier script JScript"
Set DESC_DOTWS="Fichier script Windows"

Set DESC_WSHEXT="Extension de l'interpréteur de commande pour Windows Script Host"

Set MENU_OPEN="&Ouvrir"
Set MENU_CONOPEN="Ouvrir &avec l'invite de commande"
Set MENU_DOSOPEN="&Ouvrir avec l'invite MS-DOS"
Set MENU_EDIT="&Modifier"
Set MENU_PRINT="&Imprimer"

Set VersionWarning=You need a newer version of advpack.dll.
Set Media=Windows Script Version 5.6
Set Msft="Microsoft"

Set Product="Microsoft Windows Script 5.6"
Set ExceptionClassDesc="Microsoft Windows Script 5.6 for Windows 2000"

Set LANG="FR"



:: [Version]
:: signature="$Windows NT$"
:: AdvancedINF=2.5,%VersionWarning%
Set Class=%ExceptionClassDesc%
Set ClassGUID={F5776D81-AE53-4935-8E84-B0B283D8BCEF}
Set Provider=%Msft%
Set CatalogFile=scriptfr.cat
Set ComponentId={4f645220-306d-11d2-995d-00c04f98bbc9}
Set DriverVer=05-19-2006, 5.6.0.8831

:: [DefaultInstall]
:: CopyFiles = Copy.ScriptFiles, Copy.WSH, Copy.Help, Copy.INF, DllCacheFiles
:: CustomDestination = CustomDests
:: RegisterOCXs = Register.Engines
:: AddReg = RegisterActiveSetup, AddReg.WSH, AddReg.Extensions.NT

:: [SourceDisksNames]
:: 1 = %Media%

:: [SourceDisksFiles]
:: jscript.dll 	= 1
:: vbscript.dll 	= 1
:: scrrun.dll		= 1
:: dispex.dll		= 1
:: scrobj.dll		= 1
:: wshom.ocx	= 1
:: wshext.dll	= 1
:: cscript.exe	= 1
:: wscript.exe	= 1
:: wshcon.dll	= 1
:: wscript.hlp	= 1
:: scriptfr.inf	= 1
:: jsfr.dll		= 1
:: scofr.dll		= 1
:: scrrnfr.dll		= 1
:: vbsfr.dll		= 1
:: wshfr.dll		= 1

:: [DestinationDirs]
:: DefaultDestDir 	 = 11		;windir\system32
:: Copy.ScriptFiles 	= 11		;windir\system32
:: Copy.WSH	 = 11		;windir\system32
:: Copy.Help 	 = 18		;windir\help
:: Copy.Inf	 	= 17		;windir\inf
:: DllCacheFiles 	 = 49000		;windir\system32\dllcache
Set DefaultDestDir=%windir%\system32
Set CopyScriptFiles=%windir%\system32
Set CopyWSH=%windir%\system32
Set CopyHelp=%windir%\help
Set CopyInf=%windir%\inf
Set DllCacheFiles=%windir%\system32\dllcache

:: [CustomDests]
:: 49000 = DllCacheLDID, 85

:: [DllCacheLDID]
:: HKLM,"Software\Microsoft\Windows NT\CurrentVersion\Winlogon","SfcDllCacheDir",,"%25%\system32\dllcache"
reg ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "SfcDllCacheDir" /d "%Windir%\system32\dllcache" /f >NUL

:: [Copy.ScriptFiles]
Set dest=%CopyScriptFiles%
copy /N /V /Y /B jscript.dll %dest% >NUL
copy /N /V /Y /B vbscript.dll %dest% >NUL
copy /N /V /Y /B scrrun.dll %dest% >NUL
copy /N /V /Y /B dispex.dll %dest% >NUL
copy /N /V /Y /B scrobj.dll %dest% >NUL
copy /N /V /Y /B jsfr.dll %dest% >NUL
copy /N /V /Y /B scofr.dll %dest% >NUL
copy /N /V /Y /B scrrnfr.dll %dest% >NUL
copy /N /V /Y /B vbsfr.dll %dest% >NUL

:: [Copy.WSH]
Set dest=%CopyWSH%
copy /N /V /Y /B wshom.ocx %dest% >NUL
copy /N /V /Y /B wshext.dll %dest% >NUL
copy /N /V /Y /B cscript.exe %dest% >NUL
copy /N /V /Y /B wscript.exe %dest% >NUL
copy /N /V /Y /B wshcon.dll %dest% >NUL
copy /N /V /Y /B wshfr.dll %dest% >NUL

:: [Copy.Help]
Set dest=%CopyHelp%
copy /N /V /Y /B wscript.hlp %dest% >NUL

:: [Copy.Inf]
Set dest=%CopyInf%
copy /N /V /Y /B scriptfr.inf %dest% >NUL

:: [DllCacheFiles]
Set dest=%DllCacheFiles%
copy /N /V /Y /B jscript.dll %dest% >NUL
copy /N /V /Y /B vbscript.dll %dest% >NUL
copy /N /V /Y /B scrrun.dll %dest% >NUL
copy /N /V /Y /B dispex.dll %dest% >NUL
copy /N /V /Y /B scrobj.dll %dest% >NUL
copy /N /V /Y /B wshext.dll %dest% >NUL
copy /N /V /Y /B cscript.exe %dest% >NUL
copy /N /V /Y /B wscript.exe %dest% >NUL
copy /N /V /Y /B wshom.ocx %dest% >NUL
copy /N /V /Y /B jsfr.dll %dest% >NUL
copy /N /V /Y /B scofr.dll %dest% >NUL
copy /N /V /Y /B scrrnfr.dll %dest% >NUL
copy /N /V /Y /B vbsfr.dll %dest% >NUL
copy /N /V /Y /B wshfr.dll %dest% >NUL

:: [Register.Engines]
regsvr32 /s %WinDir%\system32\jscript.dll >NUL
regsvr32 /s %WinDir%\system32\vbscript.dll >NUL
regsvr32 /s %WinDir%\system32\scrrun.dll >NUL
regsvr32 /s %WinDir%\system32\scrobj.dll >NUL
regsvr32 /s %WinDir%\system32\wshext.dll >NUL
regsvr32 /s %WinDir%\system32\wshcon.dll >NUL
regsvr32 /s %WinDir%\system32\wshom.ocx >NUL

:: [RegisterActiveSetup]
Set ActiveSetupRegKey="HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{4f645220-306d-11d2-995d-00c04f98bbc9}"
::reg ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "SfcDllCacheDir" /d "%Windir%\system32\dllcache"

reg ADD %ActiveSetupRegKey% /ve /d %Product% /f >NUL
reg ADD %ActiveSetupRegKey% /v "IsInstalled" /t REG_DWORD /d 1 /f >NUL
reg ADD %ActiveSetupRegKey% /v "Version" /d "5,6,0,8825" /f >NUL
reg ADD %ActiveSetupRegKey% /v "Locale" /d %Lang% /f >NUL
reg ADD %ActiveSetupRegKey% /v "ComponentID" /d "MSVBScript" /f >NUL

::;;;
::;;; Add WSH registry entries
::;;;
:: [AddReg.WSH]
Set REG_WSH="HKLM\Software\Microsoft\Windows Script Host\Settings"
reg ADD %REG_WSH% /v "DisplayLogo" /d "1" /f >NUL
reg ADD %REG_WSH% /v "ActiveDebugging" /d "1" /f >NUL
reg ADD %REG_WSH% /v "SilentTerminate" /d "0" /f >NUL
reg ADD %REG_WSH% /v "TrustPolicy" /t REG_DWORD /d 0 /f >NUL
reg ADD %REG_WSH% /v "LogSecurityFailures" /d "1" /f >NUL
reg ADD %REG_WSH% /v "LogSecuritySuccesses" /d "0" /f >NUL
reg ADD %REG_WSH% /v "Remote" /d "0" /f >NUL
reg ADD %REG_WSH% /v "Enabled" /d "1" /f >NUL
reg ADD %REG_WSH% /v "IgnoreUserSettings" /d "0" /f >NUL

:: ; Shell Extension
Set REG_APPROVE=Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved
Set CLSID_WSHEXT="{60254CA5-953B-11CF-8C96-00AA00B8708C}"
Set DESC_WSHEXT="Extension de l'interpreteur de commande pour Windows Script Host"
reg ADD "HKLM\%REG_APPROVE%" /v %CLSID_WSHEXT% /d %DESC_WSHEXT% /f >NUL

:: [AddReg.Extensions.NT]
:: ; Register WScript
reg ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "Regsister WScript" /d "wscript -regserver" /f >NUL

:: ; .WSH
reg ADD "HKCR\.WSH" /ve /d "WSHFile" /f >NUL
reg ADD "HKCR\WSHFile" /ve /d %DESC_DOTWSH% /f >NUL
reg ADD "HKCR\WSHFile" /d "IsShortcut" /v "Yes" /f >NUL
reg ADD "HKCR\WSHFile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%Windir%\system32\WScript.exe,1" /f >NUL
reg ADD "HKCR\WSHFile\Shell\Open" /ve /d %MENU_OPEN% /f >NUL
reg ADD "HKCR\WSHFile\Shell\Open\Command"  /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\WSHFile\Shell\Open2" /ve /d %MENU_CONOPEN% /f >NUL
reg ADD "HKCR\WSHFile\Shell\Open2\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\CScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\WSHFile\ShellEx\PropertySheetHandlers\WSHProps" /ve /d %CLSID_WSHEXT% /f >NUL
reg ADD "HKCR\WSHFile\ShellEx\DropHandler" /ve /d %CLSID_WSHEXT% /f >NUL

:: ; .VBS
reg ADD "HKCR\.VBS" /ve /d "VBSFile" /f >NUL
reg ADD "HKCR\VBSFile" /ve /d %DESC_DOTVBS% /f >NUL
reg ADD "HKCR\VBSFile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe /d 2" /f >NUL
reg ADD "HKCR\VBSFile\ScriptEngine" /ve /d "VBScript" /f >NUL
reg ADD "HKCR\VBSFile\Shell\Open" /ve /d %MENU_OPEN% /f >NUL
reg ADD "HKCR\VBSFile\Shell\Open\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\VBSFile\Shell\Open2" /ve /d %MENU_CONOPEN% /f >NUL
reg ADD "HKCR\VBSFile\Shell\Open2\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\CScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\VBSFile\Shell\Edit" /ve /d %MENU_EDIT% /f >NUL
reg ADD "HKCR\VBSFile\Shell\Edit\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe %1" /f >NUL
reg ADD "HKCR\VBSFile\Shell\Print" /ve /d %MENU_PRINT% /f >NUL
reg ADD "HKCR\VBSFile\Shell\Print\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe /p %1" /f >NUL
reg ADD "HKCR\VBSFile\ShellEx\PropertySheetHandlers\WSHProps" /ve /d %CLSID_WSHEXT% /f >NUL
reg ADD "HKCR\VBSFile\ShellEx\DropHandler" /ve /d %CLSID_WSHEXT% /f >NUL

:: ; .VBE
reg ADD "HKCR\.VBE" /ve /d "VBEFile" /f >NUL
reg ADD "HKCR\VBEFile" /ve /d %DESC_DOTVBS% /f >NUL
reg ADD "HKCR\VBEFile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe /d 2" /f >NUL
reg ADD "HKCR\VBEFile\ScriptEngine" /ve /d "VBScript.Encode" /f >NUL
reg ADD "HKCR\VBEFile\Shell\Open" /ve /d %MENU_OPEN% /f >NUL
reg ADD "HKCR\VBEFile\Shell\Open\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\VBEFile\Shell\Open2" /ve /d %MENU_CONOPEN% /f >NUL
reg ADD "HKCR\VBEFile\Shell\Open2\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\CScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\VBEFile\Shell\Edit" /ve /d %MENU_EDIT% /f >NUL
reg ADD "HKCR\VBEFile\Shell\Edit\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe %1" /f >NUL
reg ADD "HKCR\VBEFile\Shell\Print" /ve /d %MENU_PRINT% /f >NUL
reg ADD "HKCR\VBEFile\Shell\Print\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe /p %1" /f >NUL
reg ADD "HKCR\VBEFile\ShellEx\PropertySheetHandlers\WSHProps" /ve /d %CLSID_WSHEXT% /f >NUL
reg ADD "HKCR\VBEFile\ShellEx\DropHandler" /ve /d %CLSID_WSHEXT% /f >NUL

:: ; .JS
reg ADD "HKCR\.JS" /ve /d "JSFile" /f >NUL
reg ADD "HKCR\JSFile" /ve /d %DESC_DOTJS% /f >NUL
reg ADD "HKCR\JSFile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe /d 3" /f >NUL
reg ADD "HKCR\JSFile\ScriptEngine" /ve /d "JScript" /f >NUL
reg ADD "HKCR\JSFile\Shell\Open" /ve /d %MENU_OPEN% /f >NUL
reg ADD "HKCR\JSFile\Shell\Open\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\JSFile\Shell\Open2" /ve /d %MENU_CONOPEN% /f >NUL
reg ADD "HKCR\JSFile\Shell\Open2\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\CScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\JSFile\Shell\Edit" /ve /d %MENU_EDIT% /f >NUL
reg ADD "HKCR\JSFile\Shell\Edit\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe %1" /f >NUL
reg ADD "HKCR\JSFile\Shell\Print" /ve /d %MENU_PRINT% /f >NUL
reg ADD "HKCR\JSFile\Shell\Print\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe /p %1" /f >NUL
reg ADD "HKCR\JSFile\ShellEx\PropertySheetHandlers\WSHProps" /ve /d %CLSID_WSHEXT% /f >NUL
reg ADD "HKCR\JSFile\ShellEx\DropHandler" /ve /d %CLSID_WSHEXT% /f >NUL

:: ; .JSE
reg ADD "HKCR\.JSE" /ve /d "JSEFile" /f >NUL
reg ADD "HKCR\JSEFile" /ve /d %DESC_DOTJS% /f >NUL
reg ADD "HKCR\JSEFile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe /d 3" /f >NUL
reg ADD "HKCR\JSEFile\ScriptEngine" /ve /d "JScript.Encode" /f >NUL
reg ADD "HKCR\JSEFile\Shell\Open" /ve /d %MENU_OPEN% /f >NUL
reg ADD "HKCR\JSEFile\Shell\Open\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\JSEFile\Shell\Open2" /ve /d %MENU_CONOPEN% /f >NUL
reg ADD "HKCR\JSEFile\Shell\Open2\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\CScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\JSEFile\Shell\Edit" /ve /d %MENU_EDIT% /f >NUL
reg ADD "HKCR\JSEFile\Shell\Edit\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe %1" /f >NUL
reg ADD "HKCR\JSEFile\Shell\Print" /ve /d %MENU_PRINT% /f >NUL
reg ADD "HKCR\JSEFile\Shell\Print\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe /p %1" /f >NUL
reg ADD "HKCR\JSEFile\ShellEx\PropertySheetHandlers\WSHProps" /ve /d "%CLSID_WSHEXT%" /f >NUL
reg ADD "HKCR\JSEFile\ShellEx\DropHandler" /ve /d %CLSID_WSHEXT% /f >NUL

:: ; .WSF
reg ADD "HKCR\.WSF" /ve /d "WSFFile" /f >NUL
reg ADD "HKCR\WSFFile" /ve /d %DESC_DOTWS% /f >NUL
reg ADD "HKCR\WSFFile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe /d 2" /f >NUL
reg ADD "HKCR\WSFFile\Shell\Open" /ve /d %MENU_OPEN% /f >NUL
reg ADD "HKCR\WSFFile\Shell\Open\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\WScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\WSFFile\Shell\Open2" /ve /d %MENU_CONOPEN% /f >NUL
reg ADD "HKCR\WSFFile\Shell\Open2\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\CScript.exe \"%1\" %*" /f >NUL
reg ADD "HKCR\WSFFile\Shell\Edit" /ve /d %MENU_EDIT% /f >NUL
reg ADD "HKCR\WSFFile\Shell\Edit\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe %1" /f >NUL
reg ADD "HKCR\WSFFile\Shell\Print" /ve /d %MENU_PRINT% /f >NUL
reg ADD "HKCR\WSFFile\Shell\Print\Command" /ve /t REG_EXPAND_SZ /d "%SystemRoot%\system32\Notepad.exe /p %1" /f >NUL
reg ADD "HKCR\WSFFile\ShellEx\PropertySheetHandlers\WSHProps" /ve /d %CLSID_WSHEXT% /f >NUL
reg ADD "HKCR\WSFFile\ShellEx\DropHandler" /ve /d %CLSID_WSHEXT% /f >NUL

popd
rmdir /S /Q "%WinDir%\Temp\WindowsXP-Windows2000-Script56-KB917344-x86-fra"

Goto Done

:ErrNoFile
Echo Le fichier %WPKGROOT%\..\packages\windows\WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe est absent !
Echo   Installation impossible.

:Done