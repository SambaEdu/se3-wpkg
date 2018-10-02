#!/bin/bash

#########################################################################
#   /usr/share/sambaedu/scripts/wpkg_initvars.sh                             #
#                                                                       #
#########################################################################
#  TODO Est-il encore utile ?
#
#   Cree un fichier bat /var/sambaedu/unattended/install/wpkg/initvars_se3.bat
#   d'initialisation des paramètres du serveur ( Set variable=valeur ...)
#   Utilisable pour l'install des applis

#   A executer chaque fois que le parametrage du serveur se3 est change

## $Id$ ##
# last update fev 2016 - utf8

# Chemin du fichier .bat a creer
INITVARSSE3BAT='/var/sambaedu/unattended/install/wpkg/initvars_se4.bat'

# List des variables a definir
ListVars="'urlse3','lang','ldap_server','ldap_port','ldap_base_dn','adminRdn','peopleRdn','groupsRdn','rightsRdn','parcsRdn','computersRdn','path_to_wwwse3','lcsIp','domain','path2UserSkel','path2BatFiles','path2Templates','path2smbconf','path2slapdconf','path2ldapconf','path2pamldapconf','path2nssldapconf','path2ldapsecret','serv_samba','serv_apache','serv_slapd','serv_nscd','defaultgid','majnbr','autologon','uidPolicy','yala_bind','defaultshell','melsavadmin','savlevel','savbandnbr','savdevice','savhome','savse3','savsuspend','debug','urlmaj','ftpmaj','defaultintlevel','majzinbr','ntpserv','printersRdn','trashRdn','slisip','slis_url','infobul_activ','bpcmedia','backuppc','inventaire','antivirus','affiche_etat','registred','smbversion','domainsid','majdepnbr','dhcp_on_boot','dhcp_iface','dhcp_begin_range','dhcp_end_range','dhcp_dns_server_prim','dhcp_dns_server_sec','dhcp_gateway','dhcp_wins','dhcp_ntp','dhcp_max_lease','dhcp_default_lease','dhcp_domain_name','dhcp_tftp_server','dhcp_unatt_login','dhcp_unatt_pass','dhcp_unatt_filename','dhcp','version','wpkg','menu_fond_ecran'"

. /usr/share/sambaedu/includes/config.inc.sh
. /usr/share/sambaedu/includes/utils.inc.sh

echo 'SET "se4fs_name='.$config_se4fs_name.'"' > $INITVARSSE3BAT
echo 'SET "domain='.$config_domain.'"' >> $INITVARSSE3BAT

todos $INITVARSSE3BAT

