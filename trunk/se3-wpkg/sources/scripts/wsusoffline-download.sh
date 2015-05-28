#!/bin/bash
#
# Script de telechargement des maj windows par wsusoffline pour Samba Edu
# Sous licence GPL
# Si vous reprenez ou vous inspirez de ce programme, vous devez citer le Projet Samba Edu
#
#### Telechargement automatique des mises a jour wsusoffline en fonction du contenu de /var/se3/unattended/install/wsusoffline/UpdateGenerator.ini #####
# 
#  Auteur : Olivier Lacroix
#
#    mars 2012
#    olivier-yves-cl.lacroix@ac-montpellier.fr
#
## $Id$ ##
#
#  Modifie par : Jean-Remi Couturier - Academie de Clermont-Ferrand
#    avril 2015
#    jean-remi.couturier@ac-clermont.fr
#  Corrections apportees :
#    Modification du test TESTFREESPACE - 10 Go minimum
#       Test effectue sur /var/se3/unattended/install/wsusoffline/client,
#       On peut ainsi copier le dossier /var/se3/unattended/install/wsusoffline/client sur un autre disque si on manque de place,
#       Puis le monter en lieu et place de l'actuel /var/se3/unattended/install/wsusoffline/client.
#    Ajout de l'installation, si absent du serveur, des paquets cabextract, md5deep, xmlstarlet et dos2unix alias tofrodos, necessaires au fonctionnement de DownloadUpdates.sh
#    Forcer wget a telecharger le fichier temoin "WsusOffline-Versions.txt" sans passer par le proxy (pour ne pas recuperer la copie mise en cache)
#    Si le fichier tag "WsusOffline-Versions.txt" a change sur le svn, telechargement et/ou installation de la derniere version des fichiers :
#       - wsusoffline.zip
#       - UpdateGenerator.ini
#       - default.txt
#       - install.cmd
#       - offlineupdate.cmd
#       - cmd64.exe
#       - wpkgMessage.exe
#       - wpkgMessage.ini
#       - wpkg-message.zip
#       - WsusOffline modifier les Maj Microsoft deployees.lnk
#       - Installation de la derniere version stable du xml (sans ajout ou modification des associations avec des parcs)
#    Si l'installation echoue, envoi d'un mail a l'admin, et sans intervention, une nouvelle tentative d'installation a lieu des le lendemain a 20h45.
#    Mise a jour des droits sur les dossiers WPKG pour contourner un probleme d'acl non correctes apres le telechargement du xml de wsusoffline
#    


# Mode debug "1" ou "0"
DEBUG="1"

### on suppose que l'on est sous debian  ####
WWWPATH="/var/www"
### version debian  ####
script_charset="UTF8"

# Recuperation des variables necessaires au script
. /usr/share/se3/includes/config.inc.sh -ml
RNE=`/usr/share/se3/includes/config.inc.sh -mlv | grep ldap_base_dn | cut -d\= -f2 | cut -d\, -f1`

# parametre proxy a trouver dans se3db : pas trouve a part avec le .pac
ipproxy=$(grep "http_proxy=" /etc/profile | head -n 1 | sed -e "s#.*//##;s/\"//")
# ipproxy=$(/usr/share/se3/includes/config.inc.sh -cv | grep "proxy_url" | cut -d"/" -f3 | grep -v "proxy_url")

PARAMS=/var/se3/unattended/install/wsusoffline/UpdateGenerator.ini

CORRESPONDANCE()
{
OSLONG=$1
PARAM=$2
#echo "CORRESPONDANCE execute avec $SECTION $PARAM"
[ "$OSLONG" == "Windows XP" ] && echo "wxp"
[ "$OSLONG" == "Windows XP x64" ] && echo "wxp-x64"
[ "$OSLONG" == "Windows Server 2003" ] && echo "w2k3"
[ "$OSLONG" == "Windows Server 2003 x64" ] && echo "w2k3-x64"
[ "$OSLONG" == "Windows Vista" ] && echo "w60"
[ "$OSLONG" == "Windows Vista x64" ] && echo "w60-x64"
[ "$OSLONG" == "Windows 7" ] && echo "w61"
[ "$OSLONG" == "Windows 7 x64" ] && echo "w61-x64"
# A FAIRE : il faut trouver l'argument pour Windows 2008 server.
#[ "$OSLONG" == "Windows Server 2008 R2" ] && echo "w"
#echo "OtherSection"
}

MAIL=/tmp/wsusofflinemail
[ -e $MAIL ] && rm -f $MAIL

SENDMAIL()
{
	[ ! -e $MAIL ] && echo "Pas de mail a envoyer" && exit 0
	OBJET=$1
	echo "ENVOI DU MAIL SUIVANT A ADMIN :"
	cat $MAIL
	echo "OBJET :"
	echo "$OBJET"
	mail root -s"$RNE - $se3ip - $se3_domain - $OBJET" < $MAIL
	#rm -f $MAIL
}

if [ $# -ne 0 ]; then
	echo "Script a executer sans argument."
	exit 0
fi

# mise a jour du cache APT
/usr/bin/apt-get update

####### Si necessaire, installation du paquet cabextract necessaire au fonctionnement de wsusoffline
echo "Verification de la presence du paquet cabextract :"
PKG_CABEXTRACT=$(dpkg-query -W --showformat='${Status}\n' cabextract|grep "install ok installed")
if [ "" == "$PKG_CABEXTRACT" ]; then
	echo "Le paquet est absent. Installation du paquet...."
	apt-get --force-yes --yes install cabextract >$MAIL 2>&1
	if [ $? != 0 ]; then
		echo "ERREUR : apt-get --force-yes --yes install cabextract" >>$MAIL
		echo "" >>$MAIL
		echo "Une nouvelle tentative d'installation sera executee automatiquement, des demain a partir de 20h45" >>$MAIL
		echo "" >>$MAIL
		echo "Pour tenter de corriger ce probleme, vous pouvez mettre a jour votre serveur, en console ssh, avec les commandes suivantes :" >>$MAIL
		echo "apt-get update" >>$MAIL
		echo "puis" >>$MAIL
		echo "apt-get upgrade" >>$MAIL
		echo "" >>$MAIL
		echo "IMPORTANT : Si vous etes invite a configurer automatiquement le fichier smb.conf, veuillez repondre NON." >>$MAIL
		echo "Puis, lorsque cela vous est propose, choisissez de garder votre version actuelle." >>$MAIL
		echo "" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : Installation du paquet cabextract"
		exit 1
	else
		echo "OK : Le paquet a ete installe."
	fi
else
	echo "OK : Le paquet est present."
fi

####### Si necessaire, installation du paquet md5deep necessaire au fonctionnement de wsusoffline
echo "Verification de la presence du paquet md5deep :"
PKG_MD5DEEP=$(dpkg-query -W --showformat='${Status}\n' md5deep|grep "install ok installed")
if [ "" == "$PKG_MD5DEEP" ]; then
	echo "Le paquet est absent. Installation du paquet...."
	apt-get --force-yes --yes install md5deep >$MAIL 2>&1
	if [ $? != 0 ]; then
		echo "ERREUR : apt-get --force-yes --yes install md5deep" >>$MAIL
		echo "" >>$MAIL
		echo "Une nouvelle tentative d'installation sera executee automatiquement, des demain a partir de 20h45" >>$MAIL
		echo "" >>$MAIL
		echo "Pour tenter de corriger ce probleme, vous pouvez mettre a jour votre serveur, en console ssh, avec les commandes suivantes :" >>$MAIL
		echo "apt-get update" >>$MAIL
		echo "puis" >>$MAIL
		echo "apt-get upgrade" >>$MAIL
		echo "" >>$MAIL
		echo "IMPORTANT : Si vous etes invite a configurer automatiquement le fichier smb.conf, veuillez repondre NON." >>$MAIL
		echo "Puis, lorsque cela vous est propose, choisissez de garder votre version actuelle." >>$MAIL
		echo "" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : Installation du paquet md5deep"
		exit 1
	else
		echo "OK : Le paquet a ete installe."
	fi
else
	echo "OK : Le paquet est present."
fi

####### Si necessaire, installation du paquet xmlstarlet (pour la validation et la modification des documents XML) necessaire au fonctionnement de wsusoffline
echo "Verification de la presence du paquet xmlstarlet :"
PKG_XMLSTARLET=$(dpkg-query -W --showformat='${Status}\n' xmlstarlet|grep "install ok installed")
if [ "" == "$PKG_XMLSTARLET" ]; then
	echo "Le paquet est absent. Installation du paquet...."
	apt-get --force-yes --yes install xmlstarlet >$MAIL 2>&1
	if [ $? != 0 ]; then
		echo "ERREUR : apt-get --force-yes --yes install xmlstarlet" >>$MAIL
		echo "" >>$MAIL
		echo "Une nouvelle tentative d'installation sera executee automatiquement, des demain a partir de 20h45" >>$MAIL
		echo "" >>$MAIL
		echo "Pour tenter de corriger ce probleme, vous pouvez mettre a jour votre serveur, en console ssh, avec les commandes suivantes :" >>$MAIL
		echo "apt-get update" >>$MAIL
		echo "puis" >>$MAIL
		echo "apt-get upgrade" >>$MAIL
		echo "" >>$MAIL
		echo "IMPORTANT : Si vous etes invite a configurer automatiquement le fichier smb.conf, veuillez repondre NON." >>$MAIL
		echo "Puis, lorsque cela vous est propose, choisissez de garder votre version actuelle." >>$MAIL
		echo "" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : Installation du paquet xmlstarlet"
		exit 1
	else
		echo "OK : Le paquet a ete installe."
	fi
else
	echo "OK : Le paquet est present."
fi

####### Si necessaire, installation du paquet dos2unix alias tofrodos necessaire au fonctionnement de wsusoffline
echo "Verification de la presence du paquet dos2unix alias tofrodos :"
PKG_TOFRODOS=$(dpkg-query -W --showformat='${Status}\n' tofrodos|grep "install ok installed")
if [ "" == "$PKG_TOFRODOS" ]; then
	echo "Le paquet est absent. Installation du paquet...."
	apt-get --force-yes --yes install tofrodos >$MAIL 2>&1
	if [ $? != 0 ]; then
		echo "ERREUR : apt-get --force-yes --yes install tofrodos" >>$MAIL
		echo "" >>$MAIL
		echo "Une nouvelle tentative d'installation sera executee automatiquement, des demain a partir de 20h45" >>$MAIL
		echo "" >>$MAIL
		echo "Pour tenter de corriger ce probleme, vous pouvez mettre a jour votre serveur, en console ssh, avec les commandes suivantes :" >>$MAIL
		echo "apt-get update" >>$MAIL
		echo "puis" >>$MAIL
		echo "apt-get upgrade" >>$MAIL
		echo "" >>$MAIL
		echo "IMPORTANT : Si vous etes invite a configurer automatiquement le fichier smb.conf, veuillez repondre NON." >>$MAIL
		echo "Puis, lorsque cela vous est propose, choisissez de garder votre version actuelle." >>$MAIL
		echo "" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : Installation du paquet tofrodos"
		exit 1
	else
		echo "OK : Le paquet a ete installe."
	fi
else
	echo "OK : Le paquet est present."
fi

TESTFREESPACE()
#{
#	# PART=`df | grep "/var/se3\$" | sed -e "s/ .*//"`
#	# PART_SIZE=$(df -m $PARTROOT | awk  '/se3/ {print $4}')
#	if [ "$PART_SIZE" -le 1000 ]; then
#		echo "La partition /var/se3 a moins de 1 Go disponible, c'est insuffisant pour telecharger de nouvelles mises a jour.">$MAIL
#		echo "Merci de liberer de l'espace sur cette partition. Des que cela sera effectue, les mises a jour reprendront automatiquement, tous les soirs.">>$MAIL
#		SENDMAIL "ERREUR WSUSOFFLINE : Place insuffisante sur la partition /var/se3."
#		exit 1
#	fi
#}
{
	FREE_VARSE3=`df -m /var/se3/unattended/install/wsusoffline/client | awk '/[0-9]%/{print $(NF-2)}'`
	if [ "$FREE_VARSE3" -le 10000 ]; then
		echo "Le dossier /var/se3/unattended/install/wsusoffline/client a moins de 10 Go disponible sur sa partition" >$MAIL
		echo "C'est insuffisant pour telecharger de nouvelles mises a jour." >>$MAIL
		echo "Veuillez liberer de l'espace sur cette partition." >>$MAIL
		echo "Des que cela sera effectue, les mises a jour reprendront automatiquement, tous les soirs a partir de 20h45." >>$MAIL
		SENDMAIL "WsusOffline ERREUR : Espace disque insuffisant dans le dossier /var/se3/unattended/install/wsusoffline/client."
		exit 1
	fi
}

TESTFREESPACE

########### Suppression de l'ancien fichier temoin "version.txt" ###########
[ -e /var/se3/unattended/install/wsusoffline/version.txt ] && rm -f /var/se3/unattended/install/wsusoffline/version.txt
 
########### telechargement de la derniere version des fichiers si le fichier tag "WsusOffline-Versions.txt" a change sur le svn. ##########
[ -e /var/se3/unattended/install/wsusoffline.zip ] && rm -f /var/se3/unattended/install/wsusoffline.zip

WSUSOFFLINEROOT=http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages/files/wsusoffline
TEMOIN=/var/se3/unattended/install/wsusoffline/WsusOffline-Versions.txt
NEWTEMOIN=/tmp/wsusofflineversions.txt
wget -O $NEWTEMOIN $WSUSOFFLINEROOT/WsusOffline-Versions.txt? >/dev/null 2>&1
SIZEFILE=`ls -la $NEWTEMOIN | awk '{print $5}'` >/dev/null 2>&1
if [ "$SIZEFILE" == "0" -o "$SIZEFILE" == "" ]; then
	echo "Le telechargement du fichier temoin $TEMOIN a echoue." >$MAIL
	echo "Le proxy est peut etre mal parametre sur le serveur" >>$MAIL
	echo "Taille du fichier $NEWTEMOIN: $SIZEFILE" >>$MAIL
	rm -fv "$NEWTEMOIN" >>$MAIL
	echo "" >>$MAIL
	echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
	SENDMAIL "WsusOffline ERREUR : Impossible de verifier si une mise a jour est disponible."
	exit 1
fi
[ -e $NEWTEMOIN ] && TESTNEWTEMOIN=$(md5sum $NEWTEMOIN | cut -d" " -f1)
[ -e $TEMOIN ] && TESTTEMOIN=$(md5sum $TEMOIN | cut -d" " -f1)

# echo "temoin $TESTTEMOIN et newtemoin :$TESTNEWTEMOIN"
if [ "$TESTTEMOIN" == "$TESTNEWTEMOIN" ]; then
	echo "La version de wsusoffline presente est identique a celle du svn."
else
	echo "Une nouvelle version de wsusoffline est disponible sur le svn.... Veuillez patienter."
	echo "Sauf 'ERREUR' signalee dans l'objet, ce mail est envoye a titre d'information, et dans ce cas, aucune action de votre part n'est necessaire." >$MAIL
	echo "" >>$MAIL
	echo "Une nouvelle version de wsusoffline est disponible sur le svn." >>$MAIL
	echo "" >>$MAIL
	echo "Debut de la mise a jour :" >>$MAIL
	echo "" >>$MAIL
	wget $WSUSOFFLINEROOT/wsusoffline.zip? -O /var/se3/unattended/install/wsusoffline.zip >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/wsusoffline.zip ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/wsusoffline.zip | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement de wsusoffline.zip" >>$MAIL
		echo "" >>$MAIL
		echo "Tentative de decompression vers /var/se3/unattended/install/wsusoffline" >>$MAIL
		if ( ! unzip -o /var/se3/unattended/install/wsusoffline.zip -d /var/se3/unattended/install/ 2>>$MAIL 1>/dev/null ) ; then
			echo "" >>$MAIL
			echo "ERREUR : unzip -o /var/se3/unattended/install/wsusoffline.zip" >>$MAIL
			echo "" >>$MAIL
			echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
			SENDMAIL "WsusOffline ERREUR : une nouvelle version de wsusoffline est disponible mais la decompression du fichier wsusoffline.zip a echoue."
			exit 1
		else
			echo "" >>$MAIL
			echo "OK : Decompression de wsusoffline.zip." >>$MAIL
			rm -f /var/se3/unattended/install/wsusoffline.zip
			echo "Reglage des droits sur les fichiers /var/se3/unattended/install/wsusoffline" >>$MAIL
			chown -R www-se3:admins /var/se3/unattended/install/wsusoffline >>$MAIL
			chmod -R ug+rwx /var/se3/unattended/install/wsusoffline >>$MAIL
			# SENDMAIL "WsusOffline : une nouvelle version a ete telechargee automatiquement afin de proteger au mieux vos pc sous windows."
		fi
	else
		echo "" >>$MAIL
		echo "ERREUR : Fichier $WSUSOFFLINEROOT/wsusoffline.zip absent ou vide" >>$MAIL
		echo "" >>$MAIL
		echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : une nouvelle version de wsusoffline est disponible mais le telechargement a echoue."
		exit 1
	fi
	echo "" >>$MAIL
	echo "Telechargement du fichier de configuration UpdateGenerator.ini :" >>$MAIL
	wget $WSUSOFFLINEROOT/UpdateGenerator.ini? -O /var/se3/unattended/install/wsusoffline/UpdateGenerator.ini >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/wsusoffline/UpdateGenerator.ini ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/wsusoffline/UpdateGenerator.ini | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement de UpdateGenerator.ini" >>$MAIL
		rm -f /var/se3/unattended/install/UpdateGenerator.ini
		# SENDMAIL "WsusOffline : Une nouvelle version du fichier de configuration UpdateGenerator.ini a ete telechargee." 
	else
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du fichier UpdateGenerator.ini" >>$MAIL
		echo "" >>$MAIL
		echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : La nouvelle version du fichier de configuration UpdateGenerator.ini n'a pas pu etre telechargee." 
		exit 1
	fi
	echo ""
	if [ ! -d /var/se3/unattended/install/packages/wsusoffline ] ; then
		echo "" >>$MAIL
		echo "Creation du dossier /var/se3/unattended/install/packages/wsusoffline :" >>$MAIL
		mkdir /var/se3/unattended/install/packages/wsusoffline >>$MAIL 2>&1
		if [ ! -d /var/se3/unattended/install/packages/wsusoffline ] ; then
			echo "" >>$MAIL
			echo "ERREUR : Le dossier n'a pas pu etre cree." >>$MAIL
			echo "" >>$MAIL
			echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
			SENDMAIL "WsusOffline ERREUR : Le dossier /var/se3/unattended/install/packages/wsusoffline n'a pas pu etre cree." 
			exit 1
		else
			echo "" >>$MAIL
			echo "OK : Le dossier a ete cree." >>$MAIL
		fi
	fi
	echo "" >>$MAIL
	echo "Telechargement du fichier de configuration default.txt :">>$MAIL
	wget $WSUSOFFLINEROOT/default.txt? -O /var/se3/unattended/install/packages/wsusoffline/default.txt >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/packages/wsusoffline/default.txt ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/packages/wsusoffline/default.txt | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement de default.txt" >>$MAIL
		rm -f /var/se3/unattended/install/default.txt
		# SENDMAIL "WsusOffline : Une nouvelle version du fichier de configuration default.txt a ete telechargee."
	else
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du fichier default.txt" >>$MAIL
		echo "" >>$MAIL
		echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : La nouvelle version du fichier de configuration default.txt n'a pas pu etre telechargee." 
		exit 1
	fi
	echo "" >>$MAIL
	echo "Telechargement du programme de configuration des ordinateurs install.cmd :" >>$MAIL
	wget $WSUSOFFLINEROOT/install.cmd? -O /var/se3/unattended/install/packages/wsusoffline/install.cmd >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/packages/wsusoffline/install.cmd ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/packages/wsusoffline/install.cmd | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement de install.cmd" >>$MAIL
		rm -f /var/se3/unattended/install/install.cmd
		# SENDMAIL "WsusOffline : Une nouvelle version du fichier de configuration des ordinateurs install.cmd a ete telechargee."
	else
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du fichier install.cmd" >>$MAIL
		echo "" >>$MAIL
		echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : La nouvelle version du programme de configuration des ordinateurs install.cmd n'a pas pu etre telechargee." 
		exit 1
	fi
	echo "" >>$MAIL
	echo "Telechargement du programme de configuration des mises a jour offlineupdate.cmd :" >>$MAIL
	wget $WSUSOFFLINEROOT/offlineupdate.cmd? -O /var/se3/unattended/install/packages/wsusoffline/offlineupdate.cmd >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/packages/wsusoffline/offlineupdate.cmd ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/packages/wsusoffline/offlineupdate.cmd | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement de offlineupdate.cmd" >>$MAIL
		rm -f /var/se3/unattended/install/offlineupdate.cmd
		# SENDMAIL "WsusOffline : Une nouvelle version du fichier de configuration des mises a jour offlineupdate.cmd a ete telechargee."
	else
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du fichier offlineupdate.cmd" >>$MAIL
		echo "" >>$MAIL
		echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : La nouvelle version du programme de configuration des mises a jour offlineupdate.cmd n'a pas pu etre telechargee." 
		exit 1
	fi
	echo "" >>$MAIL
	echo "Telechargement de la console de commande cmd64.exe pour les ordinateurs en 64 bits :" >>$MAIL
	wget $WSUSOFFLINEROOT/cmd64.exe? -O /var/se3/unattended/install/packages/wsusoffline/cmd64.exe >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/packages/wsusoffline/cmd64.exe ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/packages/wsusoffline/cmd64.exe | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement de cmd64.exe" >>$MAIL
		# SENDMAIL "WsusOffline : La console de commande cmd64.exe a ete telechargee."
	else
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du fichier cmd64.exe" >>$MAIL
		echo "" >>$MAIL
		echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : La console de commande cmd64.exe n'a pas pu etre telechargee." 
		exit 1
	fi
	echo "" >>$MAIL
	echo "Telechargement de la barre de progression wpkgMessage.exe :" >>$MAIL
	wget $WSUSOFFLINEROOT/wpkgMessage.exe? -O /var/se3/unattended/install/packages/wsusoffline/wpkgMessage.exe >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/packages/wsusoffline/wpkgMessage.exe ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/packages/wsusoffline/wpkgMessage.exe | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement de wpkgMessage.exe" >>$MAIL
		# SENDMAIL "WsusOffline : La barre de progression wpkgMessage.exe a ete telechargee."
	else
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du fichier wpkgMessage.exe" >>$MAIL
		echo "" >>$MAIL
		echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : La barre de progression wpkgMessage.exe n'a pas pu etre telechargee." 
		exit 1
	fi
	echo "" >>$MAIL
	echo "Telechargement du fichier de configuration de la barre de progression wpkgMessage.ini :" >>$MAIL
	wget $WSUSOFFLINEROOT/wpkgMessage.ini? -O /var/se3/unattended/install/packages/wsusoffline/wpkgMessage.ini >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/packages/wsusoffline/wpkgMessage.ini ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/packages/wsusoffline/wpkgMessage.ini | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement de wpkgMessage.ini" >>$MAIL
		# SENDMAIL "WsusOffline : Le fichier de configuration de la barre de progression wpkgMessage.ini a ete telechargee."
	else
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du fichier wpkgMessage.ini" >>$MAIL
		echo "" >>$MAIL
		echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : Le fichier de configuration de la barre de progression wpkgMessage.ini n'a pas pu etre telechargee." 
		exit 1
	fi
	echo "" >>$MAIL
	echo "Telechargement des sources du programme wpkgMessage :" >>$MAIL
	# http://www.gig-mbh.de/edv/index.htm?/edv/software/wpkgtools/wpkg-message-english.htm
	wget $WSUSOFFLINEROOT/wpkg-message.zip? -O /var/se3/unattended/install/packages/wsusoffline/wpkg-message.zip >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/packages/wsusoffline/wpkg-message.zip ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/packages/wsusoffline/wpkg-message.zip | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement de wpkg-message.zip" >>$MAIL
		# SENDMAIL "WsusOffline : Les sources du programme wpkg-message ont ete telecharges."
	else
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du fichier wpkg-message.zip" >>$MAIL
		# SENDMAIL "WsusOffline ERREUR : Les sources du programme wpkg-message n'ont pas pu etre telecharges." 
		# exit 1
	fi
	echo ""
	if [ ! -d /home/templates/admins/Bureau ] ; then
		echo "" >>$MAIL
		echo "Creation du dossier /home/templates/admins/Bureau :" >>$MAIL
		mkdir -p /home/templates/admins/Bureau >>$MAIL 2>&1
		if [ ! -d /home/templates/admins/Bureau ] ; then
			echo "" >>$MAIL
			echo "ERREUR : Le dossier n'a pas pu etre cree." >>$MAIL
			echo "" >>$MAIL
			echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
			SENDMAIL "WsusOffline ERREUR : Le dossier /home/templates/admins/Bureau n'a pas pu etre cree."
			exit 1
		else
			echo "" >>$MAIL
			echo "OK : Le dossier a ete cree." >>$MAIL
			chown -R admin:admins "/home/templates/admins" >>$MAIL
			chmod -R 770 "/home/templates/admins" >>$MAIL
		fi
	fi
	echo "" >>$MAIL
	echo "Telechargement du raccourci permettant de configurer les maj deployees :" >>$MAIL
	wget $WSUSOFFLINEROOT/raccourciadmin.lnk? -O "/home/templates/admins/Bureau/WsusOffline modifier les Maj Microsoft deployees.lnk" >>$MAIL 2>&1
	if [ -e "/home/templates/admins/Bureau/WsusOffline modifier les Maj Microsoft deployees.lnk" ]; then
		SIZEFILE=`ls -la "/home/templates/admins/Bureau/WsusOffline modifier les Maj Microsoft deployees.lnk" | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	# echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "" >>$MAIL
		echo "OK : Telechargement du raccourci sur le bureau des admins permettant de modifier les maj deployees" >>$MAIL
		# SENDMAIL "WsusOffline : Les sources du programme wpkg-message ont ete telecharges."
		chown admin:admins "/home/templates/admins/Bureau/WsusOffline modifier les Maj Microsoft deployees.lnk" >>$MAIL
		chmod 770 "/home/templates/admins/Bureau/WsusOffline modifier les Maj Microsoft deployees.lnk" >>$MAIL
	else
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du raccourci sur le bureau des admins permettant de modifier les maj deployees" >>$MAIL
		echo "" >>$MAIL
		echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : Le raccourci sur le bureau des admins permettant de modifier les maj deployees n'a pas pu etre telecharges." 
		exit 1
	fi
	if [ -e "/home/templates/admins/Bureau/Telecharger les mises a jour Microsoft.lnk" ]; then
		echo "" >>$MAIL
		echo "Suppression de l'ancien raccourci de telechargement des maj Microsoft :" >>$MAIL
		rm -fv "/home/templates/admins/Bureau/Telecharger les mises a jour Microsoft.lnk" >>$MAIL
		if [ -e "/home/templates/admins/Bureau/Telecharger les mises a jour Microsoft.lnk" ]; then
			echo "" >>$MAIL
			echo "ERREUR : impossible de supprimer l'ancien raccourci de telechargement des maj Microsoft." >>$MAIL
		else
			echo "" >>$MAIL
			echo "OK : l'ancien raccourci de telechargement des maj Microsoft a ete supprime." >>$MAIL
		fi
	fi
	echo "" >>$MAIL
	echo "Telechargement du xml de wsusoffline :" >>$MAIL
	wget $WSUSOFFLINEROOT/wsusoffline.xml? -O /var/se3/unattended/install/wpkg/tmp/wsusoffline.xml >>$MAIL 2>&1
	if [ $? != 0 ]; then
		echo "" >>$MAIL
		echo "ERREUR : Telechargement du xml de wsusoffline" >>$MAIL
		echo "  Une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : Le telechargement du xml de wsusoffline a echoue."
		exit 1
	else
		echo "" >>$MAIL
		echo "OK : Telechargement du xml de wsusoffline." >>$MAIL
	fi
	echo "" >>$MAIL
	echo "Correction des droits sur /var/se3/unattended/install/wpkg/tmp/wsusoffline.xml" >>$MAIL
	chown www-se3:admins /var/se3/unattended/install/wpkg/tmp/wsusoffline.xml >>$MAIL 2>&1
	chmod 775 /var/se3/unattended/install/wpkg/tmp/wsusoffline.xml >>$MAIL 2>&1
	echo "" >>$MAIL
	echo "Installation du xml de wsusoffline dans WPKG sans association avec des parcs :" >>$MAIL
	/var/www/se3/wpkg/bin/installPackage.sh /var/se3/unattended/install/wpkg/tmp/wsusoffline.xml 0 admin 0 1 >>$MAIL 2>&1
	if [ $? != 0 ]; then
		echo "" >>$MAIL
		echo "ERREUR : Installation du xml de wsusoffline" >>$MAIL
		echo "  Une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
		SENDMAIL "WsusOffline ERREUR : L'installation du xml de wsusoffline dans WPKG sans association avec des parcs a echoue."
		exit 1
	else
		echo "" >>$MAIL
		echo "OK : Installation du xml de wsusoffline." >>$MAIL
		echo ""
		echo "Si cela n'est pas deja fait, depuis l'interface de WPKG, veuillez selectionner les parcs sur lesquels vous souhaitez deployer les mises a jour Microsoft."
	fi
	if [ ! -d /var/se3/unattended/install/wpkg/rapports/wsusoffline ] ; then
		echo "" >>$MAIL
		echo "Creation du dossier des rapports de wsusoffline dans /var/se3/unattended/install/wpkg/rapports/wsusoffline :" >>$MAIL
		mkdir /var/se3/unattended/install/wpkg/rapports/wsusoffline >>$MAIL 2>&1
		if [ ! -d /var/se3/unattended/install/wpkg/rapports/wsusoffline ] ; then
			echo "" >>$MAIL
			echo "ERREUR : Le dossier n'a pas pu etre cree." >>$MAIL
			echo "" >>$MAIL
			echo "Sans intervention de votre part, une nouvelle tentative sera executee des demain a partir de 20h45" >>$MAIL
			SENDMAIL "WsusOffline ERREUR : Le dossier /var/se3/unattended/install/wpkg/rapports/wsusoffline n'a pas pu etre cree."
			exit 1
		else
			echo "" >>$MAIL
			echo "OK : Le dossier a ete cree." >>$MAIL
		fi
	fi
	# tout a reussi, on remplace le fichier temoin
	[ -e $TEMOIN ] && rm -f $TEMOIN
	mv $NEWTEMOIN $TEMOIN
	VersionWsusOffline=`cat /var/se3/unattended/install/wsusoffline/client/cmd/DoUpdate.cmd | grep WSUSOFFLINE_VERSION= | cut -d \= -f2`
	SENDMAIL "WsusOffline : Mise a jour $VersionWsusOffline telechargee automatiquement."
fi

####### Mise a jour des droits sur les dossiers WPKG pour contourner un probleme d'acl non correctes apres le telechargement du xml de wsusoffline
####### (repris depuis /var/cache/se3_install/wpkg-install.sh)
# www-se3 a tous les droits sur /var/se3/unattended/install
# C'est peut-etre trop. A voir...
echo Mise a jour des droits sur les dossiers WPKG :
ADMINSE3="adminse3"
chown -R www-se3:admins /var/se3/unattended/install
setfacl -R -m u:www-se3:rwx -m d:u:www-se3:rwx /var/se3/unattended/install
setfacl -R -m u:$ADMINSE3:rwx -m d:u:$ADMINSE3:rwx /var/se3/unattended/install/wpkg/rapports
setfacl -R -m u::rwx -m g::rx -m o::rx -m d:m:rwx -m d:u::rwx -m d:g::rx -m d:o::rx /var/se3/unattended/install
echo OK


####### Utilisation du fichier UpdateGenerator.ini et de DownloadUpdates.sh pour recuperer les mises a jour #########
[ ! -e $PARAMS ] && "echo Fichier $PARAMS absent." && exit 0
echo "Analyse du fichier $PARAMS."

echo "Debut du telechargement des mises a jour microsoft : $date." >$MAIL

cat $PARAMS | while read line
do
	if [ "`echo $line | grep -E "^\[" | grep -E "\]"`" == "" ]; then
		#[ "$DEBUG" == "1" ] && echo "Ce n'est pas le debut d'une section : $line"
		PARAMETRE=`echo "$line" | cut -f1 -d "="`
		VALEUR=`echo "$line" | cut -f2 -d "="`
		if [ ! "`echo "$VALEUR" | grep "Enabled"`" == "" ]; then
			echo "OS=CORRESPONDANCE $SECTION $PARAMETRE"
			OS=`CORRESPONDANCE "$SECTION" "$PARAMETRE"`
			[ "$OS" == "" ] && OS="OtherSection"
			echo "nom court de l'OS : $OS"
			# si l'os est office ou options ou autre micellianous : alors gerer le cas en evitant de passer des mauvais arguments.
			if [ "$PARAMETRE" == "glb" ]; then
				# glb : global ou fra a passer en parametre ?...
				LANG="fra"
			else
				LANG=$PARAMETRE
			fi
			if [ "$ipproxy" == "" ]; then
				PROXY=""
			else
				PROXY="/proxy http://$ipproxy"
			fi
			if [ ! "$OS" == "OtherSection" ]; then
				echo "Section ignoree : $SECTION."
			#else
				echo "Dans la section $SECTION, un parametre est active : $PARAMETRE = $VALEUR"
				echo "Telechargement des mises a jour pour l'OS $OS et la langue $LANG..."
				echo "/var/se3/unattended/install/wsusoffline/sh/DownloadUpdates.sh $OS $LANG /msse $PROXY" >>$MAIL
				TESTFREESPACE
				/var/se3/unattended/install/wsusoffline/sh/DownloadUpdates.sh $OS $LANG /msse $PROXY >>$MAIL 2>&1
			fi
		fi
	else
		#[ "$DEBUG" == "1" ] && echo "C'est le debut d'une section : $line"
		SECTION=`echo "$line" | cut -f2 -d "[" | cut -f1 -d "]"`
		#[ "$DEBUG" == "1" ] && echo "Section : $SECTION"
	fi
done

# Envoi d'un mail a l'admin en cas de nouvelles mises a jour trouvees.
TEST=`cat $MAIL | grep "successfully downloaded"`
if [ ! "$TEST" == "" ]; then
	VersionWsusOffline=`cat /var/se3/unattended/install/wsusoffline/client/cmd/DoUpdate.cmd | grep WSUSOFFLINE_VERSION= | cut -d \= -f2`
	TailleDossierMaj=`du -sh /var/se3/unattended/install/wsusoffline | cut -d/ -f1`
	SENDMAIL "WsusOffline $VersionWsusOffline : Maj telechargees. Taille du dossier des Maj : $TailleDossierMaj."
else
	echo "Pas de nouvelles mises a jour telechargees. Pas d'envoi de mail a l'admin."
	[ -e $MAIL ] && rm -f $MAIL
fi



