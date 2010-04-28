:: Ce script permet de réorganiser les menus démarrer de All Users par les installations wpkg, de supprimer les raccourcis lors du remove
:: Auteur : Olivier Lacroix

@echo off
if ""=="%Z%" set Z=Y:\unattended\install
:: mettre DEBUG=1 pour afficher des logs
SET DEBUG=0

:: regeneration locale de la correspondance ID du package<-> Category
pushd %Z%\wpkg
if "%DEBUG%"=="1" echo Analyse des Category dans packages.xml
cscript %Z%\wpkg\AnalyseCategory.js > NUL
Set raccprogstoclass=%systemdrive%\netinst\PackagesCategory.txt
Set raccpersotag=%systemdrive%\netinst\PackagesCategoryPerso.tag

SET ARGUN=%1
SET ARGDEUX=%2
:: patch pour gerer les raccourcis contenant des espaces: on vire les guillemets
SET PACKAGE=%ARGUN:"=%
SET DOSSIERLNK=%ARGDEUX:"=%

if "%DEBUG%"=="1" echo # REORGANISATION DU MENU DEMARRER pour le programme %PACKAGE% #

if "%ALLUSERSPROFILE%"=="" Set ALLUSERSPROFILE="C:\Documents and Settings\All Users"

%Z%\wpkg\tools\reg.exe query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Common Programs" | find /I "Common Programs" > c:\tmp.txt
CHCP 1252 > NUL
	for /F "tokens=2* delims=	" %%a in (c:\tmp.txt) do (
	CHCP 850 > NUL
	if exist "%%b" set MenuDemarrer=%%b&& if "%DEBUG%"=="1" echo Le menu demarrer de AllUsers est dans %%b
)

if exist "%raccpersotag%" del /F "%raccpersotag%" > NUL
SET raccprogstoclassperso=%Z%\packages\windows\PackagesCategory.txt

IF "%3"=="remove" goto remove

:: Prise en compte d'un fichier de correspondance pour personnaliser 
if "%DEBUG%"=="1" echo Examen de %raccprogstoclassperso% pour rangement perso de %DOSSIERLNK% dans AllUsers
for /F "tokens=1,2 delims=;" %%a in (%raccprogstoclassperso%) do (
	if "%%a"=="%PACKAGE%" (
		if "%DEBUG%"=="1" echo ID: %%a Category: %%b
		if exist "%MenuDemarrer%\%DOSSIERLNK%" (
			if "%DEBUG%"=="1" echo "%MenuDemarrer%\%DOSSIERLNK%" existe : on le deplace si la category est renseignee.
			if not "%%a"=="" if not "%%b"=="" (
				if not exist "%MenuDemarrer%\%%b" echo Creation du dossier %%b&& mkdir "%MenuDemarrer%\%%b"
				if exist "%MenuDemarrer%\%%b\%DOSSIERLNK%" (
					echo La destination "%MenuDemarrer%\%%b\%DOSSIERLNK%" existe. On la supprime pour remplacement.
					dir "%MenuDemarrer%\%%b\%DOSSIERLNK%" | findstr /I "<REP>" >NUL
					if errorlevel 1 (
						if "%DEBUG%"=="1" echo Suppression du raccourci %%b\%DOSSIERLNK%
						del /F /S "%MenuDemarrer%\%%b\%DOSSIERLNK%"
					) ELSE (
						if "%DEBUG%"=="1" echo Suppression du dossier %%b\%DOSSIERLNK%
						rd /S /Q "%MenuDemarrer%\%%b\%DOSSIERLNK%"
					)
				)
				echo Rangement personnalise du fichier-dossier %DOSSIERLNK% de l'application %%a vers la categorie %%b
				move /Y "%MenuDemarrer%\%DOSSIERLNK%" "%MenuDemarrer%\%%b\"
				echo OK > "%raccpersotag%"
			)
		) ELSE (
			echo "%MenuDemarrer%\%DOSSIERLNK%" n existe pas. Bizarre.
		)
	)
)

:: On teste si le raccourci a deja ete classe a l'aide du fichier personnalise. Si oui, on s'arrete la.
if exist "%raccpersotag%" goto END
if "%DEBUG%"=="1" echo Action par defaut : aucune correspondance n'a ete trouvee dans %raccprogstoclassperso%

:: Debut de l'action officielle : classement dans le nom de la category par defaut
if "%DEBUG%"=="1" echo Rangement de %DOSSIERLNK% par categories dans AllUsers
for /F "tokens=1,2 delims=;" %%a in (%raccprogstoclass%) do (
	if "%%a"=="%PACKAGE%" (
		if "%DEBUG%"=="1" echo ID: %%a Category: %%b
		if exist "%MenuDemarrer%\%DOSSIERLNK%" (
			if "%DEBUG%"=="1" echo "%MenuDemarrer%\%DOSSIERLNK%" existe : on le deplace si la category est renseignee.
			if not "%%a"=="" if not "%%b"=="" (
				if not exist "%MenuDemarrer%\%%b" echo Creation du dossier %%b&& mkdir "%MenuDemarrer%\%%b"
				if exist "%MenuDemarrer%\%%b\%DOSSIERLNK%" (
					echo La destination "%MenuDemarrer%\%%b\%DOSSIERLNK%" existe. On la supprime pour remplacement.
					dir "%MenuDemarrer%\%%b\%DOSSIERLNK%" | findstr /I "<REP>" >NUL
					if errorlevel 1 (
						if "%DEBUG%"=="1" echo Suppression du raccourci %%b\%DOSSIERLNK%
						del /F /S "%MenuDemarrer%\%%b\%DOSSIERLNK%"
					) ELSE (
						if "%DEBUG%"=="1" echo Suppression du dossier %%b\%DOSSIERLNK%
						rd /S /Q "%MenuDemarrer%\%%b\%DOSSIERLNK%"
					)
				)
				echo Rangement du fichier-dossier %DOSSIERLNK% de l'application %%a vers la categorie %%b
				move /Y "%MenuDemarrer%\%DOSSIERLNK%" "%MenuDemarrer%\%%b\"
			)
		) ELSE (
			echo "%MenuDemarrer%\%DOSSIERLNK%" n existe pas. Bizarre.
		)
	)
)

goto END

:remove
:: Classement perso par Category
if "%DEBUG%"=="1" echo Suppression automatique de %DOSSIERLNK% du package %PACKAGE% : rangement personnalise. Examen de %raccprogstoclassperso%
for /F "tokens=1,2 delims=;" %%a in (%raccprogstoclassperso%) do (
	if "%%a"=="%PACKAGE%" (
		if "%DEBUG%"=="1" echo ID: %%a Category: %%b
		if exist "%MenuDemarrer%\%%b\%DOSSIERLNK%" (
			echo "%MenuDemarrer%\%%b\%DOSSIERLNK%" existe : on le supprime.
			if not "%%a"=="" if not "%%b"=="" (
				dir "%MenuDemarrer%\%%b\%DOSSIERLNK%" | findstr /I "<REP>" >NUL
				if errorlevel 1 (
					if "%DEBUG%"=="1" echo Suppression du raccourci obsolete %%b\%DOSSIERLNK%
					del /F /S "%MenuDemarrer%\%%b\%DOSSIERLNK%"
				) ELSE (
					if "%DEBUG%"=="1" echo Suppression du dossier obsolete %%b\%DOSSIERLNK%
					rd /S /Q "%MenuDemarrer%\%%b\%DOSSIERLNK%"
				)
				if "%DEBUG%"=="1" echo Suppression de la categorie "%MenuDemarrer%\%%b" si vide.
				dir /B "%MenuDemarrer%\%%b" | find /V "" >NUL || rd /S /Q "%MenuDemarrer%\%%b"
			)
		)
	)
)

:: Classement officiel par Category
if "%DEBUG%"=="1" echo Suppression automatique de %DOSSIERLNK% du package %PACKAGE% : rangement officiel. Examen de %raccprogstoclass%
for /F "tokens=1,2 delims=;" %%a in (%raccprogstoclass%) do (
	if "%%a"=="%PACKAGE%" (
		if "%DEBUG%"=="1" echo ID: %%a Category: %%b
		if exist "%MenuDemarrer%\%%b\%DOSSIERLNK%" (
			echo "%MenuDemarrer%\%%b\%DOSSIERLNK%" existe : on le supprime.
			if not "%%a"=="" if not "%%b"=="" (
				dir "%MenuDemarrer%\%%b\%DOSSIERLNK%" | findstr /I "<REP>" >NUL
				if errorlevel 1 (
					if "%DEBUG%"=="1" echo Suppression du raccourci obsolete %%b\%DOSSIERLNK%
					del /F /S "%MenuDemarrer%\%%b\%DOSSIERLNK%"
				) ELSE (
					if "%DEBUG%"=="1" echo Suppression du dossier obsolete %%b\%DOSSIERLNK%
					rd /S /Q "%MenuDemarrer%\%%b\%DOSSIERLNK%"
				)
				if "%DEBUG%"=="1" echo Suppression de la categorie "%MenuDemarrer%\%%b" si vide.
				dir /B "%MenuDemarrer%\%%b" | find /V "" >NUL || rd /S /Q "%MenuDemarrer%\%%b"
			)
		)
	)
)

:END
CHCP 850 > NUL
