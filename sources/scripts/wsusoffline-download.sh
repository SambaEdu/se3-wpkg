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
proxy=$(grep "http_proxy=" /etc/profile | head -n 1 | sed -e "s#.*//##;s/\"//")

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
[ "$OSLONG" == "Windows Server 2008 R2" ] && echo "w"
#echo "OtherSection"
}

if [ $# -ne 0 ]; then
	echo "Script a executer sans argument."
	exit 0
fi


[ ! -e $PARAMS ] && "echo Fichier $PARAMS absent." && exit 0
echo "Analyse du fichier $PARAMS."

MAIL=/tmp/wsusofflinemail
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
			# parametre proxy a trouver dans se3db : nom de variable ci-dessous mis au hasard
			if [ "$proxy" == "" ]; then
				PROXY=""
			else
				PROXY="/proxy http://$proxy"
			fi
			if [ ! "$OS" == "OtherSection" ]; then
				#echo "Section ignoree : $SECTION."
			#else
				echo "Dans la section $SECTION, un parametre est active : $PARAMETRE = $VALEUR"
				echo "Telechargement des mises a jour pour l'OS $OS et la langue $LANG..."
				echo "/var/se3/unattended/install/wsusoffline/sh/DownloadUpdates.sh $OS $LANG /msse $PROXY" >>$MAIL
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
TEST=`cat $MAIL | grep "Telechargement de nouvelles mises a jour"`
if [ ! "$TEST" == "" ]; then
	mail root -s"[Module se3-wpkg : telechargement de nouvelles mises a jour microsoft par wsusoffline]." < $MAIL
fi
#[ -e $MAIL ] && rm -f $MAIL

echo "Fin."
exit 0

URLSE3="$urlse3"
SE3="$netbios_name"
if [ -z "$SE3" ] ; then
   SE3=`gawk -F' *= *' '/netbios name/ {print $2}' /etc/samba/smb.conf`
fi
if [ -z "$SE3" ] ; then
   echo "Nom netbios du serveur samba introuvable."
   exit 1
fi
WPKGDIR="/var/se3/unattended/install/wpkg"
WPKGROOT="\\\\$SE3\\install\\wpkg"

# Compte administrateur local des postes
ADMINSE3="adminse3"
PASSADMINSE3="$xppass"

