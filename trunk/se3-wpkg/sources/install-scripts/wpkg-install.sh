#!/bin/bash
#
#### Installation et configuration de wpkg #####
# 
#  Auteur : Jean Le Bail
#
#    avril 2007
#    jean.lebail@etab.ac-caen.fr
#
## $Id$ ##
#
# Trucs et astuces.
#    Pour installer le client wpkg sur un poste équipé de sshd, sans attendre le prochain login d'un utilisateur :
#        ssh administrateur@IpDuPoste (authentification par mot de passe, pas par clé, sinon le net use suivant ne marche pas sous XP avec cygwin+openssh; avec copssh c'est ok)
#           net use \\\\se3 PassAdmin /user:se3\\admin
#           cmd /c \\\\se3\\Progs\\install\\installdll\\CPAU.exe -dec -lwp -cwd c:\\ -file \\\\se3\\Progs\\ro\\wpkgInstall.job
#
#        pour relancer l'exécution du client wpkg sans avoir à redémarrer le poste :
#             schtasks.exe /Run /Tn wpkg
#          ou jt.exe /LJ $WINDIR\\tasks\\wpkg.job /RJ

# Mode debug "1" ou "0"
DBG="0"

# Il faudrait peut-être définir le répertoire de travail en cours...
# cd /var/tmp

### on suppose que l'on est sous debian  ####
WWWPATH="/var/www"
### version debian  ####
if ( /bin/grep -q "3\.[01]" /etc/debian_version ) ; then
  script_charset="ISO8859-15"
else
  script_charset="UTF8"
fi
## recuperation des variables necessaires pour interoger mysql ###
if [ -e $WWWPATH/se3/includes/config.inc.php ]; then
   dbhost=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbhost=" | cut -d = -f2 | cut -d \" -f2`
   dbname=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbname=" | cut -d = -f 2 |cut -d \" -f 2`
   dbuser=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbuser=" | cut -d = -f 2 | cut -d \" -f 2`
   dbpass=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbpass=" | cut -d = -f 2 | cut -d \" -f 2`
else
   echo "Fichier de configuration inaccessible, le script ne peut se poursuivre."
   exit 1
fi

#mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N


echo "Installation de wpkg : installation automatique d'applications sur clients Windows 2000 et XP."
echo ""
if [ ! -d /var/se3/unattended/install ]; then
   echo "Le répertoire /var/se3/unattended/install n'existe pas"
   echo "Il aurait dû être créé lors de l'installation d'unattended."
   echo "Echec de l'installation."
   exit 1
fi

URLSE3=`echo "SELECT value FROM params WHERE name='urlse3'" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N`
SE3=`gawk -F' *= *' '/netbios name/ {print $2}' /etc/samba/smb.conf`
if [ -z "$SE3" ] ; then
   echo "Nom netbios du serveur samba introuvable."
   exit 1
fi
WPKGDIR="/var/se3/unattended/install/wpkg"
WPKGROOT="\\\\$SE3\\install\\wpkg"

# Compte administrateur local des postes
ADMINSE3=`gawk -F'=' '/compte_admin_local/ {gsub("\r","");print $2}' /var/se3/Progs/install/installdll/confse3.ini`
PASSADMINSE3=`echo "SELECT value FROM params WHERE name='xppass'" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N`


# adminse3 maintenant par defaut dans l'annuaire ldap
# On pourrait remettre ce test dans un des scripts de /usr/share/se3/scripts/
#if [ "$PASSADMINSE3" != "`gawk -F'=' '/password_admin_local/ {gsub("\r","");printf("%s", $2)}' /var/se3/Progs/install/installdll/confse3.ini`" ]; then
#   echo "Erreur le mot de passe d'adminse3 trouvé dans var/se3/Progs/install/installdll/confse3.ini"
#   echo " ne correspond pas à celui indiqué dans la table params de se3db."
#   echo " Réglez ce problème avant de reprendre l'installation."
#   echo ""
#   echo "Echec de l'installation."
#   exit 1
#fi

# Téléchargement des packages nécessaires
# les paquets nécessaire sont déjà là grace à la gestion des dépendances
# donc ce qui suit est inutile. Normalement ....
# sysutils pour unix2dos
if [ ! -x "`which unix2dos`" ] ; then
   echo "Installation du paquet sysutils"; 
   apt-get install sysutils; 
   if [ ! -x "`which unix2dos`" ] ; then
       echo "Erreur d'installation de sysutils"
       exit 1
    fi
fi

# unzip 
if [ ! -x "`which unzip`" ] ; then
    echo "Installation du paquet unzip"; 
    apt-get install unzip;
    if [ ! -x "`which unzip`" ] ; then 
        echo "Erreur d'installation du paquet unzip."
        exit 1
    fi
fi
echo ""

if [ ! -d $WPKGDIR ]; then
   echo "Erreur le répertoire $WPKGDIR n'existe pas."
   echo ""
   echo "Echec de l'installation."
   exit 1
fi


if [ ! -d $WPKGDIR/tools ]; then
   echo "Bizarre : le répertoire $WPKGDIR/tools n'existe pas !!!"
   mkdir /var/se3/unattended/install/wpkg/tools
fi
if [ ! -d $WPKGDIR/tools ]; then
   echo "Erreur : le répertoire $WPKGDIR/tools n'a pas pu être créé."
   exit 1
fi

# Téléchargements pour mettre à jour les postes Windows qui en ont besoin
if [ ! -d /var/se3/unattended/install/packages/windows ] ; then
   mkdir -p /var/se3/unattended/install/packages/windows 
fi
cd /var/se3/unattended/install/packages/windows

# WindowsXP-Windows2000-Script56
if [ ! -e WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe ] ; then
   echo "Téléchargement de WindowsScript56 (http://download.microsoft.com/download/e/a/9/ea9b9bab-0acf-47c4-8c48-75133f499e4d/WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe)."
   if ( ! wget 'http://download.microsoft.com/download/e/a/9/ea9b9bab-0acf-47c4-8c48-75133f499e4d/WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe' ) ; then
      echo "Erreur de téléchargement de WindowsScript56."
      echo "  Vous pourrez le télécharger plus tard à partir de l'adresse :"
      echo "  http://www.microsoft.com/downloads/details.aspx?FamilyID=c717d943-7e4b-4622-86eb-95a22b832caa&DisplayLang=fr"
      echo "  et placer WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe"
      echo "  dans \\\\$SE3\\install\\packages\\windows\\ ."
      if [ -e WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe ] ; then
         rm WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe
      fi
   fi
fi

# Windows Installer 3.1 (v2)
if [ ! -e WindowsInstaller-KB893803-v2-x86.exe ] ; then
   echo "Téléchargement de Windows Installer 3.1 (v2) (http://download.microsoft.com/download/1/4/7/147ded26-931c-4daf-9095-ec7baf996f46/WindowsInstaller-KB893803-v2-x86.exe)."
   if ( ! wget 'http://download.microsoft.com/download/1/4/7/147ded26-931c-4daf-9095-ec7baf996f46/WindowsInstaller-KB893803-v2-x86.exe' ) ; then
      echo "Erreur de téléchargement de Windows Installer 3.1 (v2)."
      echo "  Vous pourrez le télécharger plus tard et placer WindowsInstaller-KB893803-v2-x86.exe"
      echo "  dans \\\\$SE3\\install\\packages\\windows\\ ."
      if [ -e WindowsInstaller-KB893803-v2-x86.exe ] ; then
         rm WindowsInstaller-KB893803-v2-x86.exe
      fi
   fi
fi

# MSXML (Microsoft Core XML Services) 6.0
if [ ! -e msxml6.msi ] ; then
   echo "Téléchargement de MSXML (Microsoft Core XML Services) 6.0 (http://download.microsoft.com/download/8/a/4/8a4bae5b-95e9-4179-a838-1e75cf330a48/msxml6.msi)."
   if ( ! wget 'http://download.microsoft.com/download/8/a/4/8a4bae5b-95e9-4179-a838-1e75cf330a48/msxml6.msi' ) ; then
      echo "Erreur de téléchargement de MSXML (Microsoft Core XML Services) 6.0."
      echo "  Vous pourrez le télécharger plus tard et placer msxml6.msi"
      echo "  dans \\\\$SE3\\install\\packages\\windows\\ ."
      if [ -e msxml6.msi ] ; then
         rm msxml6.msi
      fi
   fi
fi

cd -

cd $WPKGDIR/tools

# jt pour définir une tache en ligne de commande dans le planificateur de tache
if [ ! -e jt.exe ] ; then
   if [ ! -e jt.zip ] ; then
      echo "Téléchargement de l'utilitaire jt.exe (http://mvps.org/winhelp2002/jt.zip)."
      if ( ! wget --tries=3 "http://mvps.org/winhelp2002/jt.zip" ) ; then
         if [ -e jt.zip ] ; then
            rm jt.zip
         fi
         echo "Téléchargement de l'utilitaire jt.exe : nouvel essai avec l'url 'ftp://ftp.microsoft.com/reskit/win2000/jt.zip'."
         if ( ! wget --tries=3 "ftp://ftp.microsoft.com/reskit/win2000/jt.zip" ) ; then
            echo "Erreur de téléchargement de jt.zip."
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
      echo "jt.exe pourra, par la suite, être déposé dans $WPKGROOT\\tools par l'admin."
   fi
else
   echo "L'utilitaire jt.exe était déjà disponible."
fi

#  Quelques utilitaires bien pratiques pour gérer les Windows

RebootSpecial=""
# PsTools pour psshutdown.exe pslist.exe ...
# Depuis que sysinternals ete rachete par Microsoft, il faut ajouter /accepteula aux options des commandes :(
if [ ! -e psshutdown.exe ] || [ ! -e pslist.exe ] ; then
   if [ ! -e PsTools.zip ]; then
      echo "Téléchargement des PsTools (http://download.sysinternals.com/Files/PsTools.zip)."
      if ( ! wget "http://download.sysinternals.com/Files/PsTools.zip" ) ; then
        echo "Erreur de téléchargement."
        if [ -e PsTools.zip ]; then
          rm PsTools.zip
        fi
      fi
   fi
   if [ -e PsTools.zip ]; then
      if ( ! unzip -o PsTools.zip ) ; then
         echo "Erreur unzip -o PsTools.zip"
      fi
   fi
   if [ -e psshutdown.exe ] && [ -e pslist.exe ] ; then
      echo "Les pstools sont maintenant disponibles.";
#       RebootSpecial="/rebootcmd:special"
#       if [ -e PsTools.zip ]; then
#          if ( ! rm PsTools.zip ) ; then
#             echo "Erreur rm PsTools.zip"
#          fi
#       fi
   else
      echo "Les PsTools ne sont pas disponibles ! Ressayez plus tard ...";
   fi
else
   echo "Les PsTools étaient déjà disponibles."
#    RebootSpecial="/rebootcmd:special"
fi   

# SetAcl (déjà dans le paquet)
# http://ovh.dl.sourceforge.net/sourceforge/setacl/setacl-cmdline-2.0.2.0-binary.zip
if [ ! -e SetACL.exe ]; then
   if [ ! -e setacl-cmdline-2.0.2.0-binary.zip ]; then
      echo "Téléchargement de l'utilitaire SetACL (http://ovh.dl.sourceforge.net/sourceforge/setacl/setacl-cmdline-2.0.2.0-binary.zip)."
      if ( ! wget --tries=3 "http://ovh.dl.sourceforge.net/sourceforge/setacl/setacl-cmdline-2.0.2.0-binary.zip" ) ; then
         echo "Erreur de téléchargement de setacl-cmdline-2.0.2.0-binary.zip."
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
      echo "SetACL.exe pourra, par la suite, être déposé dans $WPKGROOT\\tools par l'admin."
   fi
else
   echo "L'utilitaire SetACL.exe était déjà disponible."
fi   

# wget.exe (déjà dans le paquet)
if [ ! -e wget.exe ] ; then
   echo "Téléchargement de l'utilitaire wget.exe (http://users.ugent.be/~bpuype/cgi-bin/fetch.pl?dl=wget/wget.exe)."
   if ( ! wget --tries=3 "http://users.ugent.be/~bpuype/cgi-bin/fetch.pl?dl=wget/wget.exe" ) ; then 
      echo "Erreur de téléchargement de wget.exe."
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
      echo "wget.exe pourra, par la suite, être déposé dans $WPKGROOT\\tools par l'admin."
   fi
else
   echo "L'utilitaire wget.exe était déjà disponible."
fi

# md5sum.exe (déjà dans le paquet)
if [ ! -e md5sum.exe ] ; then
   if [ ! -e md5sum-w32.zip ] ; then 
      echo "Téléchargement de l'utilitaire md5sum.exe (http://ftp.fr.debian.org/debian/tools/md5sum-w32.zip)."
      if ( ! wget --tries=3 "http://ftp.fr.debian.org/debian/tools/md5sum-w32.zip" ) ; then 
         echo "Erreur de téléchargement de md5sum-w32.zip."
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
      echo "md5sum.exe pourra, par la suite, être déposé dans $WPKGROOT\\tools par l'admin."
   fi
else
   echo "L'utilitaire md5sum.exe était déjà disponible."
fi

cd -

CPAU="\\\\$SE3\\netlogon\\CPAU.exe"

# priorité d'exécution de wpkg sur les clients
# PRIORITY=/LOW|/BELOWNORMAL|/NORMAL|/ABOVENORMAL|/HIGH|/REALTIME
PRIORITY=/BELOWNORMAL

CONFIGBAT="/var/se3/Progs/install/wpkg-config.bat"

# Suppression de l'ancien script exécuté avant wpkg-se3.js
# Maintenant les options du client sont définies dans l'interface.
if [ -e $WPKGDIR/wpkgAvant.bat ]; then
   rm $WPKGDIR/wpkgAvant.bat
   echo "Ancien script $WPKGDIR/wpkgAvant.bat supprimé (il n'est plus utilisé dans cette version)."
fi

# Script de démarrage des anciens clients wpkg 
# C'est maintenant wpkg-client.vbs (client exécuté au boot du poste) qui lance directement wpkg-se3.js
#--------Début wpkg-se3.bat-----------#
cat - > $WPKGDIR/wpkg-se3.bat <<WPKGSE3BAT
:: Ce fichier assure la mise a jour des anciens clients
:: Ensuite il n'est plus utilise
:: ## $Id$ ##
@Echo OFF
Set Silent=1
Echo %date% %time% Mise à jour du client wpkg.
:: Lancement de wpkg-repair.bat à l'aide du job wpkg-repair.job
If Not Exist \\\\$SE3\\Progs\\ro\\wpkg-repair.job Goto NoWpkgRepairJob
Echo Lancement du job CPAU wpkg-repair 
\\\\$SE3\\netlogon\\CPAU.exe -dec -lwp -cwd %SystemDrive%\\ -file \\\\$SE3\\Progs\\ro\\wpkg-repair.job 2>NUL >NUL
If "%ErrorLevel%"=="1907" Goto ErrAdminse3Expire
If "%ErrorLevel%"=="1326" Goto ErrAdminse3BadPassword
If Not "%ErrorLevel%"=="0" Echo Erreur %ErrorLevel% lors de l'exécution de 'CPAU.exe -dec -lwp -cwd %SystemDrive%\\ -file \\\\$SE3\\Progs\\ro\\wpkg-repair.job'

echo.
echo Le rapport de la mise à jour du client est disponible ici :
echo ^</pre^>
echo  ^<a href="$URLSE3/wpkg/index.php?logfile=%COMPUTERNAME%.maj"^>$URLSE3/wpkg/index.php?logfile=%COMPUTERNAME%.maj^</a^>
echo ^<pre^>

Goto Done

:NoWpkgRepairJob
echo Erreur : Fichier \\\\$SE3\\Progs\\install\\wpkg-repair.job absent !
echo   En tant qu'admin, relancer :
echo   \\\\$SE3\\Progs\\install\\wpkg-config.bat
Goto Done

:ErrAdminse3BadPassword
echo Erreur : Le mot de passe d'adminse3 sur %COMPUTERNAME% n'est pas correct !
echo   Revoir la configuration du compte 'adminse3' sur %COMPUTERNAME%.
Goto Done

:ErrAdminse3Expire
echo Erreur : Le compte adminse3 a un mot de passe qui expire.
echo   Revoir la configuration du compte 'adminse3' sur %COMPUTERNAME%.
Goto Done

:Done
echo Fin de wpkg-se3.bat
WPKGSE3BAT
#--------Fin wpkg-se3.bat-----------#
recode $script_charset..CP850 $WPKGDIR/wpkg-se3.bat
unix2dos $WPKGDIR/wpkg-se3.bat
chmod 755 $WPKGDIR/wpkg-se3.bat
echo "Script $WPKGDIR/wpkg-se3.bat créé."

# Suppression de l'ancien script exécuté apres wpkg-se3.js
if [ -e $WPKGDIR/wpkgApres.bat ]; then
   rm $WPKGDIR/wpkgApres.bat
   echo "Ancien script $WPKGDIR/wpkgApres.bat supprimé (il n'est plus utilisé dans cette version)."
fi

# Script d'installation de la tache planifiée sur le poste
# Est exécuté sous local\adminse3 avec CPAU l'authentification au serveur etant deja faite
#--------Début wpkg-install.bat-----------#
cat - > $WPKGDIR/wpkg-install.bat <<PREINSTBAT
:: Script d'installation de wpkg sur le client.
:: S'execute avec le compte local $ADMINSE3 grace a CPAU, 
::    l'authentification sur le serveur est deja faite.
::
:: ## $Id$ ##

If "%SILENT%"=="1" @Echo OFF
Set WPKGROOT=$WPKGROOT

:: Pour executer wpkg aussitot apres l'installation du client sur les postes
If "%NoRunWpkgJS%"=="" Set NoRunWpkgJS=0
If Exist "%SystemRoot%\\netinst\\nowpkg.txt" Set NoRunWpkgJS=1
If "%NoRunWpkgJS%"=="1" Echo L'installation des applications ne sera effectuee qu'au prochain boot.

:: Pour supprimer la temporisation avant execution de wpkg-se3.js
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

:: Copie sur le poste local des fichiers nécessaires
Set REGEXE=%WinDir%\\system32\\reg.exe
If Exist "%REGEXE%" Goto REGEXEFOUND
If Exist \\\\$SE3\\install\\wpkg\\tools\\reg.exe copy /Y /B /V \\\\$SE3\\install\\wpkg\\tools\\reg.exe "%REGEXE%"
If Exist "%REGEXE%" Goto REGEXEFOUND
echo L'utilitaire reg.exe est introuvable.
echo A partir d'un WinXP, recopiez %WinDir%\\system32\\reg.exe dans \\\\$SE3\\install\\wpkg\\tools\\ 
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

echo Mise a jour WindowsScriptHost 5.6.0.8831
If Exist %WPKGROOT%\\..\\packages\\windows\\WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe Goto SETUP56
echo Le fichier "WindowsXP-Windows2000-Script56-KB917344-x86-fra.exe" est absent. 
echo   Telechargez-le depuis l'adresse 
echo   http://www.microsoft.com/downloads/details.aspx?FamilyID=c717d943-7e4b-4622-86eb-95a22b832caa&DisplayLang=fr
echo   et placez ce fichier dans \\\\$SE3\\install\\packages\\windows\\ 
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

:WININSTALLER
echo Version de Windows Installer
cscript.exe //NoLogo %WPKGROOT%\\tools\\fileversion.vbs %WinDir%\\system32\\msiexec.exe GE 3.1.4000.1823
If "%ErrorLevel%"=="0" Goto MSXML
echo Mise a jour Windows Installer 3.1 (v2) 
If Exist %WPKGROOT%\\..\\packages\\windows\\WindowsInstaller-KB893803-v2-x86.exe Goto SETUPMSI
echo Le fichier "%WPKGROOT%\\..\\packages\\windows\\WindowsInstaller-KB893803-v2-x86.exe" est absent. 
echo   Telechargez-le depuis l'adresse 
echo   http://www.microsoft.com/downloads/details.aspx?FamilyID=889482fc-5f56-4a38-b838-de776fd4138c&DisplayLang=fr 
echo   et placez ce fichier dans \\\\$SE3\\install\\packages\\windows\\ 
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
echo   et placez ce fichier dans \\\\$SE3\\install\\packages\\windows\\ 
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

::@Set OptJT=%OptJT% /SJ ApplicationName="%Windir%\\system32\\cscript.exe" 
::@Set OptJT=%OptJT% Parameters="%Windir%\\wpkg-client.vbs"
@Set OptJT=%OptJT% /SJ ApplicationName="%ComSpec%" 
@Set OptJT=%OptJT% Parameters="/C start $PRIORITY %Windir%\\system32\\cscript.exe //B %Windir%\\wpkg-client.vbs"

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
unix2dos $WPKGDIR/wpkg-install.bat
echo "Script $WPKGDIR/wpkg-install.bat créé."

# Chemin du job d'installation de wpkg sur un poste pour un utilisateur lambda
INSTTASKJOB="\\\\$SE3\\Progs\\ro\\wpkgInstall.job"
# Chemin du job d'exécution de wpkg sur un poste pour un utilisateur lambda
RUNWPKGJOB="\\\\$SE3\\Progs\\ro\\wpkgRun.job"
# Commande à placer dans le script de login des utilisateurs
CMDINSTALL="@if \"%%OS%%\"==\"Windows_NT\" if not exist \"%%WinDir%%\\wpkg-client.vbs\" $CPAU -dec -lwp -hide -cwd %%SystemDrive%%\\ -file $INSTTASKJOB 2^>NUL ^>NUL"
FINDCMD="@if \"\"%%OS%%\"\"==\"\"Windows_NT\"\" if not exist \"\"%%WinDir%%\\wpkg-client.vbs\"\" $CPAU -dec -lwp -hide -cwd %%SystemDrive%%\\ -file $INSTTASKJOB 2>NUL >NUL"
# Chemin du script de login
LogonBat="\\\\$SE3\\admhomes\\templates\\base\\logon.bat"
# Commande exécutée par adminse3 pour installer wpkg sur le poste
TASK="(net use \\\\$SE3||(exit 8))&&(Set APPENDLOG=1&&Set TaskUser=$ADMINSE3&&Set TaskPass=$PASSADMINSE3&&call $WPKGROOT\\wpkg-install.bat&net use * /delete /y)"
# Commande exécutée par adminse3 pour exécuter wpkg sur le poste
TASKRUNWPKG='{%%{ComSpec}%%} /C cscript {%%{Windir}%%}\\wpkg-client.vbs /debug /notempo /cpuLoad 80&pause'

# Script de diagnostic et réparation d'un client wpkg récalcitrant
# par exemple à cause d' un compt adminse3 défaillant
#--------Début wpkg-diag.bat-----------#
cat - > /var/se3/Progs/install/wpkg-diag.bat <<WPKGDIAG
:: Script de diagnostic/reparation d'un client wpkg qui ne demarre plus.
:: Verifie le compte adminse3 puis lance wpkg-repair.bat sous adminse3.
:: ## $Id$ ##
@echo OFF

:: NoRunWpkgJS=1  pour ne pas lancer wpkg avec ce script.
:: A priori, il est deja en cours d'execution.
:: Il sera lance au prochain boot du poste.
Set NoRunWpkgJS=1

:: Initialisation des variables
::   Nom du serveur SE3 utilise lors de l'install de wpkg
Set Se3=$SE3
::   Fichier de log du dignostic
If Not Exist \\\\%Se3%\\Progs\\rw\\wpkg mkdir \\\\%Se3%\\Progs\\rw\\wpkg
Set LOG=\\\\%Se3%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log
echo Diagnostic de l'installation du client Wpkg sur '%COMPUTERNAME%' >%LOG%
echo. 
echo %date% %time% Debut du diagnostic. >>%LOG%
echo. >>%LOG%

:: Test du compte adminse3
::   Le compte adminse3 existe-t-il ?
net user adminse3 >NUL
If ErrorLevel 1 Goto ErrNoAdminse3
echo Le compte adminse3 existe. >>%LOG%
net user adminse3 | find /I "Compte" | find /I "actif" | find /I "oui" >>%LOG%
If ErrorLevel 1 Goto ErrAdminse3NotActive
net user adminse3 | find /I "Le mot de passe expire" | find /I "jamais" >>%LOG%
If ErrorLevel 1 Goto ErrAdminse3Expire
net user adminse3 | find /I "groupes locaux" | find /I "Administrateurs" >>%LOG%
If ErrorLevel 1 Goto ErrAdminse3NotAdministrateur
net user adminse3 | find /I "Mot de passe exig" | find /I "Oui" >>%LOG%
If ErrorLevel 1 Goto ErrAdminse3NoPassword
echo. >>%LOG%

:: Lancement de wpkg-repair.bat à l'aide du job wpkg-repair.job
If Not Exist \\\\%se3%\\Progs\\ro\\wpkg-repair.job Goto NoWpkgRepairJob
Echo Lancement du job CPAU wpkg-repair >>%LOG%
\\\\%se3%\\netlogon\\CPAU.exe -dec -wait -lwp -cwd %SystemDrive%\\ -file \\\\%se3%\\Progs\\ro\\wpkg-repair.job 2>NUL >NUL
If "%ErrorLevel%"=="1907" Goto ErrAdminse3Expire
If "%ErrorLevel%"=="1326" Goto ErrAdminse3BadPassword

Goto Done

:NoWpkgRepairJob
echo Erreur : Fichier \\\\%se3%\\Progs\\install\\wpkg-repair.job absent ! >>%LOG%
echo   En tant que root sur la console du serveur, relancer : >>%LOG%
echo   /var/cache/se3_install/wpkg-install.sh >>%LOG%
Goto Done

:ErrAdminse3BadPassword
echo Erreur : Le mot de passe d'adminse3 sur %COMPUTERNAME% n'est pas correct ! >>%LOG%
echo   Revoir la configuration du compte 'adminse3' sur %COMPUTERNAME%.  >>%LOG%
Goto Done

:ErrAdminse3NoPassword
echo Erreur : Aucun mot de passe n'est exige pour adminse3.  >>%LOG%
echo   Revoir la configuration du compte 'adminse3' sur %COMPUTERNAME%.  >>%LOG%
Goto Done

:ErrAdminse3NotAdministrateur
echo Erreur : adminse3 n'est pas membre du groupe local des Administrateurs.  >>%LOG%
echo   Revoir la configuration du compte 'adminse3' sur %COMPUTERNAME%. >>%LOG%
Goto Done

:ErrAdminse3Expire
echo Erreur : Le compte adminse3 a un mot de passe qui expire.  >>%LOG%
echo   Revoir la configuration du compte 'adminse3' sur %COMPUTERNAME%.  >>%LOG%
Goto Done

:ErrAdminse3NotActive
echo Erreur : Le compte adminse3 n'est pas actif.  >>%LOG%
echo   Revoir la configuration du compte 'adminse3' sur %COMPUTERNAME%.  >>%LOG%
Goto Done

:ErrNoAdminse3
echo Erreur : Pas de compte adminse3 defini sur ce poste.  >>%LOG%
echo   Revoir l'integration du poste au domaine SAMBAEDU.  >>%LOG%
Goto Done

:Done

WPKGDIAG
#--------Fin wpkg-diag.bat-----------#
recode $script_charset..CP850 /var/se3/Progs/install/wpkg-diag.bat
unix2dos /var/se3/Progs/install/wpkg-diag.bat
# setfacl -m u::rwx -m g::rx -m o::rx /var/se3/Progs/install/wpkg-diag.bat
chmod 755 /var/se3/Progs/install/wpkg-diag.bat
echo "Script /var/se3/Progs/install/wpkg-diag.bat créé."

# Script de réparation d'un client wpkg récalcitrant
# par exemple à cause de running=true qui bloque l'exécution
#--------Début wpkg-repair.bat-----------#
cat - > $WPKGDIR/wpkg-repair.bat <<WPKGREPAIR
:: Script de diagnostic/reparation d'un client wpkg qui ne s'execute pas.
:: Il s'execute sous adminse3 (encore faut-il que ce compte soit valide !)
:: Le lancement se fait avec le job CPAU (wpkg-repair.job)
@echo OFF
Set SE3=$SE3

Set NoRunWpkgJS=1
Set CscriptRunning=1
If Not Exist \\\\%SE3%\\install\\wpkg\\tools\\pslist.exe Goto ApresTestCscript
:: Le parametre /accepteula est-il necessaire pour les pstools ?
Set ACCEPTEULA=/accepteula
\\\\%SE3%\\install\\wpkg\\tools\\pslist.exe /accepteula 2>NUL >NUL
If ErrorLevel 1 Set ACCEPTEULA=

:: Laisse une chance a l'ancien wpkg-client.vbs de se terminer
echo Attend au plus 60s que l'ancien client se termine
set BoucleAttend="x"
:AttendFinCscript
ping -n 4 127.0.0.1 >NUL
\\\\%SE3%\\install\\wpkg\\tools\\pslist.exe %ACCEPTEULA% cscript 2>NUL >NUL
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
Set REGEXE=\\\\%SE3%\\install\\wpkg\\tools\\reg.exe 1>>%LOG%
If Exist "%REGEXE%" Goto REGEXEFOUND
echo L'utilitaire reg.exe est introuvable. 1>>%LOG%
echo A partir d'un WinXP, recopiez %WinDir%\\system32\\reg.exe dans \\\\%SE3%\\install\\wpkg\\tools\\ 1>>%LOG%
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

Set LOGSRV=\\\\%SE3%\\install\\wpkg\\rapports\\%COMPUTERNAME%.maj
If Exist "%LOGSRV%" del /F /Q "%LOGSRV%"
If Exist \\\\%SE3%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log Type \\\\%SE3%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log >> %LOGSRV%
If Exist \\\\%SE3%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log del /F /Q \\\\%SE3%\\Progs\\rw\\wpkg\\%COMPUTERNAME%.log
If Exist %LOG% echo -- %date% %time% Contenu de wpkg-repair.log --- >> %LOGSRV%
If Exist %LOG% Type %LOG% >> %LOGSRV%
If Exist %LOG% echo -- Fin wpkg-repair.log --- >> %LOGSRV%
echo La suite du rapport d'installation sera disponible dans quelques instants ... >> %LOGSRV%

Rem Set SILENT=1
Set APPENDLOG=1
call \\\\%SE3%\\install\\wpkg\\wpkg-install.bat 2>%LOG%.err 1>%LOG%

echo -- %date% %time% Contenu de wpkg-install.log.err --- >> %LOGSRV%
Type %LOG%.err >> %LOGSRV%
echo -- Fin wpkg-install.log.err --- >> %LOGSRV%
echo -- Contenu de wpkg-install.log --- >> %LOGSRV%
Type %LOG% >> %LOGSRV%
echo -- Fin wpkg-install.log --- >> %LOGSRV%

WPKGREPAIR
#--------Fin wpkg-repair.bat-----------#
recode $script_charset..CP850 $WPKGDIR/wpkg-repair.bat
unix2dos $WPKGDIR/wpkg-repair.bat
echo "Script $WPKGDIR/wpkg-repair.bat créé."

#--------Début wpkg-config.bat-----------#
# A exécuter une fois par l'admin pour créer les jobs cpau et placer la commande d'installation dans 'templates\\base\\logon.bat'
cat - > $CONFIGBAT <<FINCONFIGBAT
@echo off
:: Configuration de wpkg par l'admin.
::
:: Ce fichier fait partie du module se3-wpkg du projet SambaEdu.
::     Jean Le Bail - Octobre 2007
::
:: ## $Id$ ##

echo.
echo  ######################################################
echo  #      CONFIGURATION DE WPKG pour votre réseau.      #
echo  #                                                    #
echo  #    WPKG permet de déployer automatiquement         #
echo  #    des applications sur les PC Windows XP          #
echo  #    et Windows 2000 qui ont rejoint le domaine.     #
echo  #                                                    #
echo  ######################################################
echo.

Set REPONSE=O
Set /P REPONSE=  Voulez-vous configurer wpkg maintenant ? O^|N [%REPONSE%]
if Not "%REPONSE%"=="O" if Not "%REPONSE%"=="o" Goto TCHAO
Goto CESTPARTI

:TCHAO
echo.
echo             Une autre fois peut-ˆtre ...
Goto Done

:CESTPARTI
echo.
echo             C'est parti ...
echo.

Set WPKGROOT=$WPKGROOT
Set SCHTASKEXE=%WinDir%\\system32\\schtasks.exe
Set DestExe=%WPKGROOT%\\tools\\schtasks2k.exe

Set WinType=XP
ver | find "2000" >NUL
if Not ErrorLevel 1 Set WinType=2K
if ErrorLevel 1 ver | find /I "XP" >NUL
if ErrorLevel 1 Goto No2000XP

:: Utilitaire schtasks2k.exe pour gerer les 'taches planifiees' sur Win2K et WinXp
Set SCHTASKS=schtasks2k
If Not Exist %WPKGROOT%\\tools\\schtasks2k.exe Goto MAKESCHTASKS2K
echo %WPKGROOT%\\tools\\schtasks2k.exe ‚tait d‚j… disponible.
If "%WinType%"=="XP" echo Si vous souhaitez regénérer schtasks2k.exe, 
If "%WinType%"=="XP" echo   effacez-le puis relancez wpkg-config.bat.
echo.
Goto JTorSCHTASKS2KOK
:MAKESCHTASKS2K
:: Creation de schtasks2k.exe a partir de %WinDir%\\system32\\schtasks.exe
:: Est-on bien sur un WinXP
if "%WinType%"=="XP" Goto OnXP
:: Sinon, est-ce que jt.exe est disponible pour installer une tache planifiee
if Not Exist %WPKGROOT%\\tools\\jt.exe Goto NOJT
Set SCHTASKS=jt
Goto JTorSCHTASKS2KOK

:OnXP
Set SCHTASKS=
echo Application d'un patch … schtasks.exe pour le rendre utilisable sous Windows 2000.
:: ----------------------------- patch schtasks.exe ---------------------------------------

:: Hack honteux pour rendre schtasks.exe de WinXP utilisable sous Win2k
:: D'apres une idee de http://www.windowsitpro.com/Articles/ArticleID/25186/25186.html
:: Adaptatation a la version francaise de schtasks.exe version 5.1.2600.2180
:: et automatisation de l'application du patch avec debug.

If Not Exist "%SCHTASKEXE%" Goto NoSCHTASKEXE

::Changement de repertoire
pushd %SystemDrive%\\

copy /Y /B "%SCHTASKEXE%" .\\schtasks.dat >NUL
If ErrorLevel 1 Goto ErrDupExe

:: S'agit-il de la bonne version du fichier
echo d e4f0 e4ff>patch1.txt
echo q>>patch1.txt

cmd /c debug schtasks.dat < patch1.txt >sortie.txt
type sortie.txt | find "00 E8 68 EC FF FF 85 C0-75 0F 68 7F 15 00 00 E8" >NUL

If ErrorLevel 1 Goto BadFile

:: Changement octet e4f8 : 75->EB
::    1535:E4F8 750F          JNZ     E509
:: a remplacer par
::    1535:E4F8 EB0F          JMP     E509

echo e e4f8 eb>patch2.txt
echo w>>patch2.txt
echo q>>patch2.txt
cmd /c debug schtasks.dat < patch2.txt

If ErrorLevel 1 Goto ErrDebug

:: Juste pour verifier le bon changement de l'octet.
cmd /c debug schtasks.dat < patch1.txt >sortie.txt
type sortie.txt | find "00 E8 68 EC FF FF 85 C0-EB 0F 68 7F 15 00 00 E8" >NUL

If ErrorLevel 1 Goto PatchNotDone
Echo Le patch a été appliqué avec succès.

:: Recopie de ce fichier sur le serveur
copy /Y /B schtasks.dat %DestExe% >NUL
If ErrorLevel 1 Goto ErrCopy

Goto PatchDone

:ErrDupExe
Echo Erreur de copie de "%SCHTASKEXE%" vers "%SystemDrive%\\schtasks.dat"
Goto ErreurPatch

:ErrCopy
Echo Erreur de copie de "%SystemDrive%\\schtasks.dat" vers %DestExe%
Goto ErreurPatch

:PatchNotDone
Echo Erreur : l'application du patch a échoué !
Goto ErreurPatch

:ErrDebug
Echo Erreur : La commande DEBUG a quitté avec l'erreur %ErrorLevel% !
Goto ErreurPatch

:BadFile
Echo Erreur : le fichier %SCHTASKEXE% n'est pas de la version 5.1.2600.2180
Goto ErreurPatch

:NoSCHTASKEXE
echo Erreur : le fichier %SCHTASKEXE% n'existe pas !
echo Etes-vous bien sur un Windows XP ?
Goto ErreurPatch

:ErreurPatch
Set Erreur=1

:PatchDone
:: Faire du menage
If Exist patch1.txt del /F /Q patch1.txt 2>NUL >NUL
If Exist patch2.txt del /F /Q patch2.txt 2>NUL >NUL
If Exist sortie.txt del /F /Q sortie.txt 2>NUL >NUL
If Exist schtasks.dat del /F /Q schtasks.dat 2>NUL >NUL
popd
:: Saut hors patch en cas d'erreur
If "%Erreur%"=="1" Goto PatchFail
Goto SCHTASKS2KOK

:: Yeh ! we got it !
:: ----------------------------- Fin patch schtasks.exe ---------------------------------------

:PatchFail
echo Erreur : L'application du patch au fichier SCHTASKEXE a echoué.
echo Vous pouvez tenter d'exécuter à nouveau ce script à partir d'un autre PC (Windows XP SP2).
If Exist %WPKGROOT%\\tools\\jt.exe Goto JtEstLa
Goto RECOMMANDEJT

:SCHTASKS2KOK

Set SCHTASKS=schtasks2k
echo %DestExe% est maintenant disponible.

:JTorSCHTASKS2KOK
echo.
echo Essai de %WPKGROOT%\\tools\\schtasks2k.exe 
echo   en listant les 'tâches planifiées' actuelles de ce poste :
%DestExe%
echo.
if ErrorLevel 1 Echo %DestExe%
if ErrorLevel 1 Echo   a généré une erreur : ErrorLevel=%ErrorLevel%
if ErrorLevel 1 Echo.

:: Presence jt.exe
If Exist %WPKGROOT%\\tools\\jt.exe Goto JtEstLa
:RECOMMANDEJT
echo Vous devriez télécharger l'utilitaire jt.exe à l'adresse :
echo   ftp://ftp.microsoft.com/reskit/win2000/jt.zip
echo   Et placer après décompression jt.exe dans %WPKGROOT%\\tools
echo Ainsi, vous n'aurez plus besoin du fichier patch‚ schtasks2K.exe.
echo Il vous faudra ensuite relancer ce script.
echo.
pause
Goto SetACL
:JtEstLa
Echo L'utilitaire jt.exe est disponible. 
echo   Il sera utilis‚ pour créer la tâche planifiée.
echo.

:SetACL
Set SetACL=%WPKGROOT%\\tools\\SetACL.exe
If Exist %SetACL% Goto SetACLOK
echo Vous devriez télécharger l'utilitaire SetACL à l'adresse :
echo   http://ovh.dl.sourceforge.net/sourceforge/setacl/setacl-cmdline-2.0.2.0-binary.zip
echo   Et placer après décompression SetACL.exe dans %WPKGROOT%\\tools
echo.
Goto CreationJob
:SetACLOK
echo L'utilitaire SetACL.exe est disponible
echo.

:: Recopie de reg.exe qui n'est pas disponible sous Win2k alors qu'il fonctionne parfaitement
If Exist %WinDir%\\system32\\reg.exe xcopy /Y /C /I /H /R %WinDir%\\system32\\reg.exe "%WPKGROOT%\\tools\\" >NUL
If Exist "%WPKGROOT%\\tools\\reg.exe" Echo L'utilitaire reg.exe est disponible dans %WPKGROOT%\\tools\\
If Not Exist "%WPKGROOT%\\tools\\reg.exe" Echo L'utilitaire reg.exe n'est pas disponible
echo.

:CreationJob
If Exist "$WPKGROOT\\wpkg.job" Del /F /Q "$WPKGROOT\\wpkg.job"

echo Création du job CPAU d'install sous le compte $ADMINSE3
echo $INSTTASKJOB
If Exist "$INSTTASKJOB" Del /F /Q "$INSTTASKJOB"
set TASK="$TASK"

@If "$DBG"=="1" Echo Dbg. TASK="$TASK"

@$CPAU -u $ADMINSE3 -p $PASSADMINSE3 -enc -file $INSTTASKJOB -lwp -c -ex %TASK% 2>NUL >NUL
Set TASK=
If ErrorLevel 8 Goto ErrAuthSe3
If ErrorLevel 1 Goto ErrMakeInstallJob
If Not Exist "$INSTTASKJOB" Goto ErrMakeInstallJob
echo $INSTTASKJOB : SUCCES.

echo.
echo Création du lien de lancement manuel de wpkg
Set TASKRUNWPKG="$TASKRUNWPKG"
@$CPAU -u $ADMINSE3 -p $PASSADMINSE3 -enc -file $RUNWPKGJOB -lwp -c -ex %TASKRUNWPKG% 2>NUL >NUL
%WPKGROOT%\\tools\\nircmdc.exe shortcut $CPAU "~\$folder.desktop\$" "Synchronise les applications Wpkg" "-dec -lwp -cwd c:\\ -file $RUNWPKGJOB" %%windir%%\\system32\\setup.exe
%WPKGROOT%\\tools\\nircmdc.exe execmd If Exist "~\$folder.desktop\$\\Applications Wpkg.lnk" Del /f /S "~\$folder.desktop\$\\Applications Wpkg.lnk"
%WPKGROOT%\\tools\\nircmdc.exe execmd RENAME "~\$folder.desktop\$\\Synchronise les applications Wpkg.lnk" "Applications Wpkg.lnk"

:: echo.
:: echo Création du lien pour forcer la valeur running=false
:: Set wpkgRunningFalseJOB=\\\\$SE3\\Progs\\ro\\wpkgRunningFalse.job
:: @$CPAU -u $ADMINSE3 -p $PASSADMINSE3 -enc -file "%wpkgRunningFalseJOB%" -lwp -c -ex "\\\\$SE3\\install\\wpkg\\tools\reg.exe ADD HKLM\\Software\\wpkg /v running /d false /f" 2>NUL >NUL
:: %WPKGROOT%\\tools\\nircmdc.exe shortcut $CPAU "\\\\$SE3\\Progs\\ro" "WpkgRunningFalse" "-dec -lwp -cwd c:\\ -file %wpkgRunningFalseJOB%" %%windir%%\\regedit.exe

echo.
echo Création du job pour lancer wpkg-repair.bat
Set wpkgRepairJOB=\\\\$SE3\\Progs\\ro\\wpkg-repair.job
Set wpkgRepairBAT=\\\\$SE3\\install\\wpkg\\wpkg-repair.bat
@$CPAU -u $ADMINSE3 -p $PASSADMINSE3 -enc -file "%wpkgRepairJOB%" -lwp -c -ex "(net use \\\\$SE3||exit 8)&&(set TaskUser=$ADMINSE3&&set TaskPass=$PASSADMINSE3&&call %wpkgRepairBAT%&net use * /delete /y)" 2>NUL >NUL


:: --------------Install client sur poste local------------------------------
:: Controle du compte $ADMINSE3
net user $ADMINSE3 2>NUL >NUL
If ErrorLevel 1 Goto NoAdminse3
net user $ADMINSE3 | find "Compte" | find "actif" | find "Oui" 2>NUL >NUL
If ErrorLevel 1 Goto NoAdminse3Actif
net user $ADMINSE3 | find "*Administrateurs" 2>NUL >NUL
If ErrorLevel 1 Goto NoAdminse3Admins
net user $ADMINSE3 | find "mot de passe expire" | find "Jamais" 2>NUL >NUL
If ErrorLevel 1 Goto NoAdminse3NoExpire
echo.
echo Le compte $ADMINSE3 est actif, membre du groupe 'Administrateurs'
echo    et son mot de passe n'expire jamais.
Goto AskInstallLocal

:NoAdminse3NoExpire
echo.
echo Le mot de passe de $ADMINSE3 va expirer :
net user $ADMINSE3 | find "Le mot de passe expire" 
pause
Goto AskInstallLocal

:NoAdminse3Admins
echo.
echo Le compte de $ADMINSE3 n'est pas membre du groupe des 'Administrateurs'.
pause
Goto LOGONBAT

:NoAdminse3Actif
echo.
echo Le compte local $ADMINSE3 n'est pas actif.
echo   Le test de la procédure d'installation de wpkg n'est pas possible sur ce poste.
pause
Goto LOGONBAT

:NoAdminse3
echo.
echo Le compte local $ADMINSE3 n'existe sur ce poste.
echo   Ce poste n'a vraisemblablement pas rejoint le domaine...
echo   Le test de la procédure d'installation de wpkg n'est pas possible sur ce poste.
pause
Goto LOGONBAT

:AskInstallLocal
Set REPONSE=O
echo.
echo Avant de placer la commande d'installation dans le script de login,
echo vous pouvez tester le script d'installation de wpkg sur ce poste.
echo.
echo Rmq. Les fenêtres qui s'ouvrent pour ce test, seront masquées 
echo      lors de l'installation 'normale' au login d'un utilisateur.
echo.

Set NoRunWpkgJS=1
Set /P REPONSE=  Voulez-vous installer maintenant wpkg sur ce poste ? O^|N [O]
if Not "%REPONSE%"=="O" if Not "%REPONSE%"=="o" Goto LOGONBAT
Set NoRunWpkgJS=0
echo.
echo Installation de wpkg sur ce poste : en cours...
echo Pas de temporisation avant lancement de wpkg-se3.js > "%SystemDrive%\\netinst\\wpkg-notempo.txt"
::start /wait $CPAU -dec -lwp -wait -outprocexit -cwd %SystemDrive%\\ -file $INSTTASKJOB
start /wait $CPAU -dec -lwp -wait -cwd %SystemDrive%\\ -file $INSTTASKJOB
If "%ErrorLevel%"=="0" Goto InstallWPKGSucces
Goto ErrRunJob
:InstallWPKGSucces
Set WpkgIsInstalled=1
echo Installation de wpkg sur ce poste : SUCCES.
If "%NoRunWpkgJS%"=="1" Goto LOGONBAT
echo.
If Exist %WinDir%\\wpkg.txt echo   %WinDir%\\wpkg.txt : Etat des applis wpkg de ce poste.
If Exist %WinDir%\\wpkg.log echo   %WinDir%\\wpkg.log : Log de l'exécution de wpkg-se3.js
If Not Exist %WinDir%\\wpkg.txt echo  Err. %WinDir%\\wpkg.txt absent : Pas d'état des applis disponibles.
If Not Exist %WinDir%\\wpkg.log echo  Err. %WinDir%\\wpkg.log : Pas de Log de l'exécution de wpkg.
If Exist %WPKGROOT%\\rapports\\%COMPUTERNAME%.txt echo   %WPKGROOT%\\rapports\\%COMPUTERNAME%.txt : Remontée serveur.
If Exist %WPKGROOT%\\rapports\\%COMPUTERNAME%.log echo   %WPKGROOT%\\rapports\\%COMPUTERNAME%.log : Remontée serveur.
If Not Exist %WPKGROOT%\\rapports\\%COMPUTERNAME%.txt echo  Err. %WPKGROOT%\\rapports\\%COMPUTERNAME%.txt absent : Pas de Remontée sur le serveur.
If Not Exist %WPKGROOT%\\rapports\\%COMPUTERNAME%.log echo  Err. %WPKGROOT%\\rapports\\%COMPUTERNAME%.log absent : Pas de Remontée sur le serveur.
pause
:: --------------Fin Install client sur poste local------------------------------

:LOGONBAT
:: ------------------Insert Installwpkg dans $LogonBat------------------------------
echo.
echo.
echo Commande à ajouter sur une ligne au script de login des utilisateurs :
echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo $CMDINSTALL
echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo.
If not exist $LogonBat goto NoLogonBat

echo Contenu actuel du script de login concernant 'wpkg' :
echo -------- extrait de $LogonBat -------
find /V "#" $LogonBat | find /V "Rem " | find /V "::" | find /I "wpkg"
echo -------------------------------------------------------------------
echo.
If ErrorLevel 1 Goto PASCMDLOGIN
find "$FINDCMD" $LogonBat >NUL
If Not ErrorLevel 1 Goto SameCMD
echo Une commande d'installation de wpkg semble déjà présente dans logon.bat
echo   Elle n'est cependant pas identique à la commande préconisée.
echo   Voulez-vous quand même ajouter la commande d'installation de wpkg
Set REPONSE=N
Goto AskInsertCmd

:SameCMD
echo La commande qui se trouve dans le script coïncide avec la commande préconisée.
pause
echo.
Goto WPKGOK

:PASCMDLOGIN
echo   Voulez-vous ajouter la commande d'installation de wpkg
Set REPONSE=O

:AskInsertCmd
Set /P REPONSE=  au template base logon.bat ? O^|N [%REPONSE%]
if Not "%REPONSE%"=="O" if Not "%REPONSE%"=="o" Goto NoAddTemplate
echo. >> $LogonBat
echo $CMDINSTALL >> $LogonBat
echo.
echo Nouveau contenu du script de login concernant 'wpkg' :
find /I "wpkg" $LogonBat
echo.
If ErrorLevel 1 Goto NoInstallTemplate
:: -----------------Fin Insert Installwpkg dans $LogonBat------------------------------

:WPKGOK
find /I ":: Pour resoudre un probleme de lancement de wpkg" $LogonBat >NUL
If "%ErrorLevel%"=="0" Goto WPKGGreetings
echo. >> $LogonBat
echo :: Pour resoudre un probleme de lancement de wpkg sur un poste. >> $LogonBat
echo Rem @if "%%COMPUTERNAME%%"=="PosteProblemeWpkg" call \\\\$SE3\\Progs\\install\\wpkg-diag.bat 2^>NUL ^>NUL  >> $LogonBat

:WPKGGreetings
echo.
echo Félicitation : WPKG est opérationnel sur ce serveur
echo   Il sera installé puis executé sur les postes 
echo     au prochain login d'un utilisateur.
echo   Une fois installé, WPKG s'exécute au boot du poste,
echo     après une temporisation de 30sec,
echo     sans qu'il soit nécessaire de s'authentifier.
Goto AUTODEL

:ErrAuthSe3
echo.
echo Echec d'authentification au serveur $SE3 avec le compte '$SE3\\$ADMINSE3'.
Goto Done

:NoAddTemplate
echo.
echo Félicitation : La configuration de Wpkg est terminée.
If "%InLoginScript%"=="1" Goto AUTODEL
echo   Il vous reste à ajouter la ligne de commande précédente
echo   dans les templates de votre choix.
Goto AUTODEL

:No2000XP
Set WinType=9x
echo Erreur : Vous n'êtes pas sur un poste Windows 2000 ou XP.
Goto Done

:ErrMakeInstallJob
echo Erreur : le fichier $INSTTASKJOB n'a pas pu être cré.
Goto Done

:ErrRunJob
echo Erreur : l'installation de wpkg sur ce poste a échoué. Err=%ErrorLevel%
If EXIST "%SystemDrive%\\netinst\\wpkg-notempo.txt" del /F /Q "%SystemDrive%\\netinst\\wpkg-notempo.txt"
Goto Done

:NoLogonBat
echo Erreur : le fichier $LogonBat est introuvable.
Goto NoInstallTemplate

:NoInstallTemplate
echo Erreur : le fichier template $LogonBat n'a pas pu êïtre mis à jour.
echo Ajoutez manuellement la ligne précédente au script de login des utilisateurs.
Goto Done

:NOJT
echo.
echo Erreur : Vous n'êtes pas sur un PC Windows XP et l'utilitaire jt.exe 
echo   n'est pas disponible.
echo   Téléchargez jt.zip depuis l'adresse :
echo     ftp://ftp.microsoft.com/reskit/win2000/jt.zip
echo     puis, après extraction, placez le fichier jt.exe dans le répertoire :
echo     %WPKGROOT%\\tools\\
echo   C'est ce que je vous recommande.
echo.
echo   Sinon, vous pouvez vous passer de jt.exe à condition d'exécuter ce script 
echo   à partir d'un PC Windows XP...
echo.
Goto Done

:AUTODEL
If Not Exist "%~f0" Goto Done
Set REPONSE=O
echo.
echo La gestion des applications à déployer sur les postes, 
echo   se fait à l'aide d'un navigateur web à l'adresse :
echo   $URLSE3/wpkg/  
echo.
echo Par sécurité, il serait prudent de supprimer ce fichier de configuration.
echo    Pour cela, tapez : del %~f0  
echo.
echo    En cas de besoin, vous pourrez le recréer en exécutant à nouveau
echo    '/var/cache/se3_install/wpkg-install.sh'
echo    en root, sur la console du serveur.
echo.

If Not "%WpkgIsInstalled%"=="1" Goto WpkgNotInstalled
If "%NoRunWpkgJS%"=="1" echo Wpkg s'exécutera au prochain démarrage de ce poste.
If Not "%NoRunWpkgJS%"=="1" echo Wpkg s'exécutera à nouveau à chaque démarrage de ce poste.
echo Si vous voulez exécuter wpkg maintenant, utilisez le lien
echo    'Applications Wpkg' sur le bureau de %UserName%.
echo.
:WpkgNotInstalled

@If "$DBG"=="1" Echo L'installation a été effectuée en mode DEBUG (DBG="1").
@If "$DBG"=="1" Echo   Si tout s'est bien passé, n'oubliez pas de
@If "$DBG"=="1" Echo   réexecuter ce script en mode normal (DBF="0")
@If "$DBG"=="1" Echo   pour supprimer les 'Pause' de l'exécution des scripts.
@If "$DBG"=="1" Echo.

::set /P REPONSE=Voulez-vous supprimer wpkg-config.bat maintenant ? O^|N [O]
::if Not "%REPONSE%"=="O" if Not "%REPONSE%"=="o" Goto Done
::del "%~f0"&exit 0
Goto Done

:Done
Set DestExe=
Set REPONSE=
Set SCHTASKS=
Set SetACL=
Set WinType=
Set WpkgIsInstalled=
Set WPKGROOT=

echo.
echo Fin de wpkg-config.bat
Pause
FINCONFIGBAT
#--------Fin wpkg-config.bat-----------#
recode $script_charset..CP850 $CONFIGBAT
unix2dos $CONFIGBAT
echo "Script de configuration destiné à l'admin $CONFIGBAT créé."
chown admin:admins $CONFIGBAT
chmod 770 $CONFIGBAT

# Client wpkg exécuté par la tâche planifiée.
# Mise à jour du paramètre $SE3 dans wpkg-client.vbs
sed "s/\$SE3/$SE3/g" $WPKGDIR/wpkg-client.vbs-original > $WPKGDIR/wpkg-client.vbs
unix2dos $WPKGDIR/wpkg-client.vbs
echo "Script $WPKGDIR/wpkg-client.vbs créé."

# Clés publiques ssh de www-se3 et de root disponibles pour être recopiées sur les postes lors de l'install de copssh
# Contrôle (et création si besoin) d'une clé ssh pour l'utilisateur www-se3
if [ ! -e "/var/remote_adm/.ssh/id_rsa.pub" ]; then
   if [ ! -d "/var/remote_adm/.ssh" ] ; then
      mkdir -p "/var/remote_adm/.ssh"
   fi
   chown www-se3:www-data
   chmod 700 "/var/remote_adm/.ssh"
   cd "/var/remote_adm/.ssh"
   # Creation de la clé
   sudo -u www-se3 ssh-keygen -q -b 1024 -t rsa -f id_rsa -N ''
   cd -
fi
# Contrôle (et création si besoin) d'une clé ssh pour l'utilisateur root
if [ ! -e "/root/.ssh/id_rsa.pub" ]; then
   if [ ! -d "/root/.ssh" ] ; then
      mkdir -p "/var/remote_adm/.ssh"
   fi
   chmod 700 "/root/.ssh"
   cd "/root/.ssh"
   # Creation de la clé
   ssh-keygen -q -b 1024 -t rsa -f id_rsa -N ''
   cd -
fi
# Mise à disposition des clés publiques de www-se3 et root pour adminse3
cat /var/remote_adm/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub > $WPKGDIR/authorized_keys

# Initialisation de profiles.xml, hosts.xml et initvars_se3.bat
BaseDN="`echo "SELECT value FROM params WHERE name='ldap_base_dn'" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N`"
ComputersRDN="`echo "SELECT value FROM params WHERE name='computersRdn'" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N`"
ParcsRDN="`echo "SELECT value FROM params WHERE name='parcsRdn'" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N`"
chown www-se3:root /usr/share/se3/scripts/update_hosts_profiles_xml.sh
chmod +x /usr/share/se3/scripts/update_hosts_profiles_xml.sh
chown www-se3:root /usr/share/se3/scripts/update_droits_xml.sh
chmod +x /usr/share/se3/scripts/update_droits_xml.sh
bash /usr/share/se3/scripts/update_hosts_profiles_xml.sh "$ComputersRDN" "$ParcsRDN" "$BaseDN"
echo "Fichiers hosts.xml et profiles.xml créés."
bash /usr/share/se3/scripts/update_droits_xml.sh
echo "Fichier droits.xml créé."
chown www-se3:root /usr/share/se3/scripts/wpkg_initvars.sh
chmod +x /usr/share/se3/scripts/wpkg_initvars.sh
bash /usr/share/se3/scripts/wpkg_initvars.sh
echo "Fichier initvars_se3.bat créé."
chown www-se3:root /usr/share/se3/scripts/wakeonlan
chmod +x /usr/share/se3/scripts/wakeonlan

# Initialisation de packages.xml
if [ ! -e "$WPKGDIR/packages.xml" ]; then
    SE3=`gawk -F' *= *' '/netbios name/ {print $2}' /etc/samba/smb.conf`
    cat - > $WPKGDIR/packages.xml <<PACKAGESXML
<?xml version="1.0" encoding="iso-8859-1"?>
<packages>
    <package id="time" name="Mise à l'heure du poste" revision="1" reboot="false" priority="100" notify="false" execute="always">
        <install cmd="net time \\\\$SE3 /set /yes"/>
    </package>
    
    <package id="7za" name="7-Zip en ligne de commande" revision="442" reboot="false" priority="10">
        <check  type="file" condition="exists" path="%WinDir%\\7za.exe"/>
        <download url="http://www.etab.ac-caen.fr/serveurmalherbe/tools/7za/7za.exe" saveto="wpkg/tools/7za.exe" md5sum="885e9eb42889ca547f4e3515dcde5d3d"/>
        <install  cmd='"%WinDir%\\system32\\xcopy.exe" /Y %WPKGROOT%\\tools\\7za.exe %Windir%\\' />
        <remove   cmd='"%comspec%" /c del /Q /F %windir%\\7za.exe' />
    </package>
</packages>
PACKAGESXML
    if [ ! "$script_charset" == "ISO8859-15" ]; then
      recode $script_charset..ISO8859-15 $WPKGDIR/packages.xml
    fi

    echo "Fichier packages.xml créé."
else
    echo "Le fichier packages.xml présent est conservé."
fi

# Dossier destiné à recevoir les rapports remontés par les postes
# On donne droits rwx à adminse3
if [ ! -d $WPKGDIR/rapports ] ; then
   mkdir $WPKGDIR/rapports
fi

# Dossier des fichiers ini de config des postes
if [ ! -d $WPKGDIR/ini ] ; then
   mkdir $WPKGDIR/ini
fi

# Le fichier patché 'schtasks2k.exe', a-t-il déjà été généré par l'admin.
if [ -e $WPKGDIR/tools/schtasks2k.exe ]; then
   echo "Le fichier patché schtasks2k.exe qui a été généré par l'admin est disponible."
fi

# Mise en place des droits sur $WPKGDIR
setfacl -b -R $WPKGDIR
# www-se3 a tous les droits sur /var/se3/unattended/install
# C'est peut-être trop. A voir...
chown -R www-se3 /var/se3/unattended/install
setfacl -R -m u:www-se3:rwx -m d:u:www-se3:rwx /var/se3/unattended/install
setfacl -R -m u:$ADMINSE3:rwx -m d:u:$ADMINSE3:rwx /var/se3/unattended/install/wpkg/rapports
setfacl -R -m u::rwx -m g::rx -m o::rx -m d:m:rwx -m d:u::rwx -m d:g::rx -m d:o::rx /var/se3/unattended/install

echo ""
echo "  ##############################################################"
echo "  #   L'admin doit maintenant configurer wpkg en exécutant :   #"
echo "  #   \\\\$SE3\\Progs\\install\\wpkg-config.bat                      #"
echo "  #   à partir d'un Windows XP.                                #"
echo "  ##############################################################"
echo ""
