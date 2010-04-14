:: Ce script permet de réorganiser les menus démarrer de All Users par les installations wpkg, de supprimer les raccourcis lors du remove
@echo off
if ""=="%Z%" set Z=Y:\unattended\install

:: regeneration locale de la correspondance ID du package<-> Category
pushd %Z%\wpkg
echo Analyse des Category dans packages.xml
cscript %Z%\wpkg\AnalyseCategory.js
Set raccprogstoclass=%systemdrive%\netinst\PackagesCategory.txt

SET PACKAGE=%1
SET DOSSIERLNK=%2
echo # REORGANISATION DU MENU DEMARRER pour le programme %PACKAGE% #

if "%ALLUSERSPROFILE%"=="" Set ALLUSERSPROFILE="C:\Documents and Settings\All Users"

%Z%\wpkg\tools\reg.exe query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Common Programs" | find /I "Common Programs" > c:\tmp.txt
CHCP 1252 > NUL
	for /F "tokens=2* delims=	" %%a in (c:\tmp.txt) do (
	CHCP 850 > NUL
	if exist "%%b" set MenuDemarrer=%%b&& echo Le menu demarrer de AllUsers est dans %%b
)

IF "%3"=="remove" goto remove
:: pour convertir en minuscule le nom du package fourni
:: il faudrait faire la meme chose sur l'ID recupere dans le fichier PackagesCategory.txt
::FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO (
::	echo %%i
::	SET "PACKAGE=%%%PACKAGE:%%i%%"
::	echo %PACKAGE%
::)
::echo "Package : %PACKAGE%"

echo Rangement de %DOSSIERLNK% par categories dans AllUsers
for /F "tokens=1,2 delims=;" %%a in (%raccprogstoclass%) do (
	if "%%a"=="%PACKAGE%" (
		echo ID: %%a Category: %%b
		if exist "%MenuDemarrer%\%DOSSIERLNK%" (
			echo "%MenuDemarrer%\%DOSSIERLNK%" existe : on le deplace si la category est renseignee.
			if not "%%a"=="" if not "%%b"=="" (
				if not exist "%MenuDemarrer%\%%b" echo creation du dossier %%b&& mkdir "%MenuDemarrer%\%%b"
				if exist "%MenuDemarrer%\%%b\%DOSSIERLNK%" (
					echo La destination "%MenuDemarrer%\%%b\%DOSSIERLNK%" existe. On la supprime pour remplacement.
					dir "%MenuDemarrer%\%%b\%DOSSIERLNK%" | findstr /I "<REP>" >NUL
					if errorlevel 1 (
						echo Suppression du raccourci %%b\%DOSSIERLNK%
						del /F /S "%MenuDemarrer%\%%b\%DOSSIERLNK%"
					) ELSE (
						echo Suppression du dossier %%b\%DOSSIERLNK%
						rd /S /Q "%MenuDemarrer%\%%b\%DOSSIERLNK%"
					)
				)
				echo Rangement du fichier-dossier %DOSSIERLNK% de l'appli %%a vers la categorie %%b
				move /Y "%MenuDemarrer%\%DOSSIERLNK%" "%MenuDemarrer%\%%b\"
			)
		) ELSE (
			echo "%MenuDemarrer%\%DOSSIERLNK%" n existe pas. Bizarre.
		)
	)
)

goto END

:remove
echo Suppression de %DOSSIERLNK% du package %PACKAGE%
for /F "tokens=1,2 delims=;" %%a in (%raccprogstoclass%) do (
	if "%%a"=="%PACKAGE%" (
		echo ID: %%a Category: %%b
		if exist "%MenuDemarrer%\%%b\%DOSSIERLNK%" (
			echo "%MenuDemarrer%\%%b\%DOSSIERLNK%" existe : on le supprime.
			if not "%%a"=="" if not "%%b"=="" (
				dir "%MenuDemarrer%\%%b\%DOSSIERLNK%" | findstr /I "<REP>" >NUL
				if errorlevel 1 (
					echo Suppression du raccourci obsolete %%b\%DOSSIERLNK%
					del /F /S "%MenuDemarrer%\%%b\%DOSSIERLNK%"
				) ELSE (
					echo Suppression du dossier obsolete %%b\%DOSSIERLNK%
					rd /S /Q "%MenuDemarrer%\%%b\%DOSSIERLNK%"
				)
				echo Suppression de la categorie "%MenuDemarrer%\%%b" si vide.
				dir /B "%MenuDemarrer%\%%b" | find /V "" >NUL || rd /S /Q "%MenuDemarrer%\%%b"
			)
		)
	)
)

:END
CHCP 850 > NUL
