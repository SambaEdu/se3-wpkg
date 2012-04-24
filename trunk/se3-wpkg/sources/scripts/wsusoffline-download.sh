#!/bin/bash
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


# Mode debug "1" ou "0"
DEBUG="1"

### on suppose que l'on est sous debian  ####
WWWPATH="/var/www"
### version debian  ####
script_charset="UTF8"

. /usr/share/se3/includes/config.inc.sh -ml

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
	mail root -s"$OBJET" < $MAIL
	#rm -f $MAIL
}

if [ $# -ne 0 ]; then
	echo "Script a executer sans argument."
	exit 0
fi

TESTFREESPACE()
{
	PART=`df | grep "/var/se3\$" | sed -e "s/ .*//"`
	PART_SIZE=$(df -m $PARTROOT | awk  '/se3/ {print $4}')
	if [ "$PART_SIZE" -le 1000 ]; then
		echo "La partition /var/se3 a moins de 1 Go disponible, c'est insuffisant pour telecharger de nouvelles mises a jour.">$MAIL
		echo "Merci de liberer de l'espace sur cette partition. Des que cela sera effectue, les mises a jour reprendront automatiquement, tous les soirs.">>$MAIL
		SENDMAIL "ERREUR WSUSOFFLINE : Place insuffisante sur la partition /var/se3."
		exit 1
	fi
}

TESTFREESPACE

########### telechargement de la derniere version de wsusoffline si un fichier tag a change sur le svn. ##########
[ -e /var/se3/unattended/install/wsusoffline.zip ] && rm -f /var/se3/unattended/install/wsusoffline.zip

WSUSOFFLINEROOT=http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages/files/wsusoffline
TEMOIN=/var/se3/unattended/install/wsusoffline/version.txt
NEWTEMOIN=/tmp/wsusofflineversion.txt
wget -O $NEWTEMOIN $WSUSOFFLINEROOT/version.txt >/dev/null 2>&1
SIZEFILE=`ls -la $NEWTEMOIN | awk '{print $5}'` >/dev/null 2>&1
if [ "$SIZEFILE" == "0" -o "$SIZEFILE" == "" ]; then
	echo "Le telechargement de $WSUSOFFLINEROOT/version.txt a echoue. Le proxy est peut etre mal parametre sur le serveur">$MAIL
	echo "Taille du fichier $NEWTEMOIN: $SIZEFILE">>$MAIL
	SENDMAIL "ERREUR WSUSOFFLINE : Impossible de verifier si une mise a jour est disponible.."
	exit 1
fi
[ -e $NEWTEMOIN ] && TESTNEWTEMOIN=$(md5sum $NEWTEMOIN | cut -d" " -f1)
[ -e $TEMOIN ] && TESTTEMOIN=$(md5sum $TEMOIN | cut -d" " -f1)

#echo "temoin $TESTTEMOIN et newtemoin :$TESTNEWTEMOIN"
if [ "$TESTTEMOIN" == "$TESTNEWTEMOIN" ]; then
	echo "La version de wsusoffline presente est identique a celle du svn."
else
	echo "Une nouvelle version de wsusoffline est disponible sur le svn. Veuillez patienter."
	echo "Sauf 'ERREUR' signalee dans l'objet, ce mail est envoye a titre d'information et, dans ce cas, aucune action de votre part n'est necessaire...">$MAIL
	echo "">>$MAIL
	echo "Une nouvelle version de wsusoffline est disponible sur le svn.">>$MAIL
	echo "">>$MAIL
	echo "Debut du telechargement.">>$MAIL
	wget $WSUSOFFLINEROOT/wsusoffline.zip -O /var/se3/unattended/install/wsusoffline.zip >>$MAIL 2>&1
	if [ -e /var/se3/unattended/install/wsusoffline.zip ]; then
		SIZEFILE=`ls -la /var/se3/unattended/install/wsusoffline.zip | awk '{print $5}'`
	else
		SIZEFILE="0"
	fi
	#echo "SIZEFILE=$SIZEFILE"
	if [ ! "$SIZEFILE" == "0" ]; then
		echo "Telechargement accompli.">>$MAIL
		echo "Tentative de decompression vers /var/se3/unattended/install.">>$MAIL
		if ( ! unzip -o /var/se3/unattended/install/wsusoffline.zip -d /var/se3/unattended/install/ 2>>$MAIL 1>/dev/null ) ; then
			echo "Erreur unzip -o /var/se3/unattended/install/wsusoffline.zip" >>$MAIL
			SENDMAIL "ERREUR : une nouvelle version de wsusoffline est disponible mais la decompression du fichier telecharge a echoue."
			exit 1
		else
			echo "Fin de la decompression.">>$MAIL
			rm -f /var/se3/unattended/install/wsusoffline.zip
			echo "Reglage des droits sur les fichiers wsusoffline.">>$MAIL
			chmod -R ug+rwx /var/se3/unattended/install/wsusoffline >>$MAIL
			chown -R admin:admins /var/se3/unattended/install/wsusoffline >>$MAIL
			SENDMAIL "Information : une nouvelle version de wsusoffline a ete telechargee automatiquement afin de proteger au mieux vos pc sous windows."
			# tout a reussi, on remplace le fichier temoin
			[ -e $TEMOIN ] && rm -f $TEMOIN
			mv $NEWTEMOIN $TEMOIN
		fi
	else
		echo "Fichier $WSUSOFFLINEROOT/wsusoffline.zip absent ou vide : le telechargement a echoue.">>$MAIL
		SENDMAIL "ERREUR : une nouvelle version de wsusoffline est disponible mais le telechargement a echoue."
		exit 1
	fi
fi


####### Utilisation du fichier ini renseigné par l'admin et de DownloadUpdates.sh pour recuperer les mises a jour #########
[ ! -e $PARAMS ] && "echo Fichier $PARAMS absent." && exit 0
echo "Analyse du fichier $PARAMS."

echo "Debut du telechargement des mises a jour microsoft : $date.">$MAIL

cat $PARAMS | while read line
do
	if [ "`echo $line | grep -E "^\[" | grep -E "\]"`" == "" ]; then
		#[ "$DEBUG" == "1" ] && echo "Ce n'est pas le debut d'une section : $line"
		PARAMETRE=`echo "$line" | cut -f1 -d "="`
		VALEUR=`echo "$line" | cut -f2 -d "="`
		if [ ! "`echo "$VALEUR" | grep "Enabled"`" == "" ]; then
			#echo "OS=CORRESPONDANCE $SECTION $PARAMETRE"
			OS=`CORRESPONDANCE "$SECTION" "$PARAMETRE"`
			[ "$OS" == "" ] && OS="OtherSection"
			#echo "nom court de l'OS : $OS"
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
				#echo "Section ignoree : $SECTION."
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
	SENDMAIL "[Module se3-wpkg : telechargement des mises a jour microsoft par wsusoffline]"
else
	echo "Pas de nouvelle mise a jour telechargee. Pas d'envoi de mail a l'admin."
	#[ -e $MAIL ] && rm -f $MAIL
fi



