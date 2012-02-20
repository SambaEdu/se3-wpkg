#!/bin/bash

#########################################################################
#   /usr/share/se3/scripts/wpkg_initvars.sh                             #
#                                                                       #
#########################################################################
#
#
#   Cree un fichier bat /var/se3/unattended/install/wpkg/initvars_se3.bat
#   d'initialisation des param�tres du serveur ( Set variable=valeur ...)
#   Utilisable pour l'install des applis

#   A executer chaque fois que le parametrage du serveur se3 est change

## $Id$ ##
#

# Chemin du fichier .bat a creer
INITVARSSE3BAT='/var/se3/unattended/install/wpkg/initvars_se3.bat'

# List des variables a definir
ListVars="'urlse3','lang','ldap_server','ldap_port','ldap_base_dn','adminRdn','peopleRdn','groupsRdn','rightsRdn','parcsRdn','computersRdn','path_to_wwwse3','lcsIp','domain','path2UserSkel','path2BatFiles','path2Templates','path2smbconf','path2slapdconf','path2ldapconf','path2pamldapconf','path2nssldapconf','path2ldapsecret','serv_samba','serv_apache','serv_slapd','serv_nscd','defaultgid','majnbr','autologon','uidPolicy','yala_bind','defaultshell','melsavadmin','savlevel','savbandnbr','savdevice','savhome','savse3','savsuspend','debug','urlmaj','ftpmaj','defaultintlevel','majzinbr','ntpserv','printersRdn','trashRdn','slisip','slis_url','infobul_activ','bpcmedia','backuppc','inventaire','antivirus','affiche_etat','registred','smbversion','domainsid','majdepnbr','dhcp_on_boot','dhcp_iface','dhcp_begin_range','dhcp_end_range','dhcp_dns_server_prim','dhcp_dns_server_sec','dhcp_gateway','dhcp_wins','dhcp_ntp','dhcp_max_lease','dhcp_default_lease','dhcp_domain_name','dhcp_tftp_server','dhcp_unatt_login','dhcp_unatt_pass','dhcp_unatt_filename','dhcp','version','wpkg','menu_fond_ecran'"

WWWPATH="/var/www"
## recuperation des variables necessaires pour interoger mysql ###
if [ -e $WWWPATH/se3/includes/config.inc.php ]; then
	dbhost=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbhost=" | cut -d = -f2 | cut -d \" -f2`
	dbname=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbname=" | cut	-d = -f 2 |cut -d \" -f 2`
	dbuser=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbuser=" | cut -d = -f 2 | cut -d \" -f 2`
	dbpass=`cat $WWWPATH/se3/includes/config.inc.php | grep "dbpass=" | cut -d = -f 2 | cut -d \" -f 2`
else
	echo "Fichier de configuration inaccessible, le script ne peut se poursuivre."
	exit 1
fi

# HashSE3 si un client a besoin de verifier qu'il s'agit de ce serveur
HashSE3existe="0"
if ( grep 'Set HashSE3=' $INITVARSSE3BAT >/dev/null 2>&1); then
	HashSE3existe="1"
fi

# Creation du fichier $INITVARSSE3BAT
. /usr/share/se3/includes/config.inc.sh -m

# Nom du serveur SE3
echo "Set SE3=$netbios_name" > $INITVARSSE3BAT

echo "Set IPSE3=$se3ip" >> $INITVARSSE3BAT

echo "Set DOMAINSE3=$se3_domain" >> $INITVARSSE3BAT

if [ "$HashSE3existe" == "0" ]; then
	perl -e '@c=("A".."Z","a".."z",0..9);print "Set HashSE3=",join("",@c[map{rand @c}(1..16)]),"\n"' >> $INITVARSSE3BAT
fi

# params
echo "SELECT CONCAT('Set ', name, '=', value) FROM params WHERE name In ($ListVars)" | mysql -h $dbhost $dbname -u $dbuser -p$dbpass -N >> $INITVARSSE3BAT

todos $INITVARSSE3BAT

