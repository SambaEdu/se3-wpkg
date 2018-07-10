#!/bin/bash
#
#### Installation et configuration de wpkg #####
#
# Sous licence GPL
# Si vous reprenez ou vous inspirez de ce programme, vous devez citer le Projet Samba Edu
# 
#  Auteur : Jean Le Bail
#
#    avril 2007
#    jean.lebail@etab.ac-caen.fr
#
## $Id$ ##
#
#    Modifie par : Jean-Remi Couturier - Academie de Clermont-Ferrand - avril 2015
#    A partir du travail sur WsusOffline de Olivier Lacroix
#
#  Corrections apportees :
#    Message d'information de l'installation automatique de WsusOffline a partir de 20h45.
#    Ligne 1680 :
#    Modification "chown -R www-admin /var/sambaedu/unattended/install" par "chown -R www-admin:admins /var/sambaedu/unattended/install"
#
# Trucs et astuces.
#    Pour installer le client wpkg sur un poste equipe de sshd, sans attendre le prochain login d'un utilisateur :
#        ssh administrateur@IpDuPoste (authentification par mot de passe, pas par cle, sinon le net use suivant ne marche pas sous XP avec cygwin+openssh; avec copssh c'est ok)
#           net use \\\\se4fs PassAdmin /user:se4\\admin
#           cmd /c \\\\se4fs\\Progs\\install\\installdll\\CPAU.exe -dec -lwp -cwd c:\\ -file \\\\se4fs\\Progs\\ro\\wpkgInstall.job
#
#        pour relancer l'execution du client wpkg sans avoir a redemarrer le poste :
#             schtasks.exe /Run /Tn wpkg
#          ou jt.exe /LJ $WINDIR\\tasks\\wpkg.job /RJ

# Dernier update fev 2016 - passage utf8

# Mode debug "1" ou "0"
DBG="0"

# Il faudrait peut-etre definir le repertoire de travail en cours...
# cd /var/tmp

### on suppose que l'on est sous debian  ####
WWWPATH="/var/www"
### version debian  ####
script_charset="UTF8"

. /usr/share/sambaedu/includes/config.inc.sh
. /usr/share/sambaedu/includes/utils.inc.sh



echo "Installation de wpkg : installation automatique d'applications sur clients Windows XP a Windows 10."
echo ""
if [ ! -d /var/sambaedu/unattended/install ]; then
   echo "Le repertoire /var/sambaedu/unattended/install n'existe pas"
   echo "Il aurait dû etre cree lors de l'installation d'unattended."
   echo "Echec de l'installation."
   exit 1
fi

WPKGDIR=$config_wpkgroot
WPKGROOT="\\\\${config_se4fs_name}\\install\\wpkg"


if [ ! -d $WPKGDIR ]; then
   echo "Erreur le repertoire $WPKGDIR n'existe pas."
   echo ""
   echo "Echec de l'installation."
   exit 1
fi


if [ ! -d $WPKGDIR/tools ]; then
   echo "Bizarre : le repertoire $WPKGDIR/tools n'existe pas !!!"
   mkdir /var/sambaedu/unattended/install/wpkg/tools
fi
if [ ! -d $WPKGDIR/tools ]; then
   echo "Erreur : le repertoire $WPKGDIR/tools n'a pas pu etre cree."
   exit 1
fi

# Telechargements pour mettre a jour les postes Windows qui en ont besoin
if [ ! -d /var/sambaedu/unattended/install/packages/windows ] ; then
   mkdir -p /var/sambaedu/unattended/install/packages/windows 
fi
cd /var/sambaedu/unattended/install/packages/windows

# WindowsXP-Windows2000-Script57
if [ ! -e scripten.exe ] ; then
   echo "Telechargement de WindowsScript57 (http://download.microsoft.com/download/4/4/d/44de8a9e-630d-4c10-9f17-b9b34d3f6417/scripten.exe)."
   if ( ! wget 'http://download.microsoft.com/download/4/4/d/44de8a9e-630d-4c10-9f17-b9b34d3f6417/scripten.exe' ) ; then
      echo "Erreur de telechargement de WindowsScript57."
      echo "  Vous pourrez le telecharger plus tard a partir de l'adresse :"
      echo "  http://www.microsoft.com/downloads/details.aspx?FamilyID=47809025-D896-482E-A0D6-524E7E844D81&displaylang=en"
      echo "  et placer scripten.exe"
      echo "  dans \\\\${config_se4fs_name}\\install\\packages\\windows\\ ."
      if [ -e scripten.exe ] ; then
         rm scripten.exe
      fi
   fi
fi

# Windows Installer 3.1 (v2)
if [ ! -e WindowsInstaller-KB893803-v2-x86.exe ] ; then
   echo "Telechargement de Windows Installer 3.1 (v2) (http://download.microsoft.com/download/1/4/7/147ded26-931c-4daf-9095-ec7baf996f46/WindowsInstaller-KB893803-v2-x86.exe)."
   if ( ! wget 'http://download.microsoft.com/download/1/4/7/147ded26-931c-4daf-9095-ec7baf996f46/WindowsInstaller-KB893803-v2-x86.exe' ) ; then
      echo "Erreur de telechargement de Windows Installer 3.1 (v2)."
      echo "  Vous pourrez le telecharger plus tard et placer WindowsInstaller-KB893803-v2-x86.exe"
      echo "  dans \\\\${config_se4fs_name}\\install\\packages\\windows\\ ."
      if [ -e WindowsInstaller-KB893803-v2-x86.exe ] ; then
         rm WindowsInstaller-KB893803-v2-x86.exe
      fi
   fi
fi

# MSXML (Microsoft Core XML Services) 6.0
if [ ! -e msxml6.msi ] ; then
   echo "Telechargement de MSXML (Microsoft Core XML Services) 6.0 (http://download.microsoft.com/download/8/a/4/8a4bae5b-95e9-4179-a838-1e75cf330a48/msxml6.msi)."
   if ( ! wget 'http://download.microsoft.com/download/8/a/4/8a4bae5b-95e9-4179-a838-1e75cf330a48/msxml6.msi' ) ; then
      echo "Erreur de telechargement de MSXML (Microsoft Core XML Services) 6.0."
      echo "  Vous pourrez le telecharger plus tard et placer msxml6.msi"
      echo "  dans \\\\${config_se4fs_name}\\install\\packages\\windows\\ ."
      if [ -e msxml6.msi ] ; then
         rm msxml6.msi
      fi
   fi
fi

#cd -

cd $WPKGDIR/tools

# jt pour definir une tache en ligne de commande dans le planificateur de tache
if [ ! -e jt.exe ] ; then
   if [ ! -e jt.zip ] ; then
      echo "Telechargement de l'utilitaire jt.exe (http://mvps.org/winhelp2002/jt.zip)."
      if ( ! wget --tries=3 "http://mvps.org/winhelp2002/jt.zip" ) ; then
         if [ -e jt.zip ] ; then
            rm jt.zip
         fi
         echo "Telechargement de l'utilitaire jt.exe : nouvel essai avec l'url 'ftp://ftp.microsoft.com/reskit/win2000/jt.zip'."
         if ( ! wget --tries=3 "ftp://ftp.microsoft.com/reskit/win2000/jt.zip" ) ; then
            echo "Erreur de telechargement de jt.zip."
         fi
      fi
   fi
   if [ -e jt.zip ] ; then 
      if ( md5sum jt.zip | grep '^5a11460945cab3ef526b038d37492e58 ' >/dev/null ) ; then
         if ( ! unzip -o jt.zip ) ; then
            echo "Erreur unzip -o jt.zip"
         fi
      else
         echo "Erreur md5sum : "
         md5sum jt.zip
         rm jt.zip
      fi
   fi
   if [ -e jt.exe ] ; then
      if ( md5sum jt.exe | grep '^3104f01eb01ce8b482bf895db60d7e8e ' >/dev/null ) ; then
         echo "L'utilitaire jt.exe est maintenant disponible.";
      else
         echo "Erreur md5sum : "
         md5sum jt.exe
         rm jt.exe
      fi
      # if [ -e jt.zip ] ; then rm jt.zip; fi
   else
      echo "L'utilitaire jt.exe n'est pas disponible ! Ressayez plus tard ...";
      echo "jt.exe pourra, par la suite, etre depose dans $WPKGROOT\\tools par l'admin."
   fi
else
   echo "L'utilitaire jt.exe etait deja disponible."
fi

#  Quelques utilitaires bien pratiques pour gerer les Windows

RebootSpecial=""
# PSTools pour psshutdown.exe pslist.exe ...
# Depuis que sysinternals ete rachete par Microsoft, il faut ajouter /accepteula aux options des commandes :(
if [ ! -e psshutdown.exe ] || [ ! -e pslist.exe ] ; then
   if [ ! -e PSTools.zip ]; then
      echo "Telechargement des PSTools (http://live.sysinternals.com/Files/PSTools.zip)."
      if ( ! wget "http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages-ng/files/pstools/PSTools.zip" ) ; then
        echo "Erreur de telechargement."
        if [ -e PSTools.zip ]; then
          rm PSTools.zip
        fi
      fi
   fi
   if [ -e PSTools.zip ]; then
      if ( ! unzip -o PSTools.zip ) ; then
         echo "Erreur unzip -o PSTools.zip"
      fi
   fi
   if [ -e psshutdown.exe ] && [ -e pslist.exe ] ; then
      echo "Les pstools sont maintenant disponibles.";
#       RebootSpecial="/rebootcmd:special"
#       if [ -e PSTools.zip ]; then
#          if ( ! rm PSTools.zip ) ; then
#             echo "Erreur rm PSTools.zip"
#          fi
#       fi
   else
      echo "Les PSTools ne sont pas disponibles ! Ressayez plus tard ...";
   fi
else
   echo "Les PSTools etaient deja disponibles."
#    RebootSpecial="/rebootcmd:special"
fi   

# SetAcl (deja dans le paquet)
# http://ovh.dl.sourceforge.net/sourceforge/setacl/setacl-cmdline-2.0.2.0-binary.zip
if [ ! -e SetACL.exe ]; then
   if [ ! -e setacl-cmdline-2.0.2.0-binary.zip ]; then
      echo "Telechargement de l'utilitaire SetACL (http://ovh.dl.sourceforge.net/sourceforge/setacl/setacl-cmdline-2.0.2.0-binary.zip)."
      if ( ! wget --tries=3 "http://ovh.dl.sourceforge.net/sourceforge/setacl/setacl-cmdline-2.0.2.0-binary.zip" ) ; then
         echo "Erreur de telechargement de setacl-cmdline-2.0.2.0-binary.zip."
         if [ -e setacl-cmdline-2.0.2.0-binary.zip ] ; then 
            rm setacl-cmdline-2.0.2.0-binary.zip
         fi
      fi
   fi
   if [ -e setacl-cmdline-2.0.2.0-binary.zip ]; then
      if ( ! unzip -o setacl-cmdline-2.0.2.0-binary.zip ) ; then
         echo "Erreur unzip -o setacl-cmdline-2.0.2.0-binary.zip"
         if [ -e SetACL.exe ] ; then 
            rm SetACL.exe
         fi
      fi
   fi
   if [ -e SetACL.exe ]; then
      if ( md5sum SetACL.exe | grep '^19bb0722fdbeb638df3b66b1ac1552f1 ' >/dev/null ) ; then
         echo "L'utilitaire SetACL.exe est maintenant disponible.";
      else
         echo "Erreur md5sum : "
         md5sum SetACL.exe
         rm SetACL.exe
      fi
      echo "L'utilitaire SetACL.exe est maintenant disponible.";
      if [ -e setacl-cmdline-2.0.2.0-binary.zip ]; then
         if ( ! rm setacl-cmdline-2.0.2.0-binary.zip ) ; then
            echo "Erreur rm setacl-cmdline-2.0.2.0-binary.zip"
         fi
      fi
   else
      echo "L'utilitaire SetACL.exe n'est pas disponible ! Ressayez plus tard ...";
      echo "SetACL.exe pourra, par la suite, etre depose dans $WPKGROOT\\tools par l'admin."
   fi
else
   echo "L'utilitaire SetACL.exe etait deja disponible."
fi   

# wget.exe (deja dans le paquet)
if [ ! -e wget.exe ] ; then
   echo "Telechargement de l'utilitaire wget.exe (http://users.ugent.be/~bpuype/cgi-bin/fetch.pl?dl=wget/wget.exe)."
   if ( ! wget --tries=3 "http://users.ugent.be/~bpuype/cgi-bin/fetch.pl?dl=wget/wget.exe" ) ; then 
      echo "Erreur de telechargement de wget.exe."
      if [ -e wget.exe ] ; then 
         rm wget.exe
      fi
   fi
   if [ -e wget.exe ] ; then
      # Test md5sum de wget.exe ;-)
      if ( md5sum wget.exe | grep '^dbe287eb8d58e6322e9fb67110ed7122 ' >/dev/null ) ; then
         echo "L'utilitaire wget.exe est maintenant disponible.";
      else
         echo "Erreur md5sum : "
         md5sum wget.exe
         rm wget.exe
      fi
   else
      echo "L'utilitaire wget.exe n'est pas disponible ! Ressayez plus tard ..."
      echo "wget.exe pourra, par la suite, etre depose dans $WPKGROOT\\tools par l'admin."
   fi
else
   echo "L'utilitaire wget.exe etait deja disponible."
fi

# md5sum.exe (deja dans le paquet)
if [ ! -e md5sum.exe ] ; then
   if [ ! -e md5sum-w32.zip ] ; then 
      echo "Telechargement de l'utilitaire md5sum.exe (http://ftp.fr.debian.org/debian/tools/md5sum-w32.zip)."
      if ( ! wget --tries=3 "http://ftp.fr.debian.org/debian/tools/md5sum-w32.zip" ) ; then 
         echo "Erreur de telechargement de md5sum-w32.zip."
         if [ -e md5sum-w32.zip ] ; then 
            rm md5sum-w32.zip
         fi
      fi
   fi
   if [ -e md5sum-w32.zip ] ; then 
      if ( ! unzip -o md5sum-w32.zip ) ; then
         echo "Erreur unzip -o md5sum-w32.zip"
         if [ -e md5sum.exe ] ; then 
            rm md5sum.exe
         fi
      fi
   fi
   if [ -e md5sum.exe ] ; then
      # Test md5sum de md5sum.exe ;-)
      if ( md5sum md5sum.exe | grep '^623864dab703a0ceca76e8d70de60c0c ' >/dev/null ) ; then
         echo "L'utilitaire md5sum.exe est maintenant disponible.";
      else
         echo "Erreur md5sum : "
         md5sum md5sum.exe
         rm md5sum.exe
      fi
   else
      echo "L'utilitaire md5sum.exe n'est pas disponible ! Ressayez plus tard ..."
      echo "md5sum.exe pourra, par la suite, etre depose dans $WPKGROOT\\tools par l'admin."
   fi
else
   echo "L'utilitaire md5sum.exe etait deja disponible."
fi

cd -

# priorite d'execution de wpkg sur les clients
# PRIORITY=/LOW|/BELOWNORMAL|/NORMAL|/ABOVENORMAL|/HIGH|/REALTIME
PRIORITY=/BELOWNORMAL

CONFIGBAT="/var/sambaedu/Progs/install/wpkg-config.bat"

# Suppression de l'ancien script execute avant wpkg-se4.js
# Maintenant les options du client sont definies dans l'interface.
if [ -e $WPKGDIR/wpkgAvant.bat ]; then
   rm $WPKGDIR/wpkgAvant.bat
   echo "Ancien script $WPKGDIR/wpkgAvant.bat supprime (il n'est plus utilise dans cette version)."
fi

# Script de demarrage des anciens clients wpkg 
# C'est maintenant wpkg-client.vbs (client execute au boot du poste) qui lance directement wpkg-se4.js
#--------Debut wpkg-se4.bat-----------#
cat - > $WPKGDIR/wpkg-se4.bat <<WPKGSE4BAT
:: Ce fichier assure la mise a jour des anciens clients
:: Ensuite il n'est plus utilise
:: ## $Id$ ##
@Echo OFF
Set Silent=1
Echo %date% %time% Mise a jour du client wpkg.
:: Lancement de wpkg-repair.bat a l'aide du job wpkg-repair.job
If Not Exist \\\\${config_se4fs_name}\\Progs\\ro\\wpkg-repair.job Goto NoWpkgRepairJob
Echo Lancement du job CPAU wpkg-repair 
\\\\${config_se4fs_name}\\netlogon\\CPAU.exe -dec -lwp -cwd %SystemDrive%\\ -file \\\\${config_se4fs_name}\\Progs\\ro\\wpkg-repair.job 2>NUL >NUL
If "%ErrorLevel%"=="1907" Goto ErrAdminse4Expire
If "%ErrorLevel%"=="1326" Goto ErrAdminse4BadPassword
If Not "%ErrorLevel%"=="0" Echo Erreur %ErrorLevel% lors de l'execution de 'CPAU.exe -dec -lwp -cwd %SystemDrive%\\ -file \\\\${config_se4fs_name}\\Progs\\ro\\wpkg-repair.job'

echo.
echo Le rapport de la mise a jour du client est disponible ici :
echo ^</pre^>
echo  ^<a href="${config_urlse}/wpkg/index.php?logfile=%COMPUTERNAME%.maj"^>${config_urlse}/wpkg/index.php?logfile=%COMPUTERNAME%.maj^</a^>
echo ^<pre^>

Goto Done

:NoWpkgRepairJob
echo Erreur : Fichier \\\\${config_se4fs_name}\\Progs\\install\\wpkg-repair.job absent !
echo   En tant qu'admin, relancer :
echo   \\\\${config_se4fs_name}\\Progs\\install\\wpkg-config.bat
Goto Done

:ErrAdminse4BadPassword
echo Erreur : Le mot de passe d'$config_adminse_name sur %COMPUTERNAME% n'est pas correct !
echo   Revoir la configuration du compte '$config_adminse_name' sur %COMPUTERNAME%.
Goto Done

:ErrAdminse4Expire
echo Erreur : Le compte $config_adminse_name a un mot de passe qui expire.
echo   Revoir la configuration du compte '$config_adminse_name' sur %COMPUTERNAME%.
Goto Done

:Done
echo Fin de wpkg-se4.bat
WPKGSE4BAT
#--------Fin wpkg-se4.bat-----------#
recode $script_charset..CP850 $WPKGDIR/wpkg-se4.bat
todos $WPKGDIR/wpkg-se4.bat
chmod 755 $WPKGDIR/wpkg-se4.bat
echo "Script $WPKGDIR/wpkg-se4.bat cree."

# Suppression de l'ancien script execute apres wpkg-se4.js
if [ -e $WPKGDIR/wpkgApres.bat ]; then
   rm $WPKGDIR/wpkgApres.bat
   echo "Ancien script $WPKGDIR/wpkgApres.bat supprime (il n'est plus utilise dans cette version)."
fi

# Script d'installation de la tache planifiee sur le poste
# Est execute sous local\$config_adminse_name avec CPAU l'authentification au serveur etant deja faite
#--------Debut wpkg-install.bat-----------#
cat - > $WPKGDIR/wpkg-install.bat <<PREINSTBAT
:: Script d'installation de wpkg sur le client.
:: S'execute avec le compte local $${config_adminse_name} grace a CPAU, 
::    l'authentification sur le serveur est deja faite.
::
:: ## $Id$ ##

If "%SILENT%"=="1" @Echo OFF
Set WPKGROOT=$WPKGROOT

:: Pour executer wpkg aussitot apres l'installation du client sur les postes
If "%NoRunWpkgJS%"=="" Set NoRunWpkgJS=0
If Exist "%SystemRoot%\\netinst\\nowpkg.txt" Set NoRunWpkgJS=1
If "%NoRunWpkgJS%"=="1" Echo L'installation des applications ne sera effectuee qu'au prochain boot.

:: Pour supprimer la temporisation avant execution de wpkg-se4.js
Rem Echo NoTempo >"%SystemDrive%\\netinst\\wpkg-notempo.txt"

SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

@If "$DBG"=="1" Echo Debut wpkg-install.bat   Pause 2 sec ...
@If "$DBG"=="1" ping -n 3 127.0.0.1 >NUL

@If "%TaskUser%"=="" Exit 5
@If "%TaskPass%"=="" Exit 5

echo %date% %time% Debut de l'execution de wpkg-install.bat sur %COMPUTERNAME% 
echo. 

set Log=%Windir%\\wpkg.log
set NbErreur=0

:: Copie sur le poste local des fichiers necessaires
Set REGEXE=%WinDir%\\system32\\reg.exe
If Exist "%REGEXE%" Goto REGEXEFOUND
If Exist \\\\${config_se4fs_name}\\install\\wpkg\\tools\\reg.exe copy /Y /B /V \\\\${config_se4fs_name}\\install\\wpkg\\tools\\reg.exe "%REGEXE%"
If Exist "%REGEXE%" Goto REGEXEFOUND
echo L'utilitaire reg.exe est introuvable.
echo A partir d'un WinXP, recopiez %WinDir%\\system32\\reg.exe dans \\\\${config_se4fs_name}\\install\\wpkg\\tools\\ 
Goto WindowsScriptHost56
:REGEXEFOUND


:WindowsScriptHost56
echo Version de WindowsScriptHost
cscript.exe //NoLogo %WPKGROOT%\\tools\\fileversion.vbs %WinDir%\\system32\\jscript.dll GE 5.6.0.8831
If "%ErrorLevel%"=="0" Goto WININSTALLER

:: L'install silentieuse ne marche pas sous win2k :(
echo WindowsScriptHost  n'est pas a jour !
echo   installez-le sur le poste a partir de :
echo   http://www.microsoft.com/downloads/details.aspx?FamilyID=c717d943-7e4b-4622-86eb-95a22b832caa&DisplayLang=fr
Goto WININSTALLER

echo Mise a jour WindowsScriptHost 5.7 ou 5.6
If Exist %WPKGROOT%\\..\\packages\\windows\\scripten.exe Goto SETUP57
If Exist %WPKGROOT%\\..\\packages\\windows\\WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe Goto SETUP56
echo Les fichiers "scripten.exe " et "WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe" sont absents. 
echo   Telechargez scripten.exe depuis l'adresse 
echo   http://www.microsoft.com/downloads/details.aspx?FamilyID=47809025-D896-482E-A0D6-524E7E844D81&displaylang=en
echo   et placez ce fichier dans \\\\${config_se4fs_name}\\install\\packages\\windows\\ 
Set /A NbErreur=1+%NbErreur%
Goto WININSTALLER

:SETUP56
:: Installation silentieuse de scriptfr.inf
%WPKGROOT%\\..\\packages\\windows\\WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe /T:%SystemDrive%\\tmp /C /Q
If "%Errorlevel%"=="0" start /wait %WinDir%\\System32\\rundll32.exe setupapi,InstallHinfSection DefaultInstall 128 %SystemDrive%\\tmp\\scriptfr.inf
Set Erreur=%ErrorLevel%
If Not "%Erreur%"=="0" If Not "%Erreur%"=="3010" echo Err %Errorlevel% : Mise a jour WindowsScriptHost 
If Not "%Erreur%"=="0" Set /A NbErreur=1+%NbErreur%
If "%Erreur%"=="3010" echo WindowsScriptHost56 sera operationnel apres un redemarrage. 
If "%Erreur%"=="0" echo Mise a jour WindowsScriptHost : OK 
If Exist "%SystemDrive%\\tmp" RmDir /S /Q "%SystemDrive%\\tmp"
Goto WININSTALLER

:SETUP57
:: Installation silentieuse de scriptfr.inf
%WPKGROOT%\\..\\packages\\windows\\scripten.exe /quiet /passive /norestart /overwriteoem
::If "%Errorlevel%"=="0" start /wait %WinDir%\\System32\\rundll32.exe setupapi,InstallHinfSection DefaultInstall 128 %SystemDrive%\\tmp\\scriptfr.inf
Set Erreur=%ErrorLevel%
If Not "%Erreur%"=="0" If Not "%Erreur%"=="3010" echo Err %Errorlevel% : Mise a jour WindowsScriptHost 
If Not "%Erreur%"=="0" Set /A NbErreur=1+%NbErreur%
If "%Erreur%"=="3010" echo WindowsScriptHost57 sera operationnel apres un redemarrage. 
If "%Erreur%"=="0" echo Mise a jour WindowsScriptHost : OK 
If Exist "%SystemDrive%\\tmp" RmDir /S /Q "%SystemDrive%\\tmp"

:WININSTALLER
echo Version de Windows Installer
cscript.exe //NoLogo %WPKGROOT%\\tools\\fileversion.vbs %WinDir%\\system32\\msiexec.exe GE 3.1.4000.1823
If "%ErrorLevel%"=="0" Goto MSXML
echo Mise a jour Windows Installer 3.1 (v2) 
If Exist %WPKGROOT%\\..\\packages\\windows\\WindowsInstaller-KB893803-v2-x86.exe Goto SETUPMSI
echo Le fichier "%WPKGROOT%\\..\\packages\\windows\\WindowsInstaller-KB893803-v2-x86.exe" est absent. 
echo   Telechargez-le depuis l'adresse 
echo   http://www.microsoft.com/downloads/details.aspx?FamilyID=889482fc-5f56-4a38-b838-de776fd4138c&DisplayLang=fr 
echo   et placez ce fichier dans \\\\${config_se4fs_name}\\install\\packages\\windows\\ 
Set /A NbErreur=1+%NbErreur%
Goto Done
:SETUPMSI
xcopy /Y /C /I /H /R %WPKGROOT%\\..\\packages\\windows\\WindowsInstaller-KB893803-v2-x86.exe "%TMP%\\"
start /wait /D "%TMP%" WindowsInstaller-KB893803-v2-x86.exe /passive /norestart /nobackup
Set Erreur=%ErrorLevel%
If Not "%Erreur%"=="0" echo Err %Erreur% : Mise a jour Windows Installer 
If "%Erreur%"=="0" echo Mise a jour Windows Installer : OK 
If Not "%Erreur%"=="0" Set /A NbErreur=1+%NbErreur%
Del /F /Q "%TMP%\\WindowsInstaller-KB893803-v2-x86.exe"
:: On continue meme en cas d'erreur

:MSXML
echo Version de MSXML (Microsoft Core XML Services)
cscript.exe //NoLogo %WPKGROOT%\\tools\\fileversion.vbs %WinDir%\\system32\\Msxml6.dll GE 6.0.3883.0
If "%ErrorLevel%"=="0" Goto SETTASK
echo Installation de MSXML (Microsoft Core XML Services) 6.0 
If Exist %WPKGROOT%\\..\\packages\\windows\\msxml6.msi Goto SETUPMSXML
echo Le fichier "%WPKGROOT%\\..\\packages\\windows\\msxml6.msi" est absent. 
echo   Telechargez-le depuis l'adresse 
echo   http://www.microsoft.com/downloads/details.aspx?FamilyID=993c0bcf-3bcf-4009-be21-27e85e1857b1&DisplayLang=fr 
echo   et placez ce fichier dans \\\\${config_se4fs_name}\\install\\packages\\windows\\ 
Set /A NbErreur=1+%NbErreur%
Goto Done
:SETUPMSXML
xcopy /Y /C /I /H /R %WPKGROOT%\\..\\packages\\windows\\msxml6.msi "%TMP%\\"
start /wait /D "%TMP%" msiexec /quiet /passive /i msxml6.msi
If Not "%ErrorLevel%"=="0" echo Err %Errorlevel% : Mise a jour MSXML 
If "%ErrorLevel%"=="0" echo Mise a jour MSXML : OK 
If "%Erreur%"=="3010" echo MSXML sera operationnel apres un redemarrage. 
If Not "%ErrorLevel%"=="0" Set /A NbErreur=1+%NbErreur%

:SETTASK
:: Recopie en local des utilitaires de gestion de taches planifiees
If Not Exist %WinDir%\\jt.exe If Exist %WPKGROOT%\\tools\\jt.exe copy /Y /B %WPKGROOT%\\tools\\jt.exe %WinDir%\\jt.exe
If Not Exist %WinDir%\\system32\\schtasks.exe If Exist %WPKGROOT%\\tools\\schtasks2k.exe copy /Y /B %WPKGROOT%\\tools\\schtasks2k.exe %WinDir%\\schtasks2k.exe

If Not Exist %WinDir%\\jt.exe Goto TestSCHTASKS
:: Installation de la tache planifiee avec jt.exe
Set JT=%WinDir%\\jt.exe
echo Suppression de l'ancienne tache wpkg
%JT% /SD wpkg.job
If Exist %Windir%\\Tasks\\wpkg.job del /F /Q %Windir%\\Tasks\\wpkg.job

:: Creation de la tache planifie avec jt.exe (Echo OFF pour cacher TaskPass)
@Set OptJT=/SC %TaskUser% %TaskPass% 

@Set OptJT=%OptJT% /SJ ApplicationName="%Windir%\\system32\\cscript.exe" 
@Set OptJT=%OptJT% Parameters="%Windir%\\wpkg-client.vbs"
::@Set OptJT=%OptJT% /SJ ApplicationName="%ComSpec%" 
::@Set OptJT=%OptJT% Parameters="/C start $PRIORITY %Windir%\\system32\\cscript.exe //B %Windir%\\wpkg-client.vbs"

@Set OptJT=%OptJT% WorkingDirectory="%WinDir%" 
@Set OptJT=%OptJT% Comment="Client wpkg - Installation automatique d'applications" 
@Set OptJT=%OptJT% Creator=%USERNAME% MaxRunTime=9999999999 DontStartIfOnBatteries=0 
@Set OptJT=%OptJT% KillIfGoingOnBatteries=0 RunOnlyIfLoggedOn=0 DeleteWhenDone=0 
@Set OptJT=%OptJT% /CTJ Type=ATSTARTUP StartDate=TODAY StartTime=NOW Disabled=0 
@Set OptJT=%OptJT% /SAJ wpkg.job

@If "$DBG"=="1" Echo %JT% %OptJT%      Pause 5 sec ...
@If "$DBG"=="1" ping -n 6 127.0.0.1 >NUL

echo Creation de la tache wpkg. 
@%JT% %OptJT%
If Not ErrorLevel 1 echo "Creation de la tache planifiee : OK" 
If ErrorLevel 1 echo "Erreur de creation de la tache planifiee :" 
@If ErrorLevel 1 %Windir%\\jt.exe %OptJT% 
Set OptJT=
Set TaskPass=
Set TaskUser=
Goto CopyWpkgClient

TestSCHTASKS
:: Si schtasks.exe local est dispo on l'utilise
Set SCHTASKS=%WinDir%\\system32\\schtasks.exe
If Exist "%SCHTASKS%" Goto CreateTask
Set SCHTASKS=%WinDir%\\schtasks2k.exe
If Exist "%SCHTASKS%" Goto CreateTask
Goto NoSchTasks

:CreateTask
:: Suppression eventuelle d'une ancienne tache planifiee avec schtasks2k.exe
%SCHTASKS% | find /I "wpkg" >NUL
If ErrorLevel 1 Goto TaskDelOk
echo Suppression de l'ancienne tache wpkg. avec %SCHTASKS% 
%SCHTASKS% /Delete /TN wpkg /F 
If ErrorLevel 1 %SCHTASKS% /Delete /TN wpkg /F 
If Exist %Windir%\\Tasks\\wpkg.job del /F /Q %Windir%\\Tasks\\wpkg.job
:TaskDelOk

:: Creation de la tache planifie avec %SCHTASKS%
@Set Opt=/create /RU %TaskUser% /RP %TaskPass% 
@Set Opt=%Opt% /SC ONSTART /TN wpkg /TR "%Windir%\\system32\\cscript.exe //B %Windir%\\wpkg-client.vbs"

@If "$DBG"=="1" Echo %SCHTASKS% %Opt%  Pause 5 sec ...
@If "$DBG"=="1" ping -n 6 127.0.0.1 >NUL

echo Creation de la tache wpkg avec %SCHTASKS% 
@%SCHTASKS% %Opt%
If ErrorLevel 1 echo Erreur %ErrorLevel% lors de la creation de la tache planifiee :
:: @If ErrorLevel 1 %SCHTASKS% %Opt% 
Set Opt=
Set TaskPass=
Set TaskUser=

:CopyWpkgClient
:: Suppression de %WinDir%\\wpkg.job resultant de l'install ancienne version
If Exist %WinDir%\\wpkg.job Del /F /Q %WinDir%\\wpkg.job 
If Exist %WinDir%\\wpkg-client.vbs echo Suppression de l'ancien client %WinDir%\\wpkg-client.vbs.
If Exist %WinDir%\\wpkg-client.vbs Del /F /Q %WinDir%\\wpkg-client.vbs 
:: Recopie des fichiers 
If Exist %WPKGROOT%\\wpkg-client.vbs copy /Y /V /B %WPKGROOT%\\wpkg-client.vbs %WinDir%\\wpkg-client.vbs
If Exist %WinDir%\\wpkg-client.vbs Goto RunClient
echo Erreur : copy /Y /V /B %WPKGROOT%\\wpkg-client.vbs %WinDir%\\wpkg-client.vbs
echo Erreur : copy /Y /V /B %WPKGROOT%\\wpkg-client.vbs %WinDir%\\wpkg-client.vbs 
Exit /B 7

:RunClient
echo Recopie du client depuis le serveur : OK 

If Not "%NbErreur%"=="0" Set NoRunWpkgJS=1

Set APPENDLOGOPTION=
If "%APPENDLOG%"=="1" Set APPENDLOGOPTION=/AppendLog
If Not "%NoRunWpkgJS%"=="1" echo Lancement du client (APPENDLOG=%APPENDLOG%) ...
If Not "%NoRunWpkgJS%"=="1" start /wait $PRIORITY %WinDir%\\system32\\cscript.exe //NoLogo //B %WinDir%\\wpkg-client.vbs /NoTempo %APPENDLOGOPTION%
If "%NoRunWpkgJS%"=="1" echo %date% %time% - Le client est en place. Il sera lance au prochain boot. 
@If "$DBG"=="1" Echo Apres 'start /wait $PRIORITY %WinDir%\\system32\\cscript.exe //NoLogo //B %WinDir%\\wpkg-client.vbs /NoTempo %APPENDLOGOPTION%'    Pause 2 sec ...
@If "$DBG"=="1" ping -n 3 127.0.0.1 >NUL
If Exist "%SystemDrive%\\netinst\\wpkg-notempo.txt" del /F /Q "%SystemDrive%\\netinst\\wpkg-notempo.txt"
If Exist "%SystemDrive%\\netinst\\nowpkg.txt" del /F /Q "%SystemDrive%\\netinst\\nowpkg.txt"

Goto WpkgInstallDone

:NoSchTasks
:: Pas d'utilitaire disponible pour creer la tache planifiee
echo Erreur : ni schtasks2k.exe, ni jt.exe 
echo          ne sont disponibles dans %WPKGROOT%\\tools\\ 
echo          
echo          Revoir l'installation de wpkg.
echo. 
:WpkgInstallDone

@If "$DBG"=="1" Echo Sortie de wpkg-install.bat   Pause 5 sec ...
@If "$DBG"=="1" ping -n 6 127.0.0.1 >NUL
:Done
echo %date% %time% Fin de wpkg-install.bat. 
PREINSTBAT
#--------Fin wpkg-install.bat-----------#
recode $script_charset..CP850 $WPKGDIR/wpkg-install.bat
todos $WPKGDIR/wpkg-install.bat
echo "Script $WPKGDIR/wpkg-install.bat cree."

# Chemin du job d'installation de wpkg sur un poste pour un utilisateur lambda
INSTTASKJOB="\\\\${config_se4fs_name}\\Progs\\ro\\wpkgInstall.job"
# Chemin du job d'execution de wpkg sur un poste pour un utilisateur lambda
RUNWPKGJOB="\\\\${config_se4fs_name}\\Progs\\ro\\wpkgRun.job"
# Commande a placer dans le script de login des utilisateurs
CMDINSTALL="@if \"%%OS%%\"==\"Windows_NT\" if not exist \"%%WinDir%%\\wpkg-client.vbs\" $CPAU -dec -lwp -hide -cwd %%SystemDrive%%\\ -file $INSTTASKJOB 2^>NUL ^>NUL"
FINDCMD="@if \"\"%%OS%%\"\"==\"\"Windows_NT\"\" if not exist \"\"%%WinDir%%\\wpkg-client.vbs\"\" $CPAU -dec -lwp -hide -cwd %%SystemDrive%%\\ -file $INSTTASKJOB 2>NUL >NUL"
# Chemin du script de login
LogonBat="\\\\${config_se4fs_name}\\admhomes\\templates\\base\\logon.bat"
# Commande executee par $config_adminse_name pour installer wpkg sur le poste
TASK="(net use \\\\${config_se4fs_name}||(exit 8))&&(Set APPENDLOG=1&&Set TaskUser=$${config_adminse_name}&&Set TaskPass=$${config_adminse_passwd}&&call $WPKGROOT\\wpkg-install.bat&net use * /delete /y)"
# Commande executee par $config_adminse_name pour executer wpkg sur le poste
TASKRUNWPKG='{%%{ComSpec}%%} /C cscript {%%{Windir}%%}\\wpkg-client.vbs /debug /notempo /cpuLoad 80&pause'

# Script de diagnostic et reparation d'un client wpkg recalcitrant
# par exemple a cause d' un compt $config_adminse_name defaillant
#--------Debut wpkg-diag.bat-----------#
cat - > /var/sambaedu/Progs/install/wpkg-diag.bat <<WPKGDIAG
:: Script de diagnostic/reparation d'un client wpkg qui ne demarre plus.
:: Verifie le compte $config_adminse_name puis lance wpkg-repair.bat sous $config_adminse_name.
:: ## $Id$ ##
@echo OFF

:: NoRunWpkgJS=1  pour ne pas lancer wpkg avec ce script.
:: A priori, il est deja en cours d'execution.
:: Il sera lance au prochain boot du poste.
Set NoRunWpkgJS=1

:: Initialisation des variables
::   Nom du serveur se4 utilise lors de l'install de wpkg
Set se4=${config_se4fs_name}
::   Fichier de log du dignostic
If Not Exist \\\\%se4%\\Progs\\rw\\wpkg mkdir \\\\%se4%\\Progs\\rw\\wpkg
Set LOG=\\\\%se4%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log
echo Diagnostic de l'installation du client Wpkg sur '%COMPUTERNAME%' >%LOG%
echo. 
echo %date% %time% Debut du diagnostic. >>%LOG%
echo. >>%LOG%

:: Test du compte $config_adminse_name
::   Le compte $config_adminse_name existe-t-il ?
net user $config_adminse_name >NUL
If ErrorLevel 1 Goto ErrNoAdminse4
echo Le compte $config_adminse_name existe. >>%LOG%
net user $config_adminse_name | find /I "Compte" | find /I "actif" | find /I "oui" >>%LOG%
If ErrorLevel 1 Goto ErrAdminse4NotActive
net user $config_adminse_name | find /I "Le mot de passe expire" | find /I "jamais" >>%LOG%
If ErrorLevel 1 Goto ErrAdminse4Expire
net user $config_adminse_name | find /I "groupes locaux" | find /I "Administrateurs" >>%LOG%
If ErrorLevel 1 Goto ErrAdminse4NotAdministrateur
net user $config_adminse_name | find /I "Mot de passe exig" | find /I "Oui" >>%LOG%
If ErrorLevel 1 Goto ErrAdminse4NoPassword
echo. >>%LOG%

:: Lancement de wpkg-repair.bat a l'aide du job wpkg-repair.job
If Not Exist \\\\%se4%\\Progs\\ro\\wpkg-repair.job Goto NoWpkgRepairJob
Echo Lancement du job CPAU wpkg-repair >>%LOG%
\\\\%se4%\\netlogon\\CPAU.exe -dec -wait -lwp -cwd %SystemDrive%\\ -file \\\\%se4%\\Progs\\ro\\wpkg-repair.job 2>NUL >NUL
If "%ErrorLevel%"=="1907" Goto ErrAdminse4Expire
If "%ErrorLevel%"=="1326" Goto ErrAdminse4BadPassword

Goto Done

:NoWpkgRepairJob
echo Erreur : Fichier \\\\%se4%\\Progs\\install\\wpkg-repair.job absent ! >>%LOG%
echo   En tant que root sur la console du serveur, relancer : >>%LOG%
echo   /var/cache/sambaedu_install/wpkg-install.sh >>%LOG%
Goto Done

:ErrAdminse4BadPassword
echo Erreur : Le mot de passe d'$config_adminse_name sur %COMPUTERNAME% n'est pas correct ! >>%LOG%
echo   Revoir la configuration du compte '$config_adminse_name' sur %COMPUTERNAME%.  >>%LOG%
Goto Done

:ErrAdminse4NoPassword
echo Erreur : Aucun mot de passe n'est exige pour $config_adminse_name.  >>%LOG%
echo   Revoir la configuration du compte '$config_adminse_name' sur %COMPUTERNAME%.  >>%LOG%
Goto Done

:ErrAdminse4NotAdministrateur
echo Erreur : $config_adminse_name n'est pas membre du groupe local des Administrateurs.  >>%LOG%
echo   Revoir la configuration du compte '$config_adminse_name' sur %COMPUTERNAME%. >>%LOG%
Goto Done

:ErrAdminse4Expire
echo Erreur : Le compte $config_adminse_name a un mot de passe qui expire.  >>%LOG%
echo   Revoir la configuration du compte '$config_adminse_name' sur %COMPUTERNAME%.  >>%LOG%
Goto Done

:ErrAdminse4NotActive
echo Erreur : Le compte $config_adminse_name n'est pas actif.  >>%LOG%
echo   Revoir la configuration du compte '$config_adminse_name' sur %COMPUTERNAME%.  >>%LOG%
Goto Done

:ErrNoAdminse4
echo Erreur : Pas de compte $config_adminse_name defini sur ce poste.  >>%LOG%
echo   Revoir l'integration du poste au domaine SAMBAEDU.  >>%LOG%
Goto Done

:Done

WPKGDIAG
#--------Fin wpkg-diag.bat-----------#
recode $script_charset..CP850 /var/sambaedu/Progs/install/wpkg-diag.bat
todos /var/sambaedu/Progs/install/wpkg-diag.bat
# setfacl -m u::rwx -m g::rx -m o::rx /var/sambaedu/Progs/install/wpkg-diag.bat
chmod 755 /var/sambaedu/Progs/install/wpkg-diag.bat
echo "Script /var/sambaedu/Progs/install/wpkg-diag.bat cree."

# Script de reparation d'un client wpkg recalcitrant
# par exemple a cause de running=true qui bloque l'execution
#--------Debut wpkg-repair.bat-----------#
cat - > $WPKGDIR/wpkg-repair.bat <<WPKGREPAIR
:: Script de diagnostic/reparation d'un client wpkg qui ne s'execute pas.
:: Il s'execute sous $config_adminse_name (encore faut-il que ce compte soit valide !)
:: Le lancement se fait avec le job CPAU (wpkg-repair.job)
@echo OFF
Set se4=${config_se4fs_name}

Set NoRunWpkgJS=1
Set CscriptRunning=1
If Not Exist \\\\%se4%\\install\\wpkg\\tools\\pslist.exe Goto ApresTestCscript
:: Le parametre /accepteula est-il necessaire pour les pstools ?
Set ACCEPTEULA=/accepteula
\\\\%se4%\\install\\wpkg\\tools\\pslist.exe /accepteula 2>NUL >NUL
If ErrorLevel 1 Set ACCEPTEULA=

:: Laisse une chance a l'ancien wpkg-client.vbs de se terminer
echo Attend au plus 60s que l'ancien client se termine
set BoucleAttend="x"
:AttendFinCscript
ping -n 4 127.0.0.1 >NUL
\\\\%se4%\\install\\wpkg\\tools\\pslist.exe %ACCEPTEULA% cscript 2>NUL >NUL
If ErrorLevel 1 Set CscriptRunning=0
If "%CscriptRunning%"=="0" Goto ApresTestCscript
Set BoucleAttend=%BoucleAttend%x
If "%BoucleAttend%"=="xxxxxxxxxxxxxxxxxxxxx" Goto ApresTestCscript
Echo "On attend encore un peu ..."
Goto AttendFinCscript

:ApresTestCscript

If Not Exist %SystemDrive%\\netinst\\log mkdir %SystemDrive%\\netinst\\log
Set LOG=%SystemDrive%\\netinst\\log\\wpkg-repair.log
echo. 1>%LOG%
echo %date% %time% Demarrage wpkg-repair.bat en tant que %USERNAME%. 1>%LOG%
:: TaskUser et TaskPass sont disponibles
Set REGEXE=%WinDir%\\system32\\reg.exe
If Exist "%REGEXE%" Goto REGEXEFOUND
Set REGEXE=\\\\%se4%\\install\\wpkg\\tools\\reg.exe 1>>%LOG%
If Exist "%REGEXE%" Goto REGEXEFOUND
echo L'utilitaire reg.exe est introuvable. 1>>%LOG%
echo A partir d'un WinXP, recopiez %WinDir%\\system32\\reg.exe dans \\\\%se4%\\install\\wpkg\\tools\\ 1>>%LOG%
Goto InstallWpkg

:REGEXEFOUND

:: Controle de running True
reg query hklm\\software 2>NUL >NUL
If ErrorLevel 1 Goto ErreurRegExe
reg query hklm\\software\\wpkg 2>NUL >NUL
If ErrorLevel 1 Goto WpkgNeverRun
reg query hklm\\software\\wpkg 2>NUL | find /I "running" | find /I "true" 1>>%LOG%
If ErrorLevel 1 Goto WpkgRunninFalse
Echo Wpkg est indique en cours d'execution 1>>%LOG%
Echo   L'entree running=true de la base de registre est supprimee 1>>%LOG%
Echo   Wwpkg ne sera lance qu'au prochain boot. 1>>%LOG%
reg delete hklm\\software\\wpkg /v running /f
Goto InstallWpkg

:ErreurRegExe
Echo Erreur reg.exe ! Etes-vous sur de la validite de cet utilitaire ? 1>>%LOG%
Goto InstallWpkg

:WpkgRunninFalse
Echo Wpkg n'est pas indique en cours d'execution. 1>>%LOG%
If "%CscriptRunning%"=="0" Set NoRunWpkgJS=0
Goto InstallWpkg

:WpkgNeverRun
Echo Wpkg n'a jamais ete execute sur ce poste. 1>>%LOG%
If "%CscriptRunning%"=="0" Set NoRunWpkgJS=0
Goto InstallWpkg

:InstallWpkg
:: Mise a jour du client
Echo Lancement du client wpkg ... 1>>%LOG%

Set LOGSRV=\\\\%se4%\\install\\wpkg\\rapports\\%COMPUTERNAME%.maj
If Exist "%LOGSRV%" del /F /Q "%LOGSRV%"
If Exist \\\\%se4%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log Type \\\\%se4%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log >> %LOGSRV%
If Exist \\\\%se4%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log del /F /Q \\\\%se4%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log
If Exist %LOG% echo -- %date% %time% Contenu de wpkg-repair.log --- >> %LOGSRV%
If Exist %LOG% Type %LOG% >> %LOGSRV%
If Exist %LOG% echo -- Fin wpkg-repair.log --- >> %LOGSRV%
echo La suite du rapport d'installation sera disponible dans quelques instants ... >> %LOGSRV%

Rem Set SILENT=1
Set APPENDLOG=1
call \\\\%se4%\\install\\wpkg\\wpkg-install.bat 2>%LOG%.err 1>%LOG%

echo -- %date% %time% Contenu de wpkg-install.log.err --- >> %LOGSRV%
Type %LOG%.err >> %LOGSRV%
echo -- Fin wpkg-install.log.err --- >> %LOGSRV%
echo -- Contenu de wpkg-install.log --- >> %LOGSRV%
Type %LOG% >> %LOGSRV%
echo -- Fin wpkg-install.log --- >> %LOGSRV%

WPKGREPAIR
#--------Fin wpkg-repair.bat-----------#
recode $script_charset..CP850 $WPKGDIR/wpkg-repair.bat
todos $WPKGDIR/wpkg-repair.bat
echo "Script $WPKGDIR/wpkg-repair.bat cree."


#--------Debut wpkg-config.bat-----------#
# script devenu obsolete : suppression.
[ -e /var/sambaedu/Progs/install/wpkg-config.bat ] && echo "Suppression de /var/sambaedu/Progs/install/wpkg-config.bat"&& rm /var/sambaedu/Progs/install/wpkg-config.bat


# Chemin du job d'installation de wpkg sur un poste pour un utilisateur lambda
INSTTASKJOB="wpkgInstall.job"
# Chemin du job d'execution de wpkg sur un poste pour un utilisateur lambda
RUNWPKGJOB="wpkgRun.job"
# Chemin du script de login
LogonBat="/home/templates/base/logon.bat"
# Commande executee par $config_adminse_name pour installer wpkg sur le poste
TASK="(net use \\\\${config_se4fs_name}||(exit 8))&&(Set APPENDLOG=1&&Set TaskUser=$${config_adminse_name}&&Set TaskPass=$${config_adminse_passwd}&&call $WPKGROOT\\wpkg-install.bat&net use * /delete /y)"
# Commande executee par $config_adminse_name pour executer wpkg sur le poste
TASKRUNWPKG='{%{ComSpec}%} /C cscript {%{Windir}%}\\wpkg-client.vbs /debug /notempo /cpuLoad 80&pause'
#variable WPKGDIR deja definie



echo "Generation des job"
[ -e /var/sambaedu/Progs/ro/$INSTTASKJOB ] && rm /var/sambaedu/Progs/ro/$INSTTASKJOB
[ -e /var/sambaedu/Progs/ro/$RUNWPKGJOB ] && rm /var/sambaedu/Progs/ro/$RUNWPKGJOB


#############################
## Fix for wine when running from sudo
#export HOME=/root
#############################
#cd /tmp
#echo "Creation du job CPAU d install sous le compte $${config_adminse_name}"
#env WINEDEBUG=-all wine /home/netlogon/CPAU.exe -u "$$config_adminse_name" -wait  -p "$xppass" -file $INSTTASKJOB -lwp -c -hide -ex "$TASK" -enc > /dev/null 
#echo "Creation du lien de lancement manuel de wpkg"
#env WINEDEBUG=-all wine /home/netlogon/CPAU.exe -u "$$config_adminse_name" -wait  -p "$xppass" -file $RUNWPKGJOB -lwp -c -hide -ex "$TASKRUNWPKG" -enc > /dev/null
#[ ! -d /home/netlogon/machine ] && mkdir /home/netlogon/machine
#mv -f $INSTTASKJOB /var/sambaedu/Progs/ro/
#chown admin:admins /var/sambaedu/Progs/ro/$INSTTASKJOB
#mv -f $RUNWPKGJOB /var/sambaedu/Progs/ro/
#chown admin:admins /var/sambaedu/Progs/ro/$RUNWPKGJOB
#
## creation du raccourci sur le bureau d'admin (ou admins)
##[ -e "/home/templates/admins/Bureau/Applications\ Wpkg.lnk" ] && echo "Suppression du raccourci du template admins" && rm "/home/templates/admins/Bureau/Applications\ Wpkg.lnk"
##[ -e "/home/templates/admin/Bureau/Applications\ Wpkg.lnk" ] && echo "Suppression du raccourci du template admin" && rm "/home/templates/admin/Bureau/Applications\ Wpkg.lnk"
#
##env WINEDEBUG=-all wine $WPKGDIR/tools/nircmdc.exe shortcut $CPAU ".\\" "Applications Wpkg" "-dec -lwp -cwd c:\\ -file $RUNWPKGJOB" %%windir%%\\system32\\setup.exe
#
#if [ -d /home/templates/admins ]; then
#    mkdir -p /home/templates/admins/Bureau
#	TEMPLATE="admins"
#    echo "Creation du raccourci Applications WPKG sur le bureau des admins"
#else
#	TEMPLATE="admin"
#    mkdir -p /home/templates/admin/Bureau
#	echo "Creation du raccourci Applications WPKG sur le bureau d'admin"
#fi
#
#FINDCMD="@if not exist \"%LOGONSERVER%\\\\admhomes\\\\templates\\\\$TEMPLATE\\\\Bureau\\\\Applications Wpkg.lnk\" (\\\\\\\\${config_se4fs_name}\\\\install\\\\wpkg\\\\tools\\\\nircmdc.exe shortcut \\\\\\\\${config_se4fs_name}\\\\netlogon\\\\CPAU.exe \"\\\\\\\\${config_se4fs_name}\\\\admhomes\\\\templates\\\\$TEMPLATE\\\\Bureau\" \"Applications Wpkg\" \"-dec -lwp -cwd c:\\\\ -file \\\\\\\\${config_se4fs_name}\\\\Progs\\\\ro\\\\$RUNWPKGJOB\" %windir%\\\\system32\\\\setup.exe"
#CMDINSTALL="@if not exist \"%LOGONSERVER%\\admhomes\\templates\\$TEMPLATE\\Bureau\\Applications Wpkg.lnk\" (\\\\${config_se4fs_name}\\install\\wpkg\\tools\\nircmdc.exe shortcut $CPAU \"\\\\${config_se4fs_name}\\admhomes\\templates\\$TEMPLATE\\Bureau\" \"Applications Wpkg\" \"-dec -lwp -cwd c:\\ -file \\\\${config_se4fs_name}\\Progs\\ro\\$RUNWPKGJOB\" %windir%\\system32\\setup.exe & copy /Y \"\\\\${config_se4fs_name}\\admhomes\\templates\\$TEMPLATE\\Bureau\\Applications Wpkg.lnk\" \"\\\\${config_se4fs_name}\\admin\\profil\\Bureau\\Applications  Wpkg.lnk\") ELSE (if exist \"\\\\${config_se4fs_name}\\admin\\profil\\Bureau\\Applications  Wpkg.lnk\" del /F /Q \"\\\\${config_se4fs_name}\\admin\\profil\\Bureau\\Applications  Wpkg.lnk\")"
#
#
#LOGONSCRIPT="/home/templates/$TEMPLATE/logon.bat"
#TEST=""
#[ -e $LOGONSCRIPT ] && TEST=$(cat $LOGONSCRIPT | grep "$FINDCMD" | grep -v "::" | grep -v "rem")
#
##echo "TEST :$TEST-FINDCMD=$FINDCMD"
#if [ ! "$TEST" = "" ]; then
#    echo "La commande de creation du racourci Applications WPKG est deja presente."
#else
#    echo "Commande de creation du raccourci Applications WPKG ajoutee a $LOGONSCRIPT."
#	[ -e "/home/admin/profil/Bureau/Applications Wpkg.lnk" ] && echo "Suppression du raccourci invalide (ancienne generation wpkg) du Bureau d'admin" && rm "/home/admin/profil/Bureau/Applications Wpkg.lnk"
#	echo "$CMDINSTALL" >> $LOGONSCRIPT
#    #recode $script_charset..CP850 $LOGONSCRIPT
#    todos $LOGONSCRIPT
#    chown admin:admins $LOGONSCRIPT
#    chmod 770 $LOGONSCRIPT
#fi
#
#
#echo "Creation du job pour lancer wpkg-repair.bat"
#wpkgRepairJOB=wpkg-repair.job
#wpkgRepairBAT=\\\\${config_se4fs_name}\\install\\wpkg\\wpkg-repair.bat
# env WINEDEBUG=-all wine /home/netlogon/CPAU.exe -u "$$config_adminse_name" -wait  -p "$xppass" -file $wpkgRepairJOB -lwp -c -hide -ex "(net use \\\\${config_se4fs_name}||exit 8)&&(set TaskUser=$$config_adminse_name&&set TaskPass=$xppass&&call $wpkgRepairBAT&net use * /delete /y)" -enc > /dev/null 
# mv -f $wpkgRepairJOB /var/sambaedu/Progs/ro/
#chown admin:admins /var/sambaedu/Progs/ro/$wpkgRepairJOB

# On supprime toute reference a CPAU.exe dans installdll.
# En cas de presence, on vire aussi toute reference a wpkg-client.vbs : cette methode permet de supprimer une ligne creee en double dans la version testing de 2.0
TEST=""
#FINDCMD="\\\\\\\\${config_se4fs_name}\\\\Progs\\\\install\\\\installdll\\\\CPAU.exe"
#[ -e /home/templates/base/logon.bat ] && TEST=$(cat /home/templates/base/logon.bat | grep "$FINDCMD" )
#if [ ! "$TEST" = "" ]; then
#	# Suppression de la ligne en double introduite dans la version testing lors des tests de la 2.0
#	sed -i /home/templates/base/logon.bat -e 's/%WinDir%\\wpkg-client.vbs/##### delete me #####/g'
#	sed -i /home/templates/base/logon.bat -e "/##### delete me #####/d"
#	# pour modifier le chemin de job CPAU personnels :
#	echo "Correction du lien vers CPAU.exe dans base/logon.bat"
#	sed -i /home/templates/base/logon.bat -e 's/\\\\'${config_se4fs_name}'\\Progs\\install\\installdll\\CPAU.exe/\\\\'${config_se4fs_name}'\\netlogon\\CPAU.exe/g'
#fi



## Nettoyage ancienne commande
#sed -i "/^@if \"%OS%\"==\"Windows_NT\"/d" /home/templates/base/logon.bat
#
##echo "Modification (si besoin) du script de login de base"
# Commande a placer dans le script de login des utilisateurs
#CMDINSTALL="@if not exist \"%WinDir%\\wpkg-client.vbs\" $CPAU -dec -lwp -hide -cwd %SystemDrive%\\ -file \\\\${config_se4fs_name}\\Progs\\ro\\$INSTTASKJOB 2>NUL >NUL"
#FINDCMD="@if not exist \"%WinDir%\\\\wpkg-client.vbs\" \\\\\\\\${config_se4fs_name}\\\\netlogon\\\\CPAU.exe -dec -lwp -hide -cwd %SystemDrive%\\\\ -file \\\\\\\\${config_se4fs_name}\\\\Progs\\\\ro\\\\$INSTTASKJOB 2>NUL >NUL"
#
#TEST=""
#[ -e /home/templates/base/logon.bat ] && TEST=$(cat /home/templates/base/logon.bat | grep "$FINDCMD" | grep -v "::" | grep -v "rem")
#if [ ! "$TEST" = "" ]; then
#	echo "La commande d'installation de wpkg existe dans logon.bat et n'est pas commentee."
#else
#	echo "Commande d'installation de wpkg ajoutee a /home/templates/base/logon.bat"
#	#echo "$CMDINSTALL"
#    echo "$CMDINSTALL" >> /home/templates/base/logon.bat
#    #recode $script_charset..CP850 /home/templates/base/logon.bat
#    todos /home/templates/base/logon.bat
#    chown admin:admins /home/templates/base/logon.bat
#    chmod 770 /home/templates/base/logon.bat
#fi
#
## Commande a placer dans le script de login des utilisateurs
#CMDINSTALL="Rem @if \"%COMPUTERNAME%\"==\"PosteProblemeWpkg\" call \\\\${config_se4fs_name}\\Progs\\install\\wpkg-diag.bat 2>NUL >NUL"
#FINDCMD="Rem @if \"%COMPUTERNAME%\"==\"PosteProblemeWpkg\" call \\\\\\\\${config_se4fs_name}\\\\Progs\\\\install\\\\wpkg-diag.bat 2>NUL >NUL"
#
#TEST=""
#[ -e /home/templates/base/logon.bat ] && TEST=$(cat /home/templates/base/logon.bat | grep "$FINDCMD" | grep -v "::" | grep -v "rem")
##echo "TEST :$TEST-FINDCMD=$CMDINSTALL"
#if [ ! "$TEST" = "" ]; then
#    echo "La commande de diagnostique wpkg existe dans logon.bat sous sa forme d'origine."
#else
#    echo "Commande de diagnostique wpkg ajoutee commentee a /home/templates/base/logon.bat"
#    echo "$CMDINSTALL" >> /home/templates/base/logon.bat
#    #recode $script_charset..CP850 /home/templates/base/logon.bat
#    todos /home/templates/base/logon.bat
#    chown admin:admins /home/templates/base/logon.bat
#    chmod 770 /home/templates/base/logon.bat
#fi


#--------Fin de la partie remplacant le lancement manuel de wpkg-config.bat-----------#


# Client wpkg execute par la tâche planifiee.
# Mise a jour du parametre ${config_se4fs_name} dans wpkg-client.vbs
sed "s/\${config_se4fs_name}/${config_se4fs_name}/g" $WPKGDIR/wpkg-client.vbs-original > $WPKGDIR/wpkg-client.vbs
todos $WPKGDIR/wpkg-client.vbs
echo "Script $WPKGDIR/wpkg-client.vbs cree."


# Initialisation de profiles.xml, hosts.xml et initvars_se4.bat
chown www-admin:root /usr/share/sambaedu/scripts/update_hosts_profiles_xml.sh
chmod +x /usr/share/sambaedu/scripts/update_hosts_profiles_xml.sh
chown www-admin:root /usr/share/sambaedu/scripts/update_droits_xml.sh
chmod +x /usr/share/sambaedu/scripts/update_droits_xml.sh
bash /usr/share/sambaedu/scripts/update_hosts_profiles_xml.sh "$computersRdn" "$parcsRdn" "$ldap_base_dn"
echo "Fichiers hosts.xml et profiles.xml crees."
bash /usr/share/sambaedu/scripts/update_droits_xml.sh
echo "Fichier droits.xml cree."
chown www-admin:root /usr/share/sambaedu/scripts/wpkg_initvars.sh
chmod +x /usr/share/sambaedu/scripts/wpkg_initvars.sh
bash /usr/share/sambaedu/scripts/wpkg_initvars.sh
echo "Fichier initvars_se4.bat cree."
chown www-admin:root /usr/share/sambaedu/scripts/wakeonlan
chmod +x /usr/share/sambaedu/scripts/wakeonlan

# Initialisation de Touslespostes.xml
if [ -d "$WPKGDIR/hosts" ]; then
    mkdir -p "$WPKGDIR/hosts"
fi
TOUSLESPOSTESXML=$WPKGDIR/hosts/Touslespostes.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $TOUSLESPOSTESXML
echo "<wpkg>" >> $TOUSLESPOSTESXML
echo "<host name=\".+\" profile-id=\"_TousLesPostes\" />" >> $TOUSLESPOSTESXML
echo "</wpkg>" >> $TOUSLESPOSTESXML
recode $script_charset..CP850 $TOUSLESPOSTESXML
todos $TOUSLESPOSTESXML
echo "Fichier $TOUSLESPOSTESXML cree."

# on efface le fichier cree inutilement : non fonctionnel
if [ -e $WPKGDIR/profiles/Touslespostes.xml ]; then
	rm -f $WPKGDIR/profiles/Touslespostes.xml
fi

# Initialisation de unattended.xml
WPKGPROFILEUNATTEND=$WPKGDIR/profiles/unattended.xml
echo "Creation du fichier $WPKGPROFILEUNATTEND pour les installations unattended."
if [ -d "$WPKGDIR/profiles" ]; then
    mkdir -p "$WPKGDIR/profiles"
fi
echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r
<profiles>\r
<profile id=\"unattended\">\r
<depends profile-id=\"_TousLesPostes\"/>\r
</profile>\r
</profiles>\r" > $WPKGPROFILEUNATTEND


# Initialisation de packages.xml
if [ ! -e "$WPKGDIR/packages.xml" ]; then
se4=$config_se4fs_name
    cat - > $WPKGDIR/packages.xml <<PACKAGESXML
<?xml version="1.0" encoding="UTF-8"?>
<packages>
    <package id="7za" name="7-Zip en ligne de commande" revision="442" reboot="false" priority="10">
        <check  type="file" condition="exists" path="%WinDir%\\7za.exe"/>
        <download url="http://www.etab.ac-caen.fr/serveurmalherbe/tools/7za/7za.exe" saveto="wpkg/tools/7za.exe" md5sum="885e9eb42889ca547f4e3515dcde5d3d"/>
        <install  cmd='"%WinDir%\\system32\\xcopy.exe" /Y %WPKGROOT%\\tools\\7za.exe %Windir%\\' />
        <remove   cmd='"%comspec%" /c del /Q /F %windir%\\7za.exe' />
    </package>
</packages>
PACKAGESXML
#     if [ ! "$script_charset" == "ISO8859-15" ]; then
#       recode $script_charset..ISO8859-15 $WPKGDIR/packages.xml
#     fi

    echo "Fichier packages.xml cree."
else
    echo "Le fichier packages.xml present est conserve."
    sed -i 's/iso-8859-1/UTF-8/' "$WPKGDIR/packages.xml"
    file --mime-encoding "$WPKGDIR/packages.xml" | grep -q iso && recode ISO8859-15..$script_charset "$WPKGDIR/packages.xml" && echo "passage format utf8 ok"
fi

# Paquet deploiementimprimantes.xml obsolete : on le rend inactif en supprimant le script qu'il execute.
# Une maj du xml rendra egalement ce package inoperant.
if [ -e /var/sambaedu/unattended/install/packages/windows/printers/ajoutpilotesimprimantes.bat ]; then
	echo "Suppression du script ajoutpilotesimprimantes.bat devenu obsolete en 2.0."
	rm -f /var/sambaedu/unattended/install/packages/windows/printers/ajoutpilotesimprimantes.bat
fi

# Dossier destine a recevoir les rapports remontes par les postes
# On donne droits rwx a $config_adminse_name
if [ ! -d $WPKGDIR/rapports ] ; then
   mkdir $WPKGDIR/rapports
fi

# Dossier des fichiers ini de config des postes
if [ ! -d $WPKGDIR/ini ] ; then
   mkdir $WPKGDIR/ini
fi

# Le fichier patche 'schtasks2k.exe', a-t-il deja ete genere par l'admin.
if [ -e $WPKGDIR/tools/schtasks2k.exe ]; then
   echo "Le fichier patche schtasks2k.exe qui a ete genere par l'admin est disponible."
fi

# Message d'information de l'installation automatique de WsusOffline.
echo ""
echo "WsusOffline sera installe automatiquement a partir de 20h45."
echo "Si l'installation echoue, vous serez averti par mail,"
echo "et sans intervention de votre part, une nouvelle tentative aura lieu,"
echo "des le lendemain a la meme heure."
echo "Si l'installation se termine correctement,"
echo "les mises a jour Microsoft a deployer sur les ordinateurs,"
echo "seront telechargees automatiquement dans la foulee, sur le serveur."
echo "Vous n'aurez plus qu'a selectionner les parcs sur lesquels"
echo "vous souhaitez deployer les mises a jour Microsoft."

echo ""
echo "Mise en place des droits sur $WPKGDIR."
setfacl -b -R $WPKGDIR
# www-admin a tous les droits sur /var/sambaedu/unattended/install
# C'est peut-etre trop. A voir...
chown -R www-admin:admins /var/sambaedu/unattended/install
setfacl -R -m u:www-admin:rwx -m d:u:www-admin:rwx /var/sambaedu/unattended/install
setfacl -R -m u:$${config_adminse_name}:rwx -m d:u:$${config_adminse_name}:rwx /var/sambaedu/unattended/install/wpkg/rapports
setfacl -R -m u::rwx -m g::rx -m o::rx -m d:m:rwx -m d:u::rwx -m d:g::rx -m d:o::rx /var/sambaedu/unattended/install


##### Suppression des rapports vieux de plus de 1 an
RAPPORTSWPKG="/var/sambaedu/unattended/install/wpkg/rapports"
if [ -e "$RAPPORTSWPKG" ];then
	echo "Recherche et suppression des anciens rapports"
	find $RAPPORTSWPKG/ -type f -maxdepth 1 -mtime +90 -delete 2>/dev/null
fi
exit 0
